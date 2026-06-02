#!/usr/bin/env bash
# libbs2b — Bauer stereophonic-to-binaural DSP library; FFmpeg --enable-libbs2b.
# Autotools build from SourceForge tarball; produces libbs2b.pc.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="3.1.0"
SRC="${SRCROOT}/libbs2b"

fetch_tar "https://downloads.sourceforge.net/bs2b/libbs2b-${VER}.tar.bz2" "${SRC}"
cd "${SRC}"
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static
make -j"${JOBS}"
make install
ldconfig

verify_pc libbs2b
cleanup "${SRC}"
