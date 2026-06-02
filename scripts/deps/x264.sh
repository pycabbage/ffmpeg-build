#!/usr/bin/env bash
# x264 — H.264/AVC encoder; FFmpeg --enable-libx264.
# x264 uses a rolling "stable" branch (no semver tags). We fetch a dated snapshot from
# the BLFS-mirrored tarball (commit 20250815) which is known-good with FFmpeg 8.1.1.
# nasm must be on PATH (it is, built before media libs).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="20250815"
SRC="${SRCROOT}/x264"

fetch_tar "https://anduin.linuxfromscratch.org/BLFS/x264/x264-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --enable-pic \
  --disable-cli
make -j"${JOBS}"
make install
ldconfig

verify_pc x264
cleanup "${SRC}"
