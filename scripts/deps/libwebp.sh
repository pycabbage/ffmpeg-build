#!/usr/bin/env bash
# libwebp — Google WebP image codec; FFmpeg --enable-libwebp.
# cmake build; provides libwebp, libwebpmux, libwebpdemux, libsharpyuv.
# Source tarball from chromium.googlesource.com auto-generated archive endpoint.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.6.0"
SRC="${SRCROOT}/libwebp"

fetch_tar "https://chromium.googlesource.com/webm/libwebp/+archive/refs/tags/v${VER}.tar.gz" "${SRC}"
mkdir -p "${SRC}/build"
cd "${SRC}/build"
cmake .. \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DWEBP_BUILD_ANIM_UTILS=OFF \
  -DWEBP_BUILD_CWEBP=OFF \
  -DWEBP_BUILD_DWEBP=OFF \
  -DWEBP_BUILD_GIF2WEBP=OFF \
  -DWEBP_BUILD_IMG2WEBP=OFF \
  -DWEBP_BUILD_VWEBP=OFF \
  -DWEBP_BUILD_WEBPINFO=OFF \
  -DWEBP_BUILD_WEBPMUX=OFF \
  -DWEBP_BUILD_EXTRAS=OFF
make -j"${JOBS}"
make install
ldconfig

verify_pc libwebp libwebpmux libwebpdemux
cleanup "${SRC}"
