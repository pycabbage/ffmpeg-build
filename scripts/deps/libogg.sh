#!/usr/bin/env bash
# libogg — Xiph Ogg bitstream container; shared dependency for libtheora, libvorbis, etc.
# FFmpeg does not --enable-libogg directly; consumed transitively by theora/vorbis builds.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.3.6"
SRC="${SRCROOT}/libogg"

fetch_tar "https://github.com/xiph/ogg/releases/download/v${VER}/libogg-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --enable-shared --disable-static
make -j"${JOBS}"
make install
ldconfig

verify_pc ogg
cleanup "${SRC}"
