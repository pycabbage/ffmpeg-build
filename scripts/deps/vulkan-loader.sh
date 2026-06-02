#!/usr/bin/env bash
# Vulkan-Loader — the libvulkan.so loader for FFmpeg --enable-vulkan / libplacebo. In the apt
# build this came from libvulkan-dev; the full-build compiles it from source. Installs
# libvulkan.so.1 AND vulkan.pc (reporting the loader version >= 1.4, satisfying FFmpeg 8.1.1's
# `vulkan >= 1.3.277`). MUST run AFTER vulkan-headers.sh and libxcb. The actual GPU ICD/driver
# is provided by the host at runtime (not bundled).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v1.4.323"
SRC="${SRCROOT}/vulkan-loader"

fetch_git "https://github.com/KhronosGroup/Vulkan-Loader.git" "${VER}" "${SRC}"
cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DVULKAN_HEADERS_INSTALL_DIR="${PREFIX}" \
  -DBUILD_TESTS=OFF \
  -DBUILD_WSI_XCB_SUPPORT=ON \
  -DBUILD_WSI_XLIB_SUPPORT=OFF \
  -DBUILD_WSI_WAYLAND_SUPPORT=OFF
cmake --build "${SRC}/build" -j"${JOBS}"
cmake --install "${SRC}/build"
ldconfig

verify_pc vulkan
cleanup "${SRC}"
