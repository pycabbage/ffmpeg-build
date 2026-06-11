#!/usr/bin/env bash
# twolame — MPEG Audio Layer 2 (MP2) encoder; serves FFmpeg --enable-libtwolame.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="0.4.0"
SRC="${SRCROOT}/twolame"

fetch_tar "https://sourceforge.net/projects/twolame/files/twolame/${VER}/twolame-${VER}.tar.gz/download" "${SRC}"
cd "${SRC}"
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static
make -j"${JOBS}"
make install
ldconfig

verify_pc twolame
cleanup "${SRC}"
