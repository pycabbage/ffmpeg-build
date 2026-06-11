#!/usr/bin/env bash
# Little-CMS 2 (lcms2) — colour management. In the apt build this was liblcms2-dev; here it is
# built from source because libplacebo.sh configures with -Dlcms=enabled (tone mapping). Ships
# lcms2.pc. No direct FFmpeg flag; pulled in transitively via libplacebo.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2.16"
SRC="${SRCROOT}/lcms2"

fetch_tar "https://github.com/mm2/Little-CMS/releases/download/lcms${VER}/lcms2-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --disable-static --enable-shared
make -j"${JOBS}"
make install
ldconfig

verify_pc lcms2
cleanup "${SRC}"
