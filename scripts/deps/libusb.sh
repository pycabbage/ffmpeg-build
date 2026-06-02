#!/usr/bin/env bash
# libusb — USB device access library; dependency of libdc1394.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.0.30"
SRC="${SRCROOT}/libusb"

fetch_tar "https://github.com/libusb/libusb/releases/download/v${VER}/libusb-${VER}.tar.bz2" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --enable-shared --disable-static
make -j"${JOBS}"
make install
ldconfig

verify_pc libusb-1.0
cleanup "${SRC}"
