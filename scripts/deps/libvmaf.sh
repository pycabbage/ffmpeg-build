#!/usr/bin/env bash
# libvmaf: Netflix VMAF for FFmpeg --enable-libvmaf.
# Ubuntu 24.04 has NO libvmaf-dev package (verified) -> always built from source.
# The buildable project is the libvmaf/ SUBDIR, not the repo root.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v3.1.0"
SRC="${SRCROOT}/vmaf"

fetch_git https://github.com/Netflix/vmaf.git "${VER}" "${SRC}"

meson setup "${SRC}/libvmaf" "${SRC}/libvmaf/build" \
  --buildtype release \
  --default-library shared \
  --prefix "${PREFIX}" \
  -Denable_tests=false \
  -Denable_docs=false
ninja -C "${SRC}/libvmaf/build" -j"${JOBS}"
ninja -C "${SRC}/libvmaf/build" install
ldconfig

verify_pc libvmaf
cleanup "${SRC}"
