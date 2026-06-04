#!/usr/bin/env bash
# libusb — USB device access library; dependency of libdc1394.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.0.30"
SRC="${SRCROOT}/libusb"

fetch_tar "https://github.com/libusb/libusb/releases/download/v${VER}/libusb-${VER}.tar.bz2" "${SRC}"
cd "${SRC}"
# --disable-udev: libusb defaults to requiring libudev (systemd) for device enumeration/hotplug,
# and configure hard-errors "udev support requested but libudev header not installed". We do not
# build systemd/libudev; without udev libusb uses sysfs for enumeration, which is all libdc1394
# (and FFmpeg --enable-libdc1394) needs.
./configure --prefix="${PREFIX}" --enable-shared --disable-static --disable-udev
make -j"${JOBS}"
make install
ldconfig

verify_pc libusb-1.0
cleanup "${SRC}"
