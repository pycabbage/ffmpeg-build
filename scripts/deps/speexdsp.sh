#!/usr/bin/env bash
# speexdsp — Xiph SpeexDSP audio processing library (separate repo from speex).
# Provides AEC and resampler; serves FFmpeg --enable-libspeexdsp (speex_aec filter).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.2.1"
SRC="${SRCROOT}/speexdsp"

fetch_tar "https://downloads.xiph.org/releases/speex/speexdsp-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static
make -j"${JOBS}"
make install
ldconfig

verify_pc speexdsp
cleanup "${SRC}"
