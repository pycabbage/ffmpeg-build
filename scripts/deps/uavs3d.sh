#!/usr/bin/env bash
# uavs3d: AVS3 decoder for FFmpeg --enable-libuavs3d.
# FRAGILE: the project pins cmake_minimum_required(VERSION 2.8), which CMake >= 3.27
# (Ubuntu 24.04 ships 3.28) hard-errors on. Pass -DCMAKE_POLICY_VERSION_MINIMUM=3.5.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v1.1"
SRC="${SRCROOT}/uavs3d"

fetch_git https://github.com/uavs3/uavs3d.git "${VER}" "${SRC}"

cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DBUILD_SHARED_LIBS=ON \
  -DCOMPILE_10BIT=0 \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build "${SRC}/build" --parallel "${JOBS}"
cmake --install "${SRC}/build"
ldconfig

verify_pc uavs3d
cleanup "${SRC}"
