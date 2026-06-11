#!/usr/bin/env bash
# libexpat — XML parsing library; required by fontconfig at build and runtime.
# FFmpeg does not link expat directly; it is a transitive dep of fontconfig.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2.8.1"
SRC="${SRCROOT}/expat"

fetch_tar "https://github.com/libexpat/libexpat/releases/download/R_2_8_1/expat-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static \
  --without-docbook
make -j"${JOBS}"
make install
ldconfig

verify_pc expat
cleanup "${SRC}"
