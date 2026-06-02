#!/usr/bin/env bash
# libplacebo (VideoLAN) for FFmpeg --enable-libplacebo (the vf_libplacebo filter + ffplay
# vulkan renderer). Built from source so the API matches FFmpeg 8.1.1.
#
# MUST run AFTER vulkan-headers.sh: the vulkan backend needs the newer Vulkan-Headers in
# /usr/local and the shadowing vulkan.pc that vulkan-headers.sh installs.
#
# --recursive is REQUIRED: libplacebo vendors the `glad` GL/Vulkan loader as a git submodule;
# without it meson setup fails on the missing 3rdparty/glad source.
set -euxo pipefail

# v7.349.0 is the libplacebo release matching the FFmpeg 8.1.1 libplacebo API (PL_API_VER 7xx).
VER="v7.349.0"
SRC="/tmp/placebo"

git clone --recursive --depth 1 --branch "${VER}" \
  https://code.videolan.org/videolan/libplacebo.git "${SRC}"

meson setup "${SRC}/build" "${SRC}" \
  --buildtype release \
  --prefix=/usr/local \
  -Dvulkan=enabled \
  -Dshaderc=enabled \
  -Dlcms=enabled \
  -Dglslang=disabled \
  -Ddemos=false \
  -Dtests=false
ninja -C "${SRC}/build" install
ldconfig

# Verify the source-built libplacebo is discoverable (should be 7.x).
pkg-config --exists --print-errors libplacebo
pkg-config --modversion libplacebo

rm -rf "${SRC}"
