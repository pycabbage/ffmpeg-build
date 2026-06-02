#!/usr/bin/env bash
# LAME mp3 encoder — serves FFmpeg --enable-libmp3lame.
# Ships NO .pc file; sanity-check the shared lib directly.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="3.100"
SRC="${SRCROOT}/lame"

fetch_tar "https://sourceforge.net/projects/lame/files/lame/${VER}/lame-${VER}.tar.gz/download" "${SRC}"
cd "${SRC}"
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static \
  --enable-nasm \
  --disable-frontend
make -j"${JOBS}"
make install
ldconfig

test -f "${PREFIX}/lib/libmp3lame.so"
cleanup "${SRC}"
