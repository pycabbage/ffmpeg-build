#!/usr/bin/env bash
# dav1d — fast AV1 decoder; FFmpeg --enable-libdav1d.
# meson build; tarball from official VideoLAN download server.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.5.3"
SRC="${SRCROOT}/dav1d"

fetch_tar "https://downloads.videolan.org/pub/videolan/dav1d/${VER}/dav1d-${VER}.tar.xz" "${SRC}"
mkdir -p "${SRC}/build"
cd "${SRC}"
meson setup build \
  --prefix="${PREFIX}" \
  --buildtype=release \
  --default-library=shared \
  -Denable_tests=false \
  -Denable_examples=false \
  -Denable_tools=false
ninja -C build -j"${JOBS}"
ninja -C build install
ldconfig

verify_pc dav1d
cleanup "${SRC}"
