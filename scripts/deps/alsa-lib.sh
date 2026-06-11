#!/usr/bin/env bash
# alsa-lib (libasound) — ALSA user-space library; provides alsa.pc.
# Used as audio backend by SDL2 and openal-soft.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.2.16"
SRC="${SRCROOT}/alsa-lib"

fetch_tar "https://www.alsa-project.org/files/pub/lib/alsa-lib-${VER}.tar.bz2" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --disable-static --enable-shared \
  --without-debug --disable-python
make -j"${JOBS}"
make install
ldconfig

verify_pc alsa
cleanup "${SRC}"
