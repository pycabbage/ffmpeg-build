#!/usr/bin/env bash
# libsrt — Secure Reliable Transport library. FFmpeg --enable-libsrt.
# Built with GnuTLS backend (matches project TLS choice). Provides srt.pc.
# Must run after gnutls.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.5.5"
SRC="${SRCROOT}/srt"

fetch_tar "https://github.com/Haivision/srt/archive/refs/tags/v${VER}.tar.gz" "${SRC}"
cd "${SRC}"
cmake -S . -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DENABLE_SHARED=ON \
  -DENABLE_STATIC=OFF \
  -DUSE_ENCLIB=gnutls \
  -DENABLE_APPS=OFF \
  -DENABLE_TESTING=OFF \
  -DENABLE_DOCS=OFF
cmake --build build --parallel "${JOBS}"
cmake --install build
ldconfig

verify_pc srt
cleanup "${SRC}"
