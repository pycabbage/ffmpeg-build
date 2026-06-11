# ffmpeg-build

フル機能 FFmpeg を Docker でビルドするリポジトリ。ビルド環境は `docker build` で作成し、FFmpeg 本体はソースを実行時にダウンロードして `docker run` 時にコンパイルする。

ビルド環境は **すべてソースからビルド**する（`docs/todo/001-full-build.md`）。ツールチェイン（gcc/binutils + 依存）、ビルドツール（cmake/meson/ninja/nasm/python など）、全メディアライブラリを `/usr/local` にソースビルドし、apt はライブラリを一切 install しない（OS フロア + 自前 gcc 用ブートストラップ seed のみ）。**patchelf は使わず**、`scripts/deps/common.sh` の `LD_RUN_PATH` と binutils `--disable-new-dtags`（OLD dtags = DT_RPATH）により、自前 ld がリンク時に `$ORIGIN` RPATH を焼き込んで再配置可能にする（gcc `specs` は使わない）。

## 使い方

1. ビルドイメージを作成: `docker build -t ffmpeg-build .`
2. FFmpeg をビルドして出力: `docker run --rm -v "$PWD/out:/output" ffmpeg-build`

## 出力 (./out)

`docker run` は **ホストで直接実行できる自己完結バンドル** を `./out/` に出力する:

- `out/ffmpeg` / `out/ffprobe` / `out/ffplay` — そのまま `./out/ffmpeg -version` のようにホストで直接実行できる。
- `out/lib/` — バンドルされた共有ライブラリ（`libavcodec.so.*`、コーデック / フィルタ libs、`libstdc++` など）。各バイナリは **リンク時に焼き込まれた** RPATH `$ORIGIN/lib`（`scripts/deps/common.sh` の `LD_RUN_PATH` + binutils `--disable-new-dtags` による。gcc specs / patchelf は不使用）を持つため、`out/lib/` から自分のライブラリを解決する（イメージ内パスに依存しない）。
- `out/ffmpeg-<version>-linux-x86_64.tar.gz` — 上記 4 点（`ffmpeg ffprobe ffplay lib/`）を相対パスで含む **再配置可能 (relocatable)** な tarball。任意の場所に展開してそのまま実行できる。

バンドルはホストの glibc（ビルド時 = Ubuntu 24.04 の glibc 2.39 以上）に依存する。実行時のハードウェアアクセラレーション（nvenc/nvdec/cuda、vaapi、vdpau、vulkan、opencl など）にはホスト側のドライバ / ローダが別途必要（バンドルには含めない）。

詳細（アーキテクチャ、有効化機能の一覧、依存ライブラリ、`./configure` フラグ、バンドル方式、ライセンス注意、バージョン変更方法）は `CLAUDE.md` を参照。
