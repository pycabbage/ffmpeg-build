#!/usr/bin/env bash
# libxcb — X protocol C-language Binding; provides xcb.pc + xcb-shm.pc + xcb-xfixes.pc
# + xcb-shape.pc required by FFmpeg --enable-libxcb --enable-libxcb-shm
# --enable-libxcb-xfixes --enable-libxcb-shape.
# Must run after xcb-proto, libXau, libXdmcp, libpthread-stubs.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.17.0"
SRC="${SRCROOT}/libxcb"

fetch_tar "https://xcb.freedesktop.org/dist/libxcb-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --disable-static --enable-shared \
  --without-doxygen
make -j"${JOBS}"
make install
ldconfig

verify_pc xcb xcb-shm xcb-xfixes xcb-shape
cleanup "${SRC}"
