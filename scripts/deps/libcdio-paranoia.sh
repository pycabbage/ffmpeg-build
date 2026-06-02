#!/usr/bin/env bash
# libcdio-paranoia — CD audio ripping with error correction; depends on libcdio (built above).
# FFmpeg uses libcdio_paranoia.pc (--enable-libcdio pulls cdparanoia via libcdio-paranoia).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="10.2+2.0.2"
SRC="${SRCROOT}/libcdio-paranoia"

fetch_tar "https://ftp.gnu.org/gnu/libcdio/libcdio-paranoia-${VER}.tar.bz2" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --enable-shared --disable-static
make -j"${JOBS}"
make install
ldconfig

verify_pc libcdio_paranoia
cleanup "${SRC}"
