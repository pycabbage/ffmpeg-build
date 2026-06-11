#!/usr/bin/env bash
# liblc3 — LC3 codec (Bluetooth LE Audio, Low Complexity Communication Codec); FFmpeg
# --enable-liblc3 (pkg-config: lc3). meson build.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.1.3"
SRC="${SRCROOT}/liblc3"

fetch_git "https://github.com/google/liblc3" "v${VER}" "${SRC}"
cd "${SRC}"
meson setup build \
  --prefix="${PREFIX}" \
  --buildtype=release \
  --default-library=shared
ninja -C build -j"${JOBS}"
ninja -C build install
ldconfig

verify_pc lc3
cleanup "${SRC}"
