#!/usr/bin/env bash
# libcaca — Colour ASCII Art library for FFmpeg --enable-libcaca (text video output).
# Latest stable is the beta series (0.99.beta20); that is the upstream-maintained release.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="0.99.beta20"
SRC="${SRCROOT}/libcaca"

fetch_tar "https://github.com/cacalabs/libcaca/releases/download/v${VER}/libcaca-${VER}.tar.bz2" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" \
            --enable-shared --disable-static \
            --disable-doc \
            --disable-java \
            --disable-csharp \
            --disable-ruby \
            --disable-python
make -j"${JOBS}"
make install
ldconfig

verify_pc caca
cleanup "${SRC}"
