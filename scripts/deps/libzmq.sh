#!/usr/bin/env bash
# libzmq — ZeroMQ messaging library. FFmpeg --enable-libzmq (zmq filter).
# CMake build; shared only. Provides libzmq.pc.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="4.3.5"
SRC="${SRCROOT}/libzmq"

fetch_tar "https://github.com/zeromq/libzmq/releases/download/v${VER}/zeromq-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
cmake -S . -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DBUILD_SHARED=ON \
  -DBUILD_STATIC=OFF \
  -DWITH_PERF_TOOL=OFF \
  -DZMQ_BUILD_TESTS=OFF \
  -DENABLE_CPACK=OFF
cmake --build build --parallel "${JOBS}"
cmake --install build
ldconfig

verify_pc libzmq
cleanup "${SRC}"
