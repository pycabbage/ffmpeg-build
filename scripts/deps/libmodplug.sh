#!/usr/bin/env bash
# libmodplug — MOD/S3M/XM/IT tracker music decoder for FFmpeg --enable-libmodplug.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="0.8.9.0"
SRC="${SRCROOT}/libmodplug"

fetch_tar "https://sourceforge.net/projects/modplug-xmms/files/libmodplug/${VER}/libmodplug-${VER}.tar.gz/download" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --enable-shared --disable-static
make -j"${JOBS}"
make install
ldconfig

verify_pc libmodplug
cleanup "${SRC}"
