#!/usr/bin/env bash
# xvidcore — MPEG-4 ASP (Xvid) encoder/decoder; FFmpeg --enable-libxvid.
# configure lives under build/generic/ (not the repo root).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.3.7"
SRC="${SRCROOT}/xvidcore"

fetch_tar "https://downloads.xvid.com/downloads/xvidcore-${VER}.tar.gz" "${SRC}"
cd "${SRC}/build/generic"
./configure --prefix="${PREFIX}"
make -j"${JOBS}"
make install
# xvidcore installs only a static lib by default on some paths; ensure the shared lib is linked.
ldconfig

# xvidcore ships no .pc; check for the shared library directly.
test -f "${PREFIX}/lib/libxvidcore.so" || test -f "${PREFIX}/lib/libxvidcore.so.4"
cleanup "${SRC}"
