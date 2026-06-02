#!/usr/bin/env bash
# CMU Flite — lightweight text-to-speech engine; FFmpeg --enable-libflite.
# Quirky build: the top-level build produces only static libs by default.
# We pass --enable-shared explicitly; install produces libflite*.so files.
# Sanity: test -f since flite ships no .pc file.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v2.2"
SRC="${SRCROOT}/flite"

fetch_git "https://github.com/festvox/flite.git" "${VER}" "${SRC}"
cd "${SRC}"
./configure \
  --prefix="${PREFIX}" \
  --enable-shared
make -j"${JOBS}"
make install
ldconfig

test -f "${PREFIX}/lib/libflite.so"
log "libflite.so installed"
cleanup "${SRC}"
