---
status: implemented
---

# フルビルド

## 概要

ライブラリの `apt install` を廃止し、ビルドに必要なすべての依存関係をソースコードからビルドする。
成果物に直接必要なライブラリ ( `libx264` など ) の他に、ビルドツール ( `cmake` `gcc` `python` など ) およびそれらの依存関係もすべてソースコードからビルドする。
併せて、patchelfによる成果物への侵害を排除する。

## 目的

現状のビルドフローはpatchelfに依存しており、成果物に対する非効率かつ不安定な侵害を引き起こしている。
この問題を解決するために、ビルドフローを完全に見直し、すべての依存関係をソースコードからビルドすることで、成果物の品質と安定性を向上させることを目的とする。
この変更により、ビルドプロセスがより一貫性のあるものとなり、成果物の品質が向上することが期待される。

## 実装状況 (status: implemented)

### 完了したこと

- **apt ライブラリ install を全廃。** `Dockerfile` の apt は OS フロア + ブートストラップ
  seed（`build-essential`/`m4`/`curl`/`git`/`perl`/`gettext`/`texinfo` など。自前 gcc をコンパイル
  するためだけの種コンパイラ。成果物には入らない）のみ。`-dev` ライブラリ・`cmake`/`meson`/
  `ninja`/`nasm`/`pkg-config`/`patchelf` は **一切 install しない**。
- **すべてソースビルド。** ツールチェイン（`gcc`/`binutils` + `gmp`/`mpfr`/`mpc`/`isl`）、
  ビルドツール（`pkgconf`/`m4`/`autoconf`/`automake`/`libtool`/`nasm`/`yasm`/`ncurses`/
  `readline`/`sqlite`/`openssl`/`libffi`/`python`/`ninja`/`cmake`/`meson`）、および全メディア
  ライブラリ（約100）を `/usr/local` に依存順でソースビルド。各レシピは `scripts/deps/*.sh`、
  共通契約は `scripts/deps/common.sh`、正準順序は `scripts/build-deps.sh`、段階は `Dockerfile`。
- **patchelf 全廃。** `scripts/deps/common.sh` が `LD_RUN_PATH=$ORIGIN:$ORIGIN/../lib:$ORIGIN/lib`
  を export し、`scripts/deps/binutils.sh` を `--disable-new-dtags` で構成した自前 `ld` が、
  **リンク時に**全バイナリ・全共有ライブラリへ relocatable な `$ORIGIN` **DT_RPATH（OLD dtags）**を
  焼き込む。gcc の `specs` ファイルは**使わない**（既定 specs は gcc の `--eh-frame-hdr`＝C++ 例外
  巻き戻しと libgcc_s 自動リンクを壊すため。`scripts/deps/gcc.sh` 冒頭コメント参照）。DT_RPATH は
  推移的依存（`libstdc++`→`libgcc_s`）まで伝播するため DT_RUNPATH では不可。成果物を後から書き換える
  patchelf は不要。`build-ffmpeg.sh` は `readelf -d` で 3 バイナリの `$ORIGIN` rpath を検証し、
  無ければビルドを失敗させる（黙って壊れたバンドルを出さない）。

### このセッションで検証済み（ローカルでエンドツーエンド完走）

`docker build`（全依存ソースビルド）→ `docker run`（FFmpeg 8.1.1 コンパイル + 検証 + バンドル）を
ローカルで完走し、フルビルドを初めてエンドツーエンドで確認した:

- **全依存（約100 + ツールチェイン + ビルドツール + clang/LLVM）をソースビルド**して
  `ffmpeg-build` イメージが完成。
- FFmpeg 8.1.1 が GPL+version3+nonfree で configure/compile/install 成功。`--enable-cuda-llvm`・
  `--enable-libplacebo` 等を含む全フラグが有効。**feature counts: encoders 243 / decoders 569 /
  hwaccels 8（vdpau cuda vaapi qsv drm opencl vulkan amf）**。
- **patchelf 不使用で再配置可能。** `ffmpeg`/`ffprobe`/`ffplay` の 3 バイナリすべてに
  `$ORIGIN:$ORIGIN/../lib:$ORIGIN/lib` の DT_RPATH（OLD dtags）が `readelf -d` で確認でき、
  129 個の共有ライブラリをバンドル。tarball を**別ディレクトリに展開して `./ffmpeg -version` が動作**
  （`ldd` の not-found = 0）し、相対 `$ORIGIN` だけで全依存を解決することを実証。

このセッションで追加・修正したレシピ:

- **`libXext`**（X11 拡張）を追加。`libglvnd`（opengl/GLX）が `xext` を要求するため。
- **`llvm`（clang/LLVM をソースビルド）**を追加。`--enable-cuda-llvm` が CUDA フィルタを clang で
  PTX 化するため `clang` を要求する（X86+NVPTX のみの最小構成、ビルド時専用・成果物に非リンク）。
- **`libplacebo`** の `libav.h` に `#include <libavformat/version.h>` をパッチ（ビルド前のソース修正）。
  FFmpeg 自身のビルドは `HAVE_AV_CONFIG_H` 下で `avformat.h` が `version.h` を引かず
  `LIBAVFORMAT_VERSION_INT` 未定義 → libplacebo が削除済み `av_stream_get_side_data` を選び
  `vf_libplacebo.c` がコンパイル失敗する問題を解消。
- **`build-ffmpeg.sh`** が configure 前に pkg-config の再配置非互換フラグ（SDL2 が注入する
  `-Wl,-rpath,<abs>` / `-Wl,--enable-new-dtags`）を全 `.pc` から除去。これが無いと `ffplay` のみ
  絶対 DT_RUNPATH になり再配置不能だった。

### CI（GitHub Actions）

- `.github/workflows/build.yml` が PR の create/sync で起動し、`docker/build-push-action`
  （`cache-from`/`cache-to: type=registry,ref=ghcr.io/<repo>:buildcache,mode=max`）でビルダーイメージを
  ビルド→ghcr へ push → `docker run` で FFmpeg をビルド → 成果物を artifact 化する。
- 上記の**エンドツーエンド検証はローカルで実施**した（GitHub MCP/CI が不安定だったため）。ローカルでは
  CPU/メモリを絞り（`--build-arg JOBS=N`）、egress プロキシの CA をベースイメージに注入して `docker build`
  を通した。追加した clang/LLVM ビルドは重く GitHub ランナーの空きディスクを超え得る（CI 緑化が必要に
  なれば runner のディスク確保等を別途検討）。

### 残作業 / 今後

- フルビルドのエンドツーエンド検証は **完了**（上記）。
- **「意図的に省略したライブラリ」18 本のうち 16 本を from-source で復活**（フォローオン作業。各々ローカルで
  build→run 検証済み）: libkvazaar / libqrencode / librabbitmq / liblc3 / libilbc / libsvtjpegxs /
  libdvdread / libdvdnav / libquirc / libzvbi / libcelt / vapoursynth / libjxl / libiec61883 /
  libopencv / librsvg（+依存チェーン pcre2/glib/pixman/cairo/pango/gdk-pixbuf, libavc1394+librom1394）。
  残り 2 本 `liboapv`・`libxavs` は本環境から公開ソースを取得できず未対応（`CLAUDE.md` の表参照）。
  feature counts: encoders 243→249 / decoders 569→577。
- **特に脆い 3 つ**（`libsmbclient`=Samba, `libpulse`=PulseAudio(+libsndfile+FLAC), `libjack`=jack2）は
  ソースビルドが壊れやすいため **意図的に drop 済み**（`CLAUDE.md` の「意図的に省略したライブラリ」参照）。
  必要になれば該当レシピと `--enable-*` を再追加して有効化できる。
