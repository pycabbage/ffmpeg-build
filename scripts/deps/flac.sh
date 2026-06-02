#!/usr/bin/env bash
# FLAC (libFLAC) — not used by FFmpeg directly (FFmpeg has a native FLAC codec) but a hard
# dependency of libsndfile, which in turn is a hard dependency of pulseaudio (--enable-libpulse).
# Needs libogg. cmake build.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.5.0"
SRC="${SRCROOT}/flac"

fetch_tar "https://github.com/xiph/flac/releases/download/${VER}/flac-${VER}.tar.xz" "${SRC}"
cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=OFF -DBUILD_EXAMPLES=OFF -DBUILD_PROGRAMS=OFF -DWITH_OGG=ON
cmake --build "${SRC}/build" -j"${JOBS}"
cmake --install "${SRC}/build"
ldconfig

verify_pc flac
cleanup "${SRC}"
