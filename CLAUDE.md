# ffmpeg-build — プロジェクトドキュメント

Ubuntu 24.04 上で、外部コーデック / フィルタ / ハードウェアアクセラレーション / プロトコルを
可能な限り盛り込んだ **maximal full-featured FFmpeg 8.1.1 ("Hoare")** をビルドする
Docker リポジトリ。GPL + version3 + nonfree variant。

## アーキテクチャ

- **build image = `docker build` で作られるビルド *環境*。FULL-BUILD（`docs/todo/001-full-build.md`）:
  apt はライブラリを一切 install しない。** apt は OS フロア + ブートストラップ seed
  （`build-essential`/`curl`/`git`/`xz-utils`/`bzip2`/`patch`/`perl`/`gettext`/`texinfo`。自前 gcc を
  コンパイルするためだけの種コンパイラで、成果物には入らない）のみ。ツールチェイン（gcc/binutils +
  gmp/mpfr/mpc/isl）・ビルドツール（pkgconf/cmake/ninja/meson/nasm/yasm/autotools/python など）・
  全メディアライブラリ（約100）を **`scripts/deps/*.sh` で `/usr/local` にソースビルド**する。
  **FFmpeg のソースもバイナリも イメージには含まれない。** `docker build` 中に FFmpeg の
  `./configure` / `make` は実行されない。
- **FFmpeg は `docker run` 時にコンパイルされる。** ENTRYPOINT が `scripts/build-ffmpeg.sh` を
  実行し、このスクリプトが **実行時に FFmpeg ソースをダウンロード** し（イメージにベイクしない）、
  configure / build / install / verify を走らせる。FFmpeg も自前 gcc でビルドされ `$ORIGIN` RPATH
  が焼き込まれる（後述）。
- **レイヤキャッシュ設計:** `Dockerfile` は `COPY scripts/deps/ /opt/scripts/deps/`（`common.sh` を
  含む）を依存ビルド `RUN` 群の **前** に置き、`COPY scripts/build-ffmpeg.sh scripts/build-deps.sh
  /opt/scripts/` を最後の依存 `RUN` の **後**（ENTRYPOINT 直前）に置く。これにより `build-ffmpeg.sh`
  を編集してもコスト高な依存レイヤのキャッシュが無効化されない。約100超の依存は **フェーズ単位の
  `RUN`**（クラスタごと）でレイヤ数を実用範囲に保つ。`common.sh` を編集すると全依存レイヤが
  （正しく）無効化される。

### リポジトリ構成

| ファイル | 役割 |
|------|------|
| `Dockerfile` | 単一ステージのビルドイメージ。apt は OS フロア + 種コンパイラのみ、ライブラリ install なし。全依存をフェーズ単位の `RUN` でソースビルド。FFmpeg のソース / コンパイルは含まない。 |
| `.dockerignore` | ビルドコンテキストを最小化（イメージは FFmpeg を自分で取得する）。 |
| `scripts/build-ffmpeg.sh` | **ENTRYPOINT**。`docker run` 時に FFmpeg をダウンロード → configure → build → install → verify → `/output` へバンドル出力。patchelf を使わず `readelf` で `$ORIGIN` RPATH を検証。 |
| `scripts/build-deps.sh` | **全ソース依存の正準な順序付きドライバ**（依存順の完全リスト）。Dockerfile はこの順序をフェーズ `RUN` にミラーする。ローカル/手動ビルドにも使用。 |
| `scripts/deps/common.sh` | 全 `deps/*.sh` が source する共通契約: `PREFIX`/`JOBS`、`fetch_git`/`fetch_tar`/`verify_pc`/`cleanup` ヘルパ、および patchelf を置き換える `$ORIGIN` RPATH specs (`ORIGIN_SPECS`)。 |
| `scripts/deps/*.sh` | 各ソースビルド依存（ツールチェイン + ビルドツール + 全メディア lib。順序は `build-deps.sh`）。 |

## バージョン変更方法 (FFMPEG_VERSION)

- ビルド時のデフォルトは `Dockerfile` の `ARG FFMPEG_VERSION=8.1.1`（`ENV FFMPEG_VERSION` に伝播）。
- イメージ作成時に上書き: `docker build --build-arg FFMPEG_VERSION=<ver> -t ffmpeg-build .`
- 実行時に上書き: `docker run --rm -e FFMPEG_VERSION=<ver> -v "$PWD/out:/output" ffmpeg-build`
  （`build-ffmpeg.sh` は env の `FFMPEG_VERSION`、未設定時はデフォルト `8.1.1` を使用）。
- `build-ffmpeg.sh` は configure 前に `./configure --help` に対して各 `--enable` フラグの存在を
  検証し、当該 FFmpeg バージョンが認識しないフラグを自動的に drop するセーフティネットを持つ。
  既知の正フラグ集合では何も drop されない。

## アーティファクト出力 (/output) — ホスト実行可能バンドル

`/output` がマウントされたディレクトリの場合、`build-ffmpeg.sh` は **ホストで直接実行できる
自己完結・再配置可能 (self-contained / relocatable) バンドル** を出力する。

出力物（`/output/` 直下）:

- `ffmpeg` / `ffprobe` / `ffplay`（存在するもの）。`./out/ffmpeg -version` のようにホストで直接実行できる。
- `lib/` — バンドルされた共有ライブラリ群（`libavcodec.so.*` 等の FFmpeg libs、全コーデック /
  フィルタ libs、`libstdc++` / `libgcc_s` / `libcrypt` など）。各ライブラリは **soname 名**で
  格納される（`cp -L` で symlink チェーンを解決した実体）。
- `ffmpeg-${FFMPEG_VERSION}-linux-x86_64.tar.gz` — `ffmpeg ffprobe ffplay lib/` を相対パスで含む
  **再配置可能な tarball**。バンドルディレクトリの内側 (`tar -C "$BUNDLE"`) から作るため、任意の
  場所に展開してそのまま実行できる。
- 最後に `ls -la /output` を表示。

### バンドルの仕組み（RPATH を *リンク時* に焼く / patchelf 不使用）

naive な「バイナリだけコピー」では、ffmpeg がイメージ内の共有 lib（`libavdevice.so.62` など、
`/usr/local/lib`）にリンクしているためホストで `libavdevice.so.62: cannot open shared object file`
で失敗する。**旧フローは patchelf でビルド後に RPATH を `$ORIGIN` へ書き換えていた**が、この
「成果物の事後改変」が 001-full-build で排除した *侵害* である。代わりに **RPATH をリンク時に焼き込む**:

1. **自前 gcc の `specs` で `$ORIGIN` RPATH を全リンクに注入。** `scripts/deps/gcc.sh` が
   `common.sh:ORIGIN_SPECS` を gcc 専用ディレクトリの `specs` として設置する。以降、自前 gcc が行う
   **全ての非 static リンク**（実行ファイル・共有ライブラリ双方）に
   `DT_RPATH = $ORIGIN:$ORIGIN/../lib:$ORIGIN/lib` が自動で付く。注入は gcc ドライバ内部で起きるため、
   make/シェルの `$` 展開（`$O`→空 で `RIGIN` 化する罠）を貫通してリテラル `$ORIGIN` が保存される。
   個々の `deps/*.sh` は RPATH フラグを **一切設定しない**（gcc が自動で再配置可能にする）。
2. **OLD dtags (DT_RPATH) を使う**（`--disable-new-dtags`）。実行ファイルの DT_RPATH は
   *推移的*に読み込まれる全 lib へ伝播するため、gcc 自身がビルドした（specs 設置前なので RPATH を
   持たない）`libstdc++.so.6` / `libgcc_s.so.1` も実行ファイルの RPATH で解決できる。DT_RUNPATH では
   伝播しないので不可。
3. **バンドル収集（fixpoint）。** 3 バイナリを起点に `ldd` を辿り、EXCLUDE 集合（glibc コア + 動的
   ローダのみ）以外の soname を `cp -L` で `$BUNDLE/lib/<soname>` に実体コピー。RPATH は既に焼かれて
   いるので **後処理なし**。`build-ffmpeg.sh` は `readelf -d` で各バイナリに `$ORIGIN` RPATH がある
   ことを検証し、無ければ **ビルドを失敗**させる（patchelf で繕わず、レシピ/ツールチェイン側で直す）。

EXCLUDE 集合（ホスト提供の glibc コア + ローダ）: `ld-linux-x86-64.so.2`, `linux-vdso.so.1`,
`libc.so.6`, `libm.so.6`, `libmvec.so.1`, `libpthread.so.0`, `libdl.so.2`, `librt.so.1`,
`libresolv.so.2`, `libanl.so.1`, `libnsl.so.1`, `libutil.so.1`, `libBrokenLocale.so.1`。
それ以外（`libstdc++` / `libgcc_s` と全コーデック / フィルタ libs）は全てバンドルする。
**Dockerfile の apt から `patchelf` は削除した。**

### 前提・注意

- **glibc はホスト依存。** バンドルは glibc コア + ローダを意図的に含めない。ホストの glibc が
  ビルド時（Ubuntu 24.04 = glibc 2.39）以上であることが前提。
- **ハードウェアアクセラレーションは実行時にホストドライバが別途必要。** nvenc/nvdec/cuda、vaapi、
  vdpau、vulkan、opencl などはホスト側のドライバ / ローダ（NVIDIA driver、libva ドライバ等）を
  必要とし、これらはバンドルしない。
- 各 export ステップは `set -euo pipefail` 下でも安全なよう必要箇所を `|| true` でガードするが、
  バンドル本体（バイナリ + lib コピー + tarball）は実際に生成される。`/output` 未マウント時は
  マウント方法のヒントを表示するだけで失敗扱いにはならない。

## ソースビルド依存（全 from-source / 正準順序）

FULL-BUILD では **全依存をソースビルド**する。正準な依存順序の完全リストは `scripts/build-deps.sh`
の `LIBS=( … )` を単一の真実とし、`Dockerfile` はそれをフェーズ単位の `RUN` にミラーする。各バージョンは
個々の `scripts/deps/<lib>.sh` の `VER=` でピン留め（pinned）。フェーズ概要:

- **phase 0 — pkg-config:** `pkgconf`（種コンパイラでビルド。以降の全 `verify_pc` が依存するため最初）。
- **phase 1 — toolchain（種コンパイラでビルド）:** `zlib` `zstd` `bzip2` `xz` → `gmp` `mpfr` `mpc`
  `isl` → `binutils` → `gcc`（**ここで `$ORIGIN` RPATH specs を設置**。以降は自前 gcc を使用）。
- **phase 2 — build tools（自前 gcc）:** `m4` `autoconf` `automake` `libtool` `nasm` `yasm` →
  `libffi` `openssl` `ncurses` `readline` `sqlite` → `python` → `ninja` `cmake` `meson`。
- **phase 3 — メディアライブラリ（自前 gcc、全て `$ORIGIN` RPATH 付き）:** ベース
  (`libogg` `libpng` `libjpeg-turbo` `expat` `gperf` `fftw` `lcms2`)、ビデオ
  (`x264` `x265` `xvid` `libvpx` `aom` `dav1d` `svtav1` `openh264` `libtheora` `libwebp` `openjpeg`、
  および apt 非提供の `vvenc` `xeve` `xevd` `xavs2` `davs2` `uavs3d` `rav1e`)、オーディオ
  (`lame` `opus` `libvorbis` `fdk-aac` `twolame` `libgsm` `speex`/`speexdsp` `opencore-amr`
  `vo-amrwbenc` `shine` `codec2` `libmysofa`)、字幕/テキスト/フィルタ
  (`freetype` `fribidi` `fontconfig` `harfbuzz` `libass` `aribb24` `libaribcaption` `zimg`
  `rubberband` `soxr` `vidstab` `frei0r` `ladspa` `libbs2b` `flite` `leptonica` `tesseract`
  `libvmaf`)、TLS/ネット (`nettle` `libtasn1` `libunistring` `p11-kit` `gnutls` → `librtmp`
  `libsrt` `libssh` `libzmq` `librist`)、demux/source (`libxml2` `snappy` `libgme` `libmodplug`
  `libopenmpt` `chromaprint` `libcaca` `libusb`/`libraw1394`/`libdc1394` `libcdio`/`libcdio-paranoia`
  `libbluray`)、デバイス/HW (`util-macros`→`xorgproto`→`libxau`/`libxdmcp`/`xcb-proto`/
  `libpthread-stubs`→`libxcb`、`alsa-lib` `sndio` `openal-soft` `sdl2`、
  `libdrm` `libva` `libvdpau` `v4l-utils`、`vulkan-headers`/`vulkan-loader`、
  `spirv-headers`→`spirv-tools`→`glslang`→`shaderc`、`libglvnd` `opencl-headers`/`ocl-icd` `libvpl`、
  `nv-codec-headers` `amf`)、最後に `libplacebo`（vulkan-loader+shaderc+lcms2 が必要）。

> **要 CI 検証:** フルビルドのエンドツーエンド検証は未実施（数時間かかる）。`.github/workflows/build.yml`
> が PR の create/sync でビルダーイメージを `docker build`→ghcr へ push（gha キャッシュ付き）し、
> `docker run` で FFmpeg をビルドして成果物を artifact 化する。未検証レシピは CI で反復修正する。
> なお `libsmbclient`(samba) / `libpulse`(pulseaudio) / `libjack`(jack2) はソースビルドが特に脆いため
> **意図的に外した**（下の「意図的に省略したライブラリ」参照。native AAC のように機能自体は影響軽微）。

## 有効化される機能 / 外部ライブラリ

**License:** `--enable-gpl --enable-version3 --enable-nonfree`

**Video codecs:** libx264, libx265, libxvid, libvpx, libaom, libdav1d, libsvtav1,
librav1e, libtheora, libopenh264, libvvenc, libxeve, libxevd, libxavs2,
libdavs2, libwebp, libopenjpeg

**Audio codecs:** libmp3lame, libopus, libvorbis, libfdk-aac, libtwolame, libgsm,
libspeex, libopencore-amrnb, libopencore-amrwb, libvo-amrwbenc, libshine, libcodec2,
libmysofa

**Subtitles / text / filters:** libass, libfreetype, libfribidi, libfontconfig,
libharfbuzz, libaribb24, libaribcaption, libzimg, librubberband, libsoxr, libvidstab,
libvmaf, frei0r, ladspa, libbs2b, libflite, libplacebo, libtesseract

**Protocols / network:** librtmp, libsrt (gnutls flavor), libssh, libzmq, librist,
gnutls, network

**Demux / containers / sources:** libbluray, libopenmpt, libgme, libmodplug, chromaprint,
libcaca, libdc1394, libcdio, libsnappy, libxml2, gmp

**Devices / capture / output:** openal, sndio, sdl2, libxcb (+shm
+xfixes +shape), libv4l2

**Hardware acceleration:** vaapi, vdpau, vulkan (+libshaderc for libplacebo compute),
opencl, opengl, amf, nvenc, nvdec, cuvid, ffnvcodec, cuda-llvm, libvpl (oneVPL), libdrm,
v4l2-m2m

**Misc/core:** shared, pic, pthreads, iconv, zlib, bzlib, lzma, runtime-cpudetect
（libpostproc は configure フラグを持たず自動でビルドされる）

**検証済み feature counts (FFmpeg 8.1.1):** encoders 243, decoders 569, muxers 195, demuxers 380,
filters 570, formats 434, protocols 71, hwaccels 8（hwaccels = vdpau, cuda, vaapi, qsv, drm,
opencl, vulkan, amf）。

### 設計上の選択

- **すべてソースビルド（FULL-BUILD）。** apt はライブラリを install しない。ツールチェイン・
  ビルドツール・全 lib を自前 gcc で `/usr/local` にソースビルドする。唯一の例外は OS フロアと
  自前 gcc を立ち上げるための **ブートストラップ seed**（種 gcc/make/perl 等。コンパイラは無から
  自分自身をコンパイルできないため不可避で、LFS でもホストツールチェインから bootstrap する）と、
  rav1e 用の rustup（種 Rust。同様に rustc は rustc を要する）。
- **patchelf 不使用。** 再配置可能性は自前 gcc の `specs` でリンク時に `$ORIGIN` RPATH を焼くことで
  実現（前述「バンドルの仕組み」）。
- **Shared build。** `--enable-shared` を使用し `--pkg-config-flags="--static"` は渡さない。
  各 lib は shared (`.so`) でソースビルドし、`$ORIGIN` RPATH バンドルで配布する。
- **TLS = GnuTLS**（LGPL、GPL とのフリクションなし）。OpenSSL はソースビルドするが **python の
  ssl/hashlib 用途のみ** で、FFmpeg の TLS バックエンドには使わない（`--enable-openssl` は付けない。
  OpenSSL/GPL nonfree taint と TLS 二重化の回避）。`libsrt` は `-DUSE_ENCLIB=gnutls` でビルド。
- **QSV は libvpl（modern Intel oneVPL）を使用、libmfx は不使用。** 両者は FFmpeg 上で相互排他。
- **CUDA は clang/LLVM 経由**（`--enable-cuda-llvm`）。proprietary な NVIDIA CUDA toolkit は
  ビルド時に不要。`nvcc` / `libnpp`（nonfree）は使わない。
- **vulkan は headers + loader を共にソースビルド。** `vulkan-headers.sh`（Khronos Vulkan-Headers
  >=1.3.277）+ `vulkan-loader.sh`（libvulkan.so + vulkan.pc）。`libplacebo.sh` は meson で
  vulkan + shaderc + lcms2（`lcms2.sh`）付きビルド。**opengl は `libglvnd` をソースビルド**して
  libGL を提供（mesa はビルドしない。実 GPU ドライバは実行時にホストが提供）。

## ./configure フラグ全体

`build-ffmpeg.sh` が `docker run` 時に渡すフラグ集合（固定の前段フラグ + `ENABLE_FLAGS[@]`）。
libpostproc は自動ビルドのため `--enable-postproc` は **存在しない**（FFmpeg 8.1.1 は
'Unknown option' として拒否する）。

```
--prefix=/usr/local
--extra-cflags=-I/usr/local/include
--extra-ldflags=-L/usr/local/lib
--extra-libs=-lstdc++ -lm -lpthread -ldl
--ld=g++
--disable-debug
--enable-gpl --enable-version3 --enable-nonfree
--enable-shared --enable-pic --enable-pthreads --enable-network
--enable-gnutls --enable-iconv --enable-zlib --enable-bzlib --enable-lzma
--enable-libxml2 --enable-libsnappy --enable-gmp --enable-runtime-cpudetect
--enable-libx264 --enable-libx265 --enable-libxvid --enable-libvpx --enable-libaom
--enable-libdav1d --enable-libsvtav1 --enable-librav1e --enable-libtheora
--enable-libopenh264 --enable-libvvenc --enable-libxeve --enable-libxevd
--enable-libxavs2 --enable-libdavs2 --enable-libwebp --enable-libopenjpeg
--enable-libmp3lame --enable-libopus --enable-libvorbis --enable-libfdk-aac --enable-libtwolame
--enable-libgsm --enable-libspeex --enable-libopencore-amrnb --enable-libopencore-amrwb
--enable-libvo-amrwbenc --enable-libshine --enable-libcodec2 --enable-libmysofa
--enable-libass --enable-libfreetype --enable-libfribidi --enable-libfontconfig --enable-libharfbuzz
--enable-libaribb24 --enable-libaribcaption --enable-libzimg --enable-librubberband
--enable-libsoxr --enable-libvidstab --enable-libvmaf --enable-frei0r --enable-ladspa
--enable-libbs2b --enable-libflite --enable-libplacebo --enable-libtesseract
--enable-librtmp --enable-libsrt --enable-libssh --enable-libzmq --enable-librist
--enable-libbluray --enable-libopenmpt --enable-libgme --enable-libmodplug --enable-chromaprint
--enable-libcaca --enable-libdc1394 --enable-libcdio --enable-openal
--enable-sndio --enable-sdl2 --enable-libxcb --enable-libxcb-shm --enable-libxcb-xfixes --enable-libxcb-shape
--enable-libv4l2 --enable-vaapi --enable-vdpau --enable-vulkan --enable-libshaderc --enable-opencl --enable-opengl
--enable-amf --enable-nvenc --enable-nvdec --enable-cuvid --enable-ffnvcodec --enable-cuda-llvm
--enable-libvpl --enable-libdrm --enable-v4l2-m2m
```

## 意図的に省略したライブラリ（理由つき）

maximal なフラグ wishlist にあったが、このビルドに **ソースレシピを用意していない**
（`scripts/deps/` に該当スクリプトが無い）、または provider はあっても FFmpeg 8.1.1 の要求 API より
古すぎて使えないため `--enable-*` を省略している。渡すと `./configure` が hard-fail する。
（下表の「apt なし」等の記述は旧 apt ベース時の理由。FULL-BUILD では一律「ソースレシピ未追加」と
読み替える。必要なら `scripts/deps/<lib>.sh` を追加し `build-deps.sh`/`Dockerfile`/`build-ffmpeg.sh`
に組み込めば有効化できる。）

| Flag | 省略理由 |
|------|----------|
| `--enable-libkvazaar` | 24.04 に apt なし、ソースレシピなし。 |
| `--enable-libilbc` | `libilbc` は Ubuntu archive から削除済み。provider なし。 |
| `--enable-libxavs` | AVS1 エンコーダ。未パッケージ、レシピなし（xavs2 とは別物）。 |
| `--enable-libjxl` | 検証済み apt セットに `libjxl-dev` なし、レシピなし。 |
| `--enable-liboapv` | APV codec。未パッケージ、レシピなし。 |
| `--enable-libsvtjpegxs` | SVT JPEG-XS。未パッケージ、レシピなし。 |
| `--enable-liblc3` | LC3 codec。未パッケージ、レシピなし。 |
| `--enable-libzvbi` | Teletext (`libzvbi-dev`)。検証済み apt セットになし、レシピなし。 |
| `--enable-librsvg` | `librsvg2-dev`/cairo。検証済み apt セットになし、レシピなし。 |
| `--enable-libqrencode` | `libqrencode-dev`。検証済み apt セットになし、レシピなし。 |
| `--enable-libquirc` | `libquirc-dev`。検証済み apt セットになし、レシピなし。 |
| `--enable-librabbitmq` | `librabbitmq-dev`。検証済み apt セットになし、レシピなし。 |
| `--enable-libdvdnav` | `libdvdnav-dev`。検証済み apt セットになし、レシピなし。 |
| `--enable-libdvdread` | `libdvdread-dev`。検証済み apt セットになし、レシピなし。 |
| `--enable-libiec61883` | `libiec61883-dev`。検証済み apt セットになし、レシピなし。 |
| `--enable-libcelt` | `libcelt-dev`。検証済み apt セットになし、レシピなし。 |
| `--enable-libopencv` | `libopencv-dev`。検証済み apt セットになし、レシピなし。 |
| `--enable-vapoursynth` | `vapoursynth`。検証済み apt セットになし、レシピなし。 |
| `--enable-libmfx` | 意図的に drop。選択した `--enable-libvpl` と競合する。 |
| `--enable-openssl` | 意図的に drop。TLS バックエンドは GnuTLS に一本化。 |
| `--enable-libuavs3d` | uavs3d v1.1 が FFmpeg 8.1.1 の要求 API より古く compile error。24.04 に新版 provider なし。 |
| `--enable-liblensfun` | Ubuntu 24.04 の lensfun 0.3.4 に lf_db_create() が無く configure が link 失敗。 |
| `--enable-libsmbclient` | Samba のソースビルドが非常に重く脆い（独自 waf + python + 大きな依存ツリー）ため、ビルド信頼性を優先して FULL-BUILD では意図的に外した。必要なら `scripts/deps/samba.sh` 相当を追加し再有効化可能。 |
| `--enable-libpulse` | PulseAudio のソースビルドが重く（hard dep の libsndfile→FLAC を含む）脆いため意図的に外した。必要なら `pulse`/`libsndfile`/`flac` のレシピを追加し再有効化可能。 |
| `--enable-libjack` | jack2 の waf ビルドが脆いため意図的に外した。必要なら `scripts/deps/jack.sh` 相当を追加し再有効化可能。 |

## ライセンス注意（再配布不可）

このビルドは `--enable-gpl --enable-version3 --enable-nonfree` であり、nonfree な
**fdk-aac** エンコーダをリンクする。結果のバイナリは **GPL-tainted かつ再配布不可
(NON-redistributable)**。personal / internal / server 用途を想定する。再配布可能な
バイナリが必要なら `--enable-nonfree` と `--enable-libfdk-aac` を外し（native AAC は使える）、
実際に必要な GPL ライブラリを再評価すること。
