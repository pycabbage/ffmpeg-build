#!/usr/bin/env bash
# uavs3d: AVS3 decoder for FFmpeg --enable-libuavs3d.
# FRAGILE: the project pins cmake_minimum_required(VERSION 2.8), which CMake >= 3.27
# (Ubuntu 24.04 ships 3.28) hard-errors on. Pass -DCMAKE_POLICY_VERSION_MINIMUM=3.5.
set -euxo pipefail

VER="v1.1"
SRC="/tmp/uavs3d"

git clone --depth 1 --branch "${VER}" \
  https://github.com/uavs3/uavs3d.git "${SRC}"

cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr/local \
  -DBUILD_SHARED_LIBS=ON \
  -DCOMPILE_10BIT=0 \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build "${SRC}/build" --parallel "$(nproc)"
cmake --install "${SRC}/build"
ldconfig

pkg-config --exists --print-errors uavs3d

rm -rf "${SRC}"
