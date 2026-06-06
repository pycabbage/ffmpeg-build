#!/usr/bin/env bash
# SDL2 — Simple DirectMedia Layer 2; provides sdl2.pc.
# FFmpeg --enable-sdl2 (ffplay output + sdl2 device). We stay on SDL 2.x (not SDL3)
# because FFmpeg 8.1.1 configure checks for sdl2.pc specifically.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2.32.8"
SRC="${SRCROOT}/sdl2"

fetch_tar "https://www.libsdl.org/release/SDL2-${VER}.tar.gz" "${SRC}"
mkdir -p "${SRC}/build"
# -DSDL_X11=OFF: libX11 is now present (added for vdpau), which makes SDL2 auto-enable its X11
# video backend and then hard-fail for the rest of the Xlib extension suite (Xext, Xrender,
# Xcursor, Xrandr, …) which this build does not ship. SDL2 built without X11 in every prior run;
# keep it that way (it still has kmsdrm via libdrm + dummy). FFmpeg --enable-sdl2 only needs
# sdl2.pc + libSDL2. (Full SDL2 X11 display is part of the later maximal X11-stack work.)
cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DSDL_STATIC=OFF \
  -DSDL_TEST=OFF \
  -DSDL_X11=OFF
cmake --build "${SRC}/build" -j"${JOBS}"
cmake --install "${SRC}/build"
ldconfig

verify_pc sdl2
cleanup "${SRC}"
