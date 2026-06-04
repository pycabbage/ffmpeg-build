#!/usr/bin/env bash
# libX11 — core X11 client library (Xlib); provides x11.pc. Required by libvdpau (VDPAU is an
# X11 API) and by FFmpeg --enable-vdpau (vdpau/vdpau_x11.h) and the GLX path of --enable-opengl.
# Uses libxcb as its transport and xtrans build headers; protocol headers come from xorgproto.
# Must run after xtrans, libxcb (+ libXau/libXdmcp), xorgproto, util-macros.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.8.12"
SRC="${SRCROOT}/libX11"

fetch_tar "https://www.x.org/releases/individual/lib/libX11-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
# --disable-specs + --without-{xmlto,fop,xsltproc}: skip the documentation toolchain we do not
# ship. Shared lib only, consistent with the rest of the build.
./configure --prefix="${PREFIX}" \
  --enable-shared --disable-static \
  --disable-specs \
  --without-xmlto \
  --without-fop \
  --without-xsltproc
make -j"${JOBS}"
make install
ldconfig

verify_pc x11
cleanup "${SRC}"
