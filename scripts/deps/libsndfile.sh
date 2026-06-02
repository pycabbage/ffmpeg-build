#!/usr/bin/env bash
# libsndfile — sound-file I/O. Not used by FFmpeg directly; it is the hard dependency that
# pulseaudio (--enable-libpulse) needs. Picks up FLAC/Ogg/Vorbis/Opus (all built earlier) for
# the compressed formats. cmake build.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.2.2"
SRC="${SRCROOT}/libsndfile"

fetch_tar "https://github.com/libsndfile/libsndfile/releases/download/${VER}/libsndfile-${VER}.tar.xz" "${SRC}"
cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=OFF -DBUILD_PROGRAMS=OFF -DBUILD_EXAMPLES=OFF
cmake --build "${SRC}/build" -j"${JOBS}"
cmake --install "${SRC}/build"
ldconfig

verify_pc sndfile
cleanup "${SRC}"
