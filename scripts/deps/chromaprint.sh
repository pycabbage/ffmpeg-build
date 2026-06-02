#!/usr/bin/env bash
# chromaprint — AcoustID audio fingerprinting for FFmpeg --enable-chromaprint.
# Requires fftw (built above); use fftw3 backend via -DFFT_LIB=fftw3.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.6.0"
SRC="${SRCROOT}/chromaprint"

fetch_tar "https://github.com/acoustid/chromaprint/archive/refs/tags/v${VER}.tar.gz" "${SRC}"
cd "${SRC}"
cmake -S . -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DFFT_LIB=fftw3 \
      -DBUILD_SHARED_LIBS=ON
cmake --build build -j"${JOBS}"
cmake --install build
ldconfig

verify_pc libchromaprint
cleanup "${SRC}"
