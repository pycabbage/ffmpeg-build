#!/usr/bin/env bash
# libcaca — Colour ASCII Art library for FFmpeg --enable-libcaca (text video output).
# Latest stable is the beta series (0.99.beta20); that is the upstream-maintained release.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="0.99.beta20"
SRC="${SRCROOT}/libcaca"

fetch_tar "https://github.com/cacalabs/libcaca/releases/download/v${VER}/libcaca-${VER}.tar.bz2" "${SRC}"
cd "${SRC}"
# Build/install ONLY the caca/ library subdir. libcaca's src/ CLI tools (cacaview, img2txt) call
# the library-internal symbol _caca_alloc2d, which is NOT exported from the shared libcaca, so
# linking the tools fails with "undefined reference to _caca_alloc2d" (a gcc-14 -Wint-conversion
# warning earlier masked that the decl was bogus). FFmpeg --enable-libcaca needs only the libcaca
# library, its headers and caca.pc — all produced by caca/ — so we configure the whole project
# (to generate caca/caca.pc, config.h, caca_types.h) but `make -C caca` to skip src/examples/tools.
./configure --prefix="${PREFIX}" \
            --enable-shared --disable-static \
            --disable-doc \
            --disable-java \
            --disable-csharp \
            --disable-ruby \
            --disable-python
make -C caca -j"${JOBS}"
make -C caca install
ldconfig

verify_pc caca
cleanup "${SRC}"
