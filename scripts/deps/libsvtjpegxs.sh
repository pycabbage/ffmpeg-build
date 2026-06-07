#!/usr/bin/env bash
# SVT-JPEG-XS — Scalable Video Technology for JPEG XS (encoder + decoder); FFmpeg
# --enable-libsvtjpegxs (pkg-config: SvtJpegxs). cmake build at repo root; apps off (lib only).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="0.9.0"
SRC="${SRCROOT}/svt-jpegxs"

fetch_git "https://github.com/OpenVisualCloud/SVT-JPEG-XS" "v${VER}" "${SRC}"
mkdir -p "${SRC}/build"
cd "${SRC}/build"
cmake .. \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DBUILD_APPS=OFF
make -j"${JOBS}"
make install
ldconfig

verify_pc SvtJpegxs
cleanup "${SRC}"
