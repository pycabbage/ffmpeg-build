#!/usr/bin/env bash
# openh264 — Cisco OpenH264 H.264 encoder/decoder; FFmpeg --enable-libopenh264.
# meson build preferred over the GNU Makefile; provides openh264.pc.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2.6.0"
SRC="${SRCROOT}/openh264"

fetch_tar "https://github.com/cisco/openh264/archive/v${VER}/openh264-${VER}.tar.gz" "${SRC}"
mkdir -p "${SRC}/build"
cd "${SRC}"
meson setup build \
  --prefix="${PREFIX}" \
  --buildtype=release \
  --default-library=shared
ninja -C build -j"${JOBS}"
ninja -C build install
ldconfig

verify_pc openh264
cleanup "${SRC}"
