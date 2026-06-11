#!/usr/bin/env bash
# libdvdnav — DVD navigation (menus/state) on top of libdvdread; FFmpeg --enable-libdvdnav
# (pkg-config: dvdnav). MUST build after libdvdread (its configure needs dvdread.pc). autotools;
# the VideoLAN release tarball ships ./configure.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="6.1.1"
SRC="${SRCROOT}/libdvdnav"

fetch_tar "https://download.videolan.org/pub/videolan/libdvdnav/${VER}/libdvdnav-${VER}.tar.bz2" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --enable-shared --disable-static
make -j"${JOBS}"
make install
ldconfig

verify_pc dvdnav
cleanup "${SRC}"
