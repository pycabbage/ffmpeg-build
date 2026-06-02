#!/usr/bin/env bash
# libvmaf: Netflix VMAF for FFmpeg --enable-libvmaf.
# Ubuntu 24.04 has NO libvmaf-dev package (verified) -> always built from source.
# The buildable project is the libvmaf/ SUBDIR, not the repo root.
set -euxo pipefail

VER="v3.1.0"
SRC="/tmp/vmaf"

git clone --depth 1 --branch "${VER}" \
  https://github.com/Netflix/vmaf.git "${SRC}"

meson setup "${SRC}/libvmaf" "${SRC}/libvmaf/build" \
  --buildtype release \
  --default-library shared \
  --prefix /usr/local \
  -Denable_tests=false \
  -Denable_docs=false
ninja -C "${SRC}/libvmaf/build"
ninja -C "${SRC}/libvmaf/build" install
ldconfig

pkg-config --exists --print-errors libvmaf

rm -rf "${SRC}"
