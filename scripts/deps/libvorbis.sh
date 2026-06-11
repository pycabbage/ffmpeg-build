#!/usr/bin/env bash
# libvorbis — Xiph Ogg Vorbis audio codec; serves FFmpeg --enable-libvorbis.
# Requires libogg (built by another cluster, available in ${PREFIX}).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.3.7"
SRC="${SRCROOT}/libvorbis"

fetch_tar "https://downloads.xiph.org/releases/vorbis/libvorbis-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static \
  --with-ogg="${PREFIX}"
make -j"${JOBS}"
make install
ldconfig

verify_pc vorbis vorbisenc vorbisfile
cleanup "${SRC}"
