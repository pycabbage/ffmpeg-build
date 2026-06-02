#!/usr/bin/env bash
# libopenmpt — OpenMPT-based tracker music decoder for FFmpeg --enable-libopenmpt.
# Use the official autotools release tarball; disable optional heavy deps (mpg123, ogg,
# vorbis, portaudio, sndfile, flac) to keep the build lean and dependency-free.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="0.8.7"
SRC="${SRCROOT}/libopenmpt"

fetch_tar "https://lib.openmpt.org/files/libopenmpt/src/libopenmpt-${VER}+release.autotools.tar.gz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" \
            --enable-shared --disable-static \
            --without-mpg123 \
            --without-ogg \
            --without-vorbis \
            --without-vorbisfile \
            --without-portaudio \
            --without-portaudiocpp \
            --without-sndfile \
            --without-flac
make -j"${JOBS}"
make install
ldconfig

verify_pc libopenmpt
cleanup "${SRC}"
