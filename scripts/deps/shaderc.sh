#!/usr/bin/env bash
# shaderc — Google GLSL/HLSL-to-SPIR-V compiler library; provides libshaderc_shared + shaderc.pc.
# FFmpeg --enable-libshaderc (used by libplacebo Vulkan compute shaders).
# shaderc REQUIRES its third_party deps (glslang, SPIRV-Tools, SPIRV-Headers) as SOURCE subdirs
# under third_party/: it add_subdirectory()s them and has NO find_package/system-install path,
# and it pins exact, mutually-consistent revisions. So populate third_party/ with the upstream
# git-sync-deps (version-matched) rather than pointing it at our separately-built copies
# (different versions -> API drift). With -DSHADERC_SKIP_TESTS=ON the test-only deps
# (abseil/re2/effcee/googletest) are cloned by git-sync-deps but never compiled. shaderc's
# bundled glslang/SPIRV-Tools also install into /usr/local, harmlessly refreshing the earlier
# glslang.sh/spirv-tools.sh copies with shaderc's matched revisions.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v2026.2"
SRC="${SRCROOT}/shaderc"

fetch_git "https://github.com/google/shaderc.git" "${VER}" "${SRC}"
cd "${SRC}"
# Populate third_party/{glslang,spirv-tools,spirv-headers,...} at shaderc's pinned revisions.
python3 ./utils/git-sync-deps
cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DSHADERC_SKIP_TESTS=ON \
  -DSHADERC_SKIP_EXAMPLES=ON \
  -DSHADERC_SKIP_COPYRIGHT_CHECK=ON \
  -DSHADERC_ENABLE_SHARED_CRT=ON
cmake --build "${SRC}/build" -j"${JOBS}"
cmake --install "${SRC}/build"
ldconfig

verify_pc shaderc
cleanup "${SRC}"
