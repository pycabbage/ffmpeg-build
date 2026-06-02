#!/usr/bin/env bash
# shaderc — Google GLSL/HLSL-to-SPIR-V compiler library; provides shaderc_combined + shaderc.pc.
# FFmpeg --enable-libshaderc (used by libplacebo Vulkan compute shaders).
# Must run after glslang + spirv-tools.
# NOTE: shaderc vendors its own copies of glslang and SPIRV-Tools by default. We override
#       this to use our already-built system copies (-DSHADERC_GLSLANG_DIR / _SPIRV_TOOLS_DIR)
#       so we don't pull in a second copy of those large trees.
# NOTE: -DSHADERC_SKIP_TESTS=ON is essential (avoids googletest + huge test suite compilation).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v2026.2"
SRC="${SRCROOT}/shaderc"

fetch_git "https://github.com/google/shaderc.git" "${VER}" "${SRC}"
cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DSHADERC_SKIP_TESTS=ON \
  -DSHADERC_SKIP_EXAMPLES=ON \
  -DSHADERC_SKIP_COPYRIGHT_CHECK=ON \
  -DSHADERC_ENABLE_SHARED_CRT=ON \
  -DSHADERC_GLSLANG_DIR="${PREFIX}" \
  -DSHADERC_SPIRV_TOOLS_DIR="${PREFIX}" \
  -Dglslang_DIR="${PREFIX}/lib/cmake/glslang" \
  -DSPIRV-Tools_DIR="${PREFIX}/lib/cmake/SPIRV-Tools"
cmake --build "${SRC}/build" -j"${JOBS}"
cmake --install "${SRC}/build"
ldconfig

verify_pc shaderc
cleanup "${SRC}"
