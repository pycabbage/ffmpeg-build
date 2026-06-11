#!/usr/bin/env bash
# libdc1394 — IEEE 1394 digital camera control library for FFmpeg --enable-libdc1394.
# Requires libusb-1.0 and libraw1394 (both built above).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2.2.7"
SRC="${SRCROOT}/libdc1394"

fetch_tar "https://sourceforge.net/projects/libdc1394/files/libdc1394-2/${VER}/libdc1394-${VER}.tar.gz/download" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --enable-shared --disable-static
make -j"${JOBS}"
make install
ldconfig

verify_pc libdc1394-2
cleanup "${SRC}"
