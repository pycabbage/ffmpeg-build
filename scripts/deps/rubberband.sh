#!/usr/bin/env bash
# Rubber Band Library — audio time-stretching and pitch-shifting; FFmpeg --enable-librubberband.
# Built with builtin FFT and resampler to avoid fftw3/libsamplerate deps; cmdline and tests off.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v4.0.0"
SRC="${SRCROOT}/rubberband"

fetch_git "https://github.com/breakfastquay/rubberband.git" "${VER}" "${SRC}"

meson setup "${SRC}/build" "${SRC}" \
  --buildtype release \
  --prefix="${PREFIX}" \
  --default-library shared \
  -Dfft=builtin \
  -Dresampler=builtin \
  -Dcmdline=disabled \
  -Dtests=disabled
ninja -C "${SRC}/build" install
ldconfig

verify_pc rubberband
cleanup "${SRC}"
