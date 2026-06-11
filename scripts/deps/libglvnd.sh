#!/usr/bin/env bash
# libglvnd — GL Vendor-Neutral Dispatch library (NVIDIA/Khronos); provides gl.pc + egl.pc
# + glesv2.pc. Satisfies FFmpeg --enable-opengl WITHOUT building Mesa — the actual GL
# driver / loader is provided by the host at runtime (e.g. NVIDIA driver's libGL).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v1.7.0"
SRC="${SRCROOT}/libglvnd"

fetch_git "https://github.com/NVIDIA/libglvnd.git" "${VER}" "${SRC}"
meson setup "${SRC}/build" "${SRC}" \
  --prefix="${PREFIX}" \
  --buildtype=release \
  --default-library=shared \
  -Dx11=enabled \
  -Dglx=enabled \
  -Degl=true \
  -Dgles1=true \
  -Dgles2=true \
  -Dheaders=true
ninja -C "${SRC}/build" -j"${JOBS}"
ninja -C "${SRC}/build" install
ldconfig

verify_pc gl egl glesv2
cleanup "${SRC}"
