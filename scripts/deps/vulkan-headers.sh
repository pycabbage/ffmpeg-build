#!/usr/bin/env bash
# Vulkan-Headers (header-only) for FFmpeg --enable-vulkan and the libplacebo vulkan backend.
# In the full-build there is no apt libvulkan, so the matching loader is built separately by
# vulkan-loader.sh (which also installs vulkan.pc). Here we install ONLY the Khronos headers;
# vulkan-loader.sh MUST run after this. FFmpeg 8.1.1 needs VK_HEADER_VERSION >= 277.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v1.4.323"
SRC="${SRCROOT}/vulkan-headers"

fetch_git "https://github.com/KhronosGroup/Vulkan-Headers.git" "${VER}" "${SRC}"
cmake -S "${SRC}" -B "${SRC}/build" -DCMAKE_INSTALL_PREFIX="${PREFIX}"
cmake --install "${SRC}/build"

# Sanity: ASSERT the installed header is >= 277 (the FFmpeg 8.1.1 floor), not just print it.
VKHV="$(awk '/^#define VK_HEADER_VERSION / {print $3}' "${PREFIX}/include/vulkan/vulkan_core.h")"
echo "VK_HEADER_VERSION = ${VKHV}"
{ [ -n "${VKHV}" ] && [ "${VKHV}" -ge 277 ]; } \
  || die "Vulkan headers too old: VK_HEADER_VERSION=${VKHV:-?} (< 277 required by FFmpeg 8.1.1)"

cleanup "${SRC}"
