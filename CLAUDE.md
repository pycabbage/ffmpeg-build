# ffmpeg-build — プロジェクトドキュメント

Ubuntu 24.04 上で、外部コーデック / フィルタ / ハードウェアアクセラレーション / プロトコルを
可能な限り盛り込んだ **maximal full-featured FFmpeg 8.1.1 ("Hoare")** をビルドする
Docker リポジトリ。GPL + version3 + nonfree variant。

## アーキテクチャ

- **build image = `docker build` で作られるビルド *環境*。** ビルドツールチェイン、すべての
  apt `-dev` 依存、すべてのソースビルド依存をインストールする。**FFmpeg のソースもバイナリも
  イメージには含まれない。** `docker build` 中に FFmpeg の `./configure` / `make` は実行されない。
- **FFmpeg は `docker run` 時にコンパイルされる。** ENTRYPOINT が `scripts/build-ffmpeg.sh` を
  実行し、このスクリプトが **実行時に FFmpeg ソースをダウンロード** し（イメージにベイクしない）、
  configure / build / install / verify を走らせる。
- **レイヤキャッシュ設計:** `Dockerfile` は `COPY scripts/deps/ /opt/scripts/deps/` を 13 個の
  依存ビルド `RUN` の **前** に置き、`COPY scripts/build-ffmpeg.sh scripts/build-deps.sh
  /opt/scripts/` を最後の依存 `RUN` の **後**（ENTRYPOINT 直前）に置く。これにより
  `build-ffmpeg.sh` を編集してもコスト高な依存レイヤのキャッシュが無効化されない。

### リポジトリ構成

| ファイル | 役割 |
|------|------|
| `Dockerfile` | 単一ステージのビルドイメージ。apt deps + ソース deps（1 lib につき 1 `RUN`）。FFmpeg のソース / コンパイルは含まない。 |
| `.dockerignore` | ビルドコンテキストを最小化（イメージは FFmpeg を自分で取得する）。 |
| `scripts/build-ffmpeg.sh` | **ENTRYPOINT**。`docker run` 時に FFmpeg をダウンロード → configure → build → install → verify → `/output` へバンドル出力。 |
| `scripts/build-deps.sh` | ソースビルド依存セットの便宜ドライバ / ドキュメント（Dockerfile は各 `deps/*.sh` を個別に実行）。 |
| `scripts/deps/*.sh` | 各ソースビルド依存（下表）。 |

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

### バンドルの仕組み（patchelf / RPATH / $ORIGIN）

naive な「バイナリだけコピー」では、ffmpeg がイメージ内の共有 lib（`libavdevice.so.62` など、
`/usr/local/lib` や multiarch 配下）にリンクしているためホストで
`libavdevice.so.62: cannot open shared object file` で失敗する。そこで:

1. **依存の再帰収集（fixpoint）。** 3 バイナリを起点に worklist を回し、各 ELF の `ldd` 出力の
   `<soname> => <path> (0x..)` 行をパースする。EXCLUDE 集合（後述）以外の soname は、未収集なら
   `<path>` の実体を `cp -L` で `$BUNDLE/lib/<soname>` にコピーし worklist に追加。新規が無く
   なるまで繰り返す。
2. **EXCLUDE 集合 = glibc コア + 動的ローダのみ**（ホストが提供）:
   `ld-linux-x86-64.so.2`, `linux-vdso.so.1`, `libc.so.6`, `libm.so.6`, `libmvec.so.1`,
   `libpthread.so.0`, `libdl.so.2`, `librt.so.1`, `libresolv.so.2`, `libanl.so.1`, `libnsl.so.1`,
   `libutil.so.1`, `libBrokenLocale.so.1`。**それ以外は全てバンドルする**
   （`libstdc++` / `libgcc_s` / `libcrypt` と全コーデック / フィルタ libs を含む）。
3. **RPATH で再配置可能化。** `patchelf --set-rpath '$ORIGIN/lib'` を 3 バイナリに、
   `patchelf --set-rpath '$ORIGIN'` を `lib/*.so*` 全てに設定する。`$ORIGIN` は **シングルクォート**
   で渡し（シェル展開させず patchelf にリテラル文字列として保存させる）、動的ローダが実行時に
   「ロード対象 ELF のあるディレクトリ」へ解決する。これによりバイナリは隣の `lib/` を、バンドル
   された lib は同居する兄弟 lib を、絶対パス非依存で見つける。

そのため Dockerfile の apt 一覧に **`patchelf`** を追加してある。

### 前提・注意

- **glibc はホスト依存。** バンドルは glibc コア + ローダを意図的に含めない。ホストの glibc が
  ビルド時（Ubuntu 24.04 = glibc 2.39）以上であることが前提。
- **ハードウェアアクセラレーションは実行時にホストドライバが別途必要。** nvenc/nvdec/cuda、vaapi、
  vdpau、vulkan、opencl などはホスト側のドライバ / ローダ（NVIDIA driver、libva ドライバ等）を
  必要とし、これらはバンドルしない。
- 各 export ステップは `set -euo pipefail` 下でも安全なよう必要箇所を `|| true` でガードするが、
  バンドル本体（バイナリ + lib コピー + tarball）は実際に生成される。`/output` 未マウント時は
  マウント方法のヒントを表示するだけで失敗扱いにはならない。

## ソースビルド依存（pinned versions）

`Dockerfile` は cacheability のため 1 lib につき 1 `RUN` で `scripts/deps/<lib>.sh` を実行する。ソースビルド依存セットは現在 **13 個**（下表）。

| スクリプト | 内容 | version |
|------|------|---------|
| `deps/nv-codec-headers.sh` | NVENC/NVDEC/CUVID/ffnvcodec/cuda-llvm 用ヘッダ | `n12.2.72.0` |
| `deps/amf.sh` | AMD AMF ヘッダ | `v1.5.2` |
| `deps/vvenc.sh` | Fraunhofer H.266/VVC エンコーダ | `v1.14.0` |
| `deps/xeve.sh` | MPEG-5 EVC エンコーダ (MAIN profile) | `v0.5.1` |
| `deps/xevd.sh` | MPEG-5 EVC デコーダ (MAIN profile) | `v0.5.0` |
| `deps/uavs3d.sh` | AVS3 デコーダ | `v1.1` |
| `deps/xavs2.sh` | AVS2 エンコーダ (GPL) | `1.4` |
| `deps/davs2.sh` | AVS2 デコーダ (GPL) | `1.7` |
| `deps/libaribcaption.sh` | ARIB STD-B24 caption renderer | `v1.1.1` |
| `deps/libvmaf.sh` | Netflix VMAF（24.04 に apt パッケージなし） | `v3.1.0` |
| `deps/rav1e.sh` | Rust AV1 エンコーダ（apt なし。cargo-c でビルド） | `v0.8.1` |
| `deps/vulkan-headers.sh` | Khronos Vulkan-Headers（Vulkan ヘッダ >=1.3.277 + vulkan.pc; --enable-vulkan / libplacebo 用） | `v1.4.323` |
| `deps/libplacebo.sh` | VideoLAN libplacebo（libplacebo フィルタ / トーンマッピング; meson, vulkan+shaderc+lcms） | `v7.349.0` |

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
libsmbclient, gnutls, network

**Demux / containers / sources:** libbluray, libopenmpt, libgme, libmodplug, chromaprint,
libcaca, libdc1394, libcdio, libsnappy, libxml2, gmp

**Devices / capture / output:** openal, libpulse, libjack, sndio, sdl2, libxcb (+shm
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

- **Shared build。** `--enable-shared` を使用し `--pkg-config-flags="--static"` は意図的に
  渡さない（大量の外部 lib に対し static pkg-config 解決を強制すると共有依存のリンクが壊れうる）。
  static build は不可（Ubuntu 24.04 の apt `-dev` は `.so` のみで `.a` を同梱しないため
  `--enable-static` ではほとんどの lib のリンクが失敗する）。代わりに **shared + バンドル** を採る。
- **TLS = GnuTLS**（LGPL、GPL とのフリクションなし）。`libssl-dev` は入っているが OpenSSL は
  有効化しない（OpenSSL/GPL nonfree taint と TLS バックエンド二重化の回避）。`libsrt-gnutls-dev`
  を `--enable-gnutls` と組み合わせる。
- **QSV は libvpl（modern Intel oneVPL）を使用、libmfx は不使用。** 両者は FFmpeg 上で相互排他。
- **CUDA は clang/LLVM 経由**（`--enable-cuda-llvm`）。proprietary な NVIDIA CUDA toolkit は
  ビルド時に不要。`nvcc` / `libnpp`（nonfree）は使わない。
- **SVT-AV1 / fdk-aac は apt 由来。** FFmpeg 8.1.1 の configure に対する preflight で apt 版が
  最小要件を満たすことを確認済み（SvtAv1Enc 1.7.0 >= 0.9.0 など）。
- **vulkan ヘッダと libplacebo は apt にあるが古すぎて使えないため、/usr/local に新版を
  ソースビルドして apt 版を shadow する。** apt の `libvulkan-dev` は vulkan.pc が 1.3.275 を報告し
  FFmpeg 8.1.1 の `vulkan >= 1.3.277` を満たさず、apt の `libplacebo` 6.338.2 は FFmpeg 8.1.1 の
  ffplay_renderer コンパイルを壊す。そこで `scripts/deps/vulkan-headers.sh`（Vulkan-Headers v1.4.323 +
  >=1.3.277 を報告する shadow vulkan.pc、loader 自体は apt の libvulkan.so をリンク）と
  `scripts/deps/libplacebo.sh`（libplacebo v7.349.0 を meson で vulkan+shaderc+lcms 付きビルド）を
  /usr/local に入れ、PKG_CONFIG_PATH で apt 版より優先させる。libplacebo のために `liblcms2-dev` を
  apt 追加した。**apt に全く無く必ずソースビルドするのは libvmaf と rav1e。**
- `libde265-dev` は（他 apt パッケージの依存として）入っているが FFmpeg に `--enable-libde265`
  フラグは無い（HEVC decode は内部実装）ため、フラグでの参照はない。

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
--enable-librtmp --enable-libsrt --enable-libssh --enable-libzmq --enable-librist --enable-libsmbclient
--enable-libbluray --enable-libopenmpt --enable-libgme --enable-libmodplug --enable-chromaprint
--enable-libcaca --enable-libdc1394 --enable-libcdio --enable-openal --enable-libpulse --enable-libjack
--enable-sndio --enable-sdl2 --enable-libxcb --enable-libxcb-shm --enable-libxcb-xfixes --enable-libxcb-shape
--enable-libv4l2 --enable-vaapi --enable-vdpau --enable-vulkan --enable-libshaderc --enable-opencl --enable-opengl
--enable-amf --enable-nvenc --enable-nvdec --enable-cuvid --enable-ffnvcodec --enable-cuda-llvm
--enable-libvpl --enable-libdrm --enable-v4l2-m2m
```

## 意図的に省略したライブラリ（理由つき）

maximal なフラグ wishlist にあったが Ubuntu 24.04 に provider が無い（apt `-dev` パッケージも
スコープ内のソースレシピも無い）、または provider はあっても FFmpeg 8.1.1 の要求 API より
古すぎて使えないため `--enable-*` を省略している。渡すと `./configure` が
hard-fail する。

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

## ライセンス注意（再配布不可）

このビルドは `--enable-gpl --enable-version3 --enable-nonfree` であり、nonfree な
**fdk-aac** エンコーダをリンクする。結果のバイナリは **GPL-tainted かつ再配布不可
(NON-redistributable)**。personal / internal / server 用途を想定する。再配布可能な
バイナリが必要なら `--enable-nonfree` と `--enable-libfdk-aac` を外し（native AAC は使える）、
実際に必要な GPL ライブラリを再評価すること。
