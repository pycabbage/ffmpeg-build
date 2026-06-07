#!/usr/bin/env bash
# libcelt — legacy CELT audio decoder (pre-Opus); FFmpeg --enable-libcelt (check_lib: celt/celt.h
# + celt_decode in -lcelt0). Xiph release tarball ships ./configure.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="0.11.3"
SRC="${SRCROOT}/celt"

fetch_tar "https://downloads.xiph.org/releases/celt/celt-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --enable-shared --disable-static
make -j"${JOBS}"
make install
ldconfig

verify_pc celt
cleanup "${SRC}"
