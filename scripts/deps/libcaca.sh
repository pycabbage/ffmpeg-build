#!/usr/bin/env bash
# libcaca — Colour ASCII Art library for FFmpeg --enable-libcaca (text video output).
# Latest stable is the beta series (0.99.beta20); that is the upstream-maintained release.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="0.99.beta20"
SRC="${SRCROOT}/libcaca"

fetch_tar "https://github.com/cacalabs/libcaca/releases/download/v${VER}/libcaca-${VER}.tar.bz2" "${SRC}"
cd "${SRC}"
# gcc-14 promotes -Wint-conversion (and friends) to errors; libcaca's src/ tools (cacaview's
# common-image.c) call the internal _caca_alloc2d via a stale nested-extern decl returning int,
# tripping "pointer from integer". The caca/ LIBRARY itself compiles clean (it builds before
# src/ in SUBDIRS) — only the bundled tools trip this — so demote those diagnostics for the whole
# build via CFLAGS. FFmpeg --enable-libcaca links only libcaca.so + caca.pc; the tools are unused.
./configure --prefix="${PREFIX}" \
            --enable-shared --disable-static \
            --disable-doc \
            --disable-java \
            --disable-csharp \
            --disable-ruby \
            --disable-python \
            CFLAGS="${CFLAGS:-} -O2 -Wno-int-conversion -Wno-implicit-function-declaration -Wno-implicit-int -Wno-incompatible-pointer-types"
make -j"${JOBS}"
make install
ldconfig

verify_pc caca
cleanup "${SRC}"
