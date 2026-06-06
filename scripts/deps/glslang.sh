#!/usr/bin/env bash
# glslang — Khronos GLSL/HLSL reference compiler + SPIR-V generator; provides glslang libs.
# Required by shaderc (--enable-libshaderc) and libplacebo. Must run after spirv-tools.
# NOTE: -DENABLE_OPT=1 links against the SPIRV-Tools optimizer — the spirv-tools.sh layer
#       must be present. By default glslang expects SPIRV-Tools bundled under External/ (via
#       update_glslang_sources.py); -DALLOW_EXTERNAL_SPIRV_TOOLS=ON makes it use our installed
#       SPIRV-Tools (cmake configs under /usr/local). -DBUILD_SHARED_LIBS=ON for this shared build.
# NOTE: moderately heavy cmake build; keep -DBUILD_TESTING=OFF to skip gtest infrastructure.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="16.3.0"
SRC="${SRCROOT}/glslang"

fetch_tar "https://github.com/KhronosGroup/glslang/archive/refs/tags/${VER}.tar.gz" "${SRC}"
cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DENABLE_OPT=1 \
  -DALLOW_EXTERNAL_SPIRV_TOOLS=ON \
  -DBUILD_TESTING=OFF \
  -DENABLE_GLSLANG_BINARIES=ON \
  -DGLSLANG_TESTS=OFF
cmake --build "${SRC}/build" -j"${JOBS}"
cmake --install "${SRC}/build"
ldconfig

# glslang doesn't ship a .pc; verify the main library is present.
test -f "${PREFIX}/lib/libglslang.so" || die "libglslang.so not found"
cleanup "${SRC}"
