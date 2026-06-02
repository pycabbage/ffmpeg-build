#!/usr/bin/env bash
# openjpeg — JPEG 2000 codec; FFmpeg --enable-libopenjpeg. Provides libopenjp2.pc.
# cmake build; GitHub archive tarball.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2.5.4"
SRC="${SRCROOT}/openjpeg"

fetch_tar "https://github.com/uclouvain/openjpeg/archive/refs/tags/v${VER}.tar.gz" "${SRC}"
mkdir -p "${SRC}/build"
cd "${SRC}/build"
cmake .. \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DBUILD_STATIC_LIBS=OFF \
  -DBUILD_CODEC=OFF \
  -DBUILD_DOC=OFF \
  -DBUILD_TESTING=OFF
make -j"${JOBS}"
make install
ldconfig

verify_pc libopenjp2
cleanup "${SRC}"
