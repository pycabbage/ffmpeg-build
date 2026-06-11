#!/usr/bin/env bash
# libjpeg-turbo — SIMD-accelerated JPEG library; provides libjpeg + libturbojpeg.
# cmake build; -DENABLE_SHARED=ON installs both .so and the turbojpeg .so.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="3.1.4.1"
SRC="${SRCROOT}/libjpeg-turbo"

fetch_tar "https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/${VER}/libjpeg-turbo-${VER}.tar.gz" "${SRC}"
mkdir -p "${SRC}/build"
cd "${SRC}/build"
cmake .. \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_SHARED=ON \
  -DENABLE_STATIC=OFF
make -j"${JOBS}"
make install
ldconfig

verify_pc libjpeg libturbojpeg
cleanup "${SRC}"
