#!/usr/bin/env bash
# vo-amrwbenc — VisualOn AMR-WB encoder; serves FFmpeg --enable-libvo-amrwbenc.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="0.1.3"
SRC="${SRCROOT}/vo-amrwbenc"

fetch_tar "https://sourceforge.net/projects/opencore-amr/files/vo-amrwbenc/vo-amrwbenc-${VER}.tar.gz/download" "${SRC}"
cd "${SRC}"
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static
make -j"${JOBS}"
make install
ldconfig

verify_pc vo-amrwbenc
cleanup "${SRC}"
