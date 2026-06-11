#!/usr/bin/env bash
# libbluray (VideoLAN) for FFmpeg --enable-libbluray (Blu-ray demuxer). Needs freetype +
# fontconfig (for BD-J/menu font handling); libxml2 optional. We disable the optional BD-J
# Java jar (avoids needing a JDK/ant). Release tarball ships ./configure.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.3.4"
SRC="${SRCROOT}/libbluray"

fetch_tar "https://download.videolan.org/pub/videolan/libbluray/${VER}/libbluray-${VER}.tar.bz2" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --disable-static --enable-shared --disable-bdjava-jar
make -j"${JOBS}"
make install
ldconfig

verify_pc libbluray
cleanup "${SRC}"
