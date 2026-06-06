#!/usr/bin/env bash
# libXext — X11 common extensions client library (XShm, XSync, DPMS, Shape, …); provides xext.pc.
# Required by libglvnd's GLX backend (FFmpeg --enable-opengl): libglvnd's meson build
# hard-requires the "xext" pkg-config dependency. Builds on libX11 + xorgproto (XextProto) +
# xtrans, all already built earlier in the X11 stack.
# Grouped with its consumer (the libglvnd/opengl cluster) rather than the X11 base stack on
# purpose: that keeps the canonical order in build-deps.sh mirrored by the Dockerfile while
# avoiding a cache-bust of the (much heavier) vulkan/spirv/glslang/shaderc layers that are built
# before libglvnd — dependencies are already satisfied either way.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.3.6"
SRC="${SRCROOT}/libXext"

fetch_tar "https://www.x.org/releases/individual/lib/libXext-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
# Shared lib only; skip the X.Org documentation toolchain we do not ship.
./configure --prefix="${PREFIX}" \
  --enable-shared --disable-static \
  --without-xmlto \
  --without-fop \
  --without-xsltproc
make -j"${JOBS}"
make install
ldconfig

verify_pc xext
cleanup "${SRC}"
