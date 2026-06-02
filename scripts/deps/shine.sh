#!/usr/bin/env bash
# libshine — fixed-point MP3 encoder; serves FFmpeg --enable-libshine.
# Uses autotools; upstream tarball has no configure — autoreconf required.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="3.1.1"
SRC="${SRCROOT}/shine"

fetch_tar "https://github.com/toots/shine/archive/refs/tags/${VER}.tar.gz" "${SRC}"
cd "${SRC}"
autoreconf -fiv
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static
make -j"${JOBS}"
make install
ldconfig

verify_pc shine
cleanup "${SRC}"
