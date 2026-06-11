#!/usr/bin/env bash
# SPIRV-Headers — Khronos SPIR-V header definitions; header-only cmake install.
# Required by spirv-tools and glslang. No shared lib.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="vulkan-sdk-1.4.350.0"
SRC="${SRCROOT}/spirv-headers"

fetch_git "https://github.com/KhronosGroup/SPIRV-Headers.git" "${VER}" "${SRC}"
cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DSPIRV_HEADERS_SKIP_EXAMPLES=ON \
  -DSPIRV_HEADERS_SKIP_TESTS=ON
cmake --install "${SRC}/build"
ldconfig

# No .pc; verify the canonical header is present.
test -f "${PREFIX}/include/spirv/unified1/spirv.h" || die "spirv.h not found"
cleanup "${SRC}"
