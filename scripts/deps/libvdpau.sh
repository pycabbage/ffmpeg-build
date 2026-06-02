#!/usr/bin/env bash
# libvdpau — Video Decode and Presentation API for Unix (NVIDIA); provides vdpau.pc.
# FFmpeg --enable-vdpau. The loader only; actual driver is host-provided at runtime.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.5"
SRC="${SRCROOT}/libvdpau"

fetch_git "https://gitlab.freedesktop.org/vdpau/libvdpau.git" "${VER}" "${SRC}"
meson setup "${SRC}/build" "${SRC}" \
  --prefix="${PREFIX}" \
  --buildtype=release \
  --default-library=shared \
  -Ddocumentation=false
ninja -C "${SRC}/build" -j"${JOBS}"
ninja -C "${SRC}/build" install
ldconfig

verify_pc vdpau
cleanup "${SRC}"
