#!/usr/bin/env bash
# libaribb24 — ARIB STD-B24 (Japanese broadcast captions) decoder; FFmpeg --enable-libaribb24.
# Upstream uses autotools but the configure script must be generated with autoreconf -fiv.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v1.0.3"
SRC="${SRCROOT}/aribb24"

fetch_git "https://github.com/nkoriyama/aribb24.git" "${VER}" "${SRC}"
cd "${SRC}"
autoreconf -fiv
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static
make -j"${JOBS}"
make install
ldconfig

verify_pc aribb24
cleanup "${SRC}"
