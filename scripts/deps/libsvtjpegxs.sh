#!/usr/bin/env bash
# SVT-JPEG-XS — Scalable Video Technology for JPEG XS (encoder + decoder); FFmpeg
# --enable-libsvtjpegxs (pkg-config: SvtJpegxs). cmake build at repo root; apps off (lib only).
#
# FFmpeg 8.1.1 requires SvtJpegxs >= 0.10.0, but upstream's only release tag is v0.9.0 (< required);
# 0.10.0 currently lives only on main. Pin a specific main commit and fetch it by SHA (shallow) so
# the build stays reproducible despite there being no 0.10.0 tag yet.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

COMMIT="8e50180ad909a0bdcdf91b462c64033f0fe3e112"   # main @ project VERSION 0.10.0
SRC="${SRCROOT}/svt-jpegxs"

rm -rf "${SRC}"; mkdir -p "${SRC}"; cd "${SRC}"
git init -q
git fetch --depth 1 https://github.com/OpenVisualCloud/SVT-JPEG-XS "${COMMIT}"
git checkout -q FETCH_HEAD

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
