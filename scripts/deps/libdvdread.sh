#!/usr/bin/env bash
# libdvdread — DVD title/IFO/block reading; FFmpeg --enable-libdvdread (pkg-config: dvdread).
# autotools; the VideoLAN release tarball ships ./configure (no autogen needed).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="6.1.3"
SRC="${SRCROOT}/libdvdread"

fetch_tar "https://download.videolan.org/pub/videolan/libdvdread/${VER}/libdvdread-${VER}.tar.bz2" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --enable-shared --disable-static
make -j"${JOBS}"
make install
ldconfig

verify_pc dvdread
cleanup "${SRC}"
