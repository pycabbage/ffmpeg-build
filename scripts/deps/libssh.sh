#!/usr/bin/env bash
# libssh — SSH client library. FFmpeg --enable-libssh (sftp:// / ssh:// protocol support).
# Uses OpenSSL as crypto backend (already built). Provides libssh.pc.
# -DWITH_SERVER=OFF avoids building the server-side code (not needed for FFmpeg).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="0.12.0"
SRC="${SRCROOT}/libssh"

fetch_tar "https://www.libssh.org/files/0.12/libssh-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
cmake -S . -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DBUILD_SHARED_LIBS=ON \
  -DWITH_SERVER=OFF \
  -DWITH_EXAMPLES=OFF \
  -DWITH_TESTING=OFF \
  -DWITH_BENCHMARKS=OFF \
  -DWITH_GCRYPT=OFF \
  -DWITH_MBEDTLS=OFF
cmake --build build --parallel "${JOBS}"
cmake --install build
ldconfig

verify_pc libssh
cleanup "${SRC}"
