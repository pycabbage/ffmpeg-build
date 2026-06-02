#!/usr/bin/env bash
# libxml2 — XML parsing library for FFmpeg --enable-libxml2 (HLS manifest parsing etc.).
# Build with autotools; --without-python to avoid python3 binding churn.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2.15.3"
SRC="${SRCROOT}/libxml2"

fetch_tar "https://download.gnome.org/sources/libxml2/2.15/libxml2-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" \
            --enable-shared --disable-static \
            --without-python \
            --with-zlib="${PREFIX}" \
            --with-lzma="${PREFIX}"
make -j"${JOBS}"
make install
ldconfig

verify_pc libxml-2.0
cleanup "${SRC}"
