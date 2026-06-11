#!/usr/bin/env bash
# fdk-aac — Fraunhofer FDK AAC codec; serves FFmpeg --enable-libfdk-aac (nonfree).
# Uses autotools; requires autoreconf because upstream ships no configure in the tarball.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2.0.3"
SRC="${SRCROOT}/fdk-aac"

fetch_tar "https://github.com/mstorsjo/fdk-aac/archive/refs/tags/v${VER}.tar.gz" "${SRC}"
cd "${SRC}"
autoreconf -fiv
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static
make -j"${JOBS}"
make install
ldconfig

verify_pc fdk-aac
cleanup "${SRC}"
