#!/usr/bin/env bash
# SPIRV-Tools — Khronos SPIR-V assembler/disassembler/optimizer/validator; provides
# SPIRV-Tools shared libs and SPIRV-Tools.pc. Required by glslang and shaderc.
# NOTE: needs spirv-headers already installed at ${PREFIX} and python3 on PATH.
# NOTE: fairly heavy cmake build; -DSPIRV_SKIP_TESTS=ON is essential to avoid the very large
#       test infrastructure being compiled (googletest etc.).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v2026.2"
SRC="${SRCROOT}/spirv-tools"

fetch_git "https://github.com/KhronosGroup/SPIRV-Tools.git" "${VER}" "${SRC}"
cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DSPIRV_SKIP_TESTS=ON \
  -DSPIRV_SKIP_EXECUTABLES=OFF \
  -DSPIRV-Headers_SOURCE_DIR="${PREFIX}"
cmake --build "${SRC}/build" -j"${JOBS}"
cmake --install "${SRC}/build"
ldconfig

verify_pc SPIRV-Tools
cleanup "${SRC}"
