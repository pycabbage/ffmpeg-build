#!/usr/bin/env bash
# libjxl — JPEG XL codec; FFmpeg --enable-libjxl (pkg-config: libjxl). cmake build.
# Clone --recursive: libjxl vendors brotli/highway/skcms/sjpeg as submodules (we don't build those
# separately) and builds them statically into libjxl. Disable tools/benchmark/examples/etc — we
# only need the shared library + libjxl.pc / libjxl_threads.pc.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="0.11.2"
SRC="${SRCROOT}/libjxl"

fetch_git "https://github.com/libjxl/libjxl" "v${VER}" "${SRC}" --recursive
mkdir -p "${SRC}/build"
cd "${SRC}/build"
# Use OUR gcc-14 for both C and C++ (cmake would otherwise take the seed gcc-13 as `cc` for C),
# keeping the vendored brotli (C) and libjxl (C++) objects on one toolchain.
export CC=gcc CXX=g++
cmake .. \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DBUILD_TESTING=OFF \
  -DJPEGXL_ENABLE_TOOLS=OFF \
  -DJPEGXL_ENABLE_BENCHMARK=OFF \
  -DJPEGXL_ENABLE_EXAMPLES=OFF \
  -DJPEGXL_ENABLE_MANPAGES=OFF \
  -DJPEGXL_ENABLE_DOXYGEN=OFF \
  -DJPEGXL_ENABLE_JNI=OFF \
  -DJPEGXL_ENABLE_PLUGINS=OFF \
  -DJPEGXL_ENABLE_SKCMS=ON
make -j"${JOBS}"
make install
ldconfig

verify_pc libjxl libjxl_threads
cleanup "${SRC}"
