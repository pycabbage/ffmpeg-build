#!/usr/bin/env bash
# libiec61883 — IEC 61883 streaming over FireWire (DV / HDV / MPEG2-TS capture); FFmpeg
# --enable-libiec61883 (check_lib: libiec61883/iec61883.h + -lraw1394 -lavc1394 -lrom1394
# -liec61883). Needs libraw1394 (built) + libavc1394/librom1394 (built). kernel.org tarball ships
# ./configure.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.2.0"
SRC="${SRCROOT}/libiec61883"

fetch_tar "https://www.kernel.org/pub/linux/libs/ieee1394/libiec61883-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --enable-shared --disable-static
make -j"${JOBS}"
make install
ldconfig

test -f "${PREFIX}/lib/libiec61883.so" && test -f "${PREFIX}/include/libiec61883/iec61883.h" \
  || die "libiec61883 not installed"
cleanup "${SRC}"
