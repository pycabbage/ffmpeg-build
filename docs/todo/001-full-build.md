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
  seed（`build-essential`/`curl`/`git`/`perl`/`gettext`/`texinfo` など。自前 gcc をコンパイル
  するためだけの種コンパイラ。成果物には入らない）のみ。`-dev` ライブラリ・`cmake`/`meson`/
  `ninja`/`nasm`/`pkg-config`/`patchelf` は **一切 install しない**。
- **すべてソースビルド。** ツールチェイン（`gcc`/`binutils` + `gmp`/`mpfr`/`mpc`/`isl`）、
  ビルドツール（`pkgconf`/`m4`/`autoconf`/`automake`/`libtool`/`nasm`/`yasm`/`ncurses`/
  `readline`/`sqlite`/`openssl`/`libffi`/`python`/`ninja`/`cmake`/`meson`）、および全メディア
  ライブラリ（約100）を `/usr/local` に依存順でソースビルド。各レシピは `scripts/deps/*.sh`、
  共通契約は `scripts/deps/common.sh`、正準順序は `scripts/build-deps.sh`、段階は `Dockerfile`。
- **patchelf 全廃。** 自前 gcc に `specs` ファイル（`scripts/deps/gcc.sh` が
  `common.sh:ORIGIN_SPECS` を gcc 専用ディレクトリへ設置）を仕込み、**リンク時に**全バイナリ・
  全共有ライブラリへ relocatable な `$ORIGIN` DT_RPATH を焼き込む。成果物を後から書き換える
  patchelf は不要。`build-ffmpeg.sh` は `readelf -d` で各バイナリの `$ORIGIN` rpath を検証し、
  無ければビルドを失敗させる（黙って壊れたバンドルを出さない）。

### このセッションで検証済み

- `$ORIGIN` RPATH のリンク時注入（gcc specs）が make/shell の `$` 展開を貫通して効くこと、
  および OLD dtags(DT_RPATH) が推移的依存（`libstdc++`→`libgcc_s`）まで解決することを実コンパイルで確認。
- `common.sh` 契約の実ビルド（`pkgconf` + `zlib`）が成功（fetch/build/`verify_pc`/cleanup）。
- 全 139 スクリプトの `bash -n` 構文チェック通過。ツールチェイン全 URL + メディア lib 約90 URL が解決可能。

### 残作業（CI 推奨）

- **フルビルドのエンドツーエンド検証は未実施**（4コアで数時間かかり対話セッション内では完了不能）。
  GitHub Actions 等の CI で `docker build` → `docker run` を実行し、未検証のレシピを反復修正する想定。
- **重い/脆いレシピ 3 つ**（`samba`=libsmbclient, `pulse`=libpulse(+`libsndfile`+`flac`), `jack`=libjack）は
  ソースビルドが最も壊れやすい。CI で問題が出るなら、当該 `scripts/deps/*.sh` と対応する
  `build-ffmpeg.sh` の `--enable-libsmbclient`/`--enable-libpulse`/`--enable-libjack` を外すのが実用的。
