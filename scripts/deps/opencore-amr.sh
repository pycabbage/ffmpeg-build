#!/usr/bin/env bash
# opencore-amr — OpenCORE AMR-NB/WB decoder; serves FFmpeg --enable-libopencore-amrnb/amrwb.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="0.1.6"
SRC="${SRCROOT}/opencore-amr"

fetch_tar "https://sourceforge.net/projects/opencore-amr/files/opencore-amr/opencore-amr-${VER}.tar.gz/download" "${SRC}"
cd "${SRC}"
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static
make -j"${JOBS}"
make install
ldconfig

verify_pc opencore-amrnb opencore-amrwb
cleanup "${SRC}"
