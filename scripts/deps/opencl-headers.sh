#!/usr/bin/env bash
# OpenCL-Headers — Khronos OpenCL API headers; header-only install into ${PREFIX}/include/CL.
# Required by ocl-icd and FFmpeg --enable-opencl. No shared library built (headers only).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v2026.05.29"
SRC="${SRCROOT}/opencl-headers"

fetch_git "https://github.com/KhronosGroup/OpenCL-Headers.git" "${VER}" "${SRC}"
cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DOPENCL_HEADERS_BUILD_TESTING=OFF
cmake --install "${SRC}/build"
ldconfig

# No .pc; verify the canonical header is present.
test -f "${PREFIX}/include/CL/cl.h" || die "CL/cl.h not found"
cleanup "${SRC}"
