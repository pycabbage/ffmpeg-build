#!/usr/bin/env bash
# librsvg — SVG rendering; FFmpeg --enable-librsvg (pkg-config: librsvg-2.0). meson front-end that
# drives a Rust (cargo) build, so reuse the rustup toolchain rav1e installed at /opt/rust. Needs
# cairo + pango + gdk-pixbuf + glib + our harfbuzz/freetype/libxml2.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2.62.3"
SRC="${SRCROOT}/librsvg"

export RUSTUP_HOME="/opt/rust/rustup" CARGO_HOME="/opt/rust/cargo"
export PATH="${CARGO_HOME}/bin:${PATH}"
export CC=gcc CXX=g++

fetch_tar "https://download.gnome.org/sources/librsvg/2.62/librsvg-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
meson setup build \
  --prefix="${PREFIX}" \
  --buildtype=release \
  --default-library=shared \
  -Dintrospection=disabled \
  -Ddocs=disabled \
  -Dvala=disabled \
  -Dpixbuf-loader=disabled \
  -Dtests=false
ninja -C build -j"${JOBS}"
ninja -C build install
ldconfig

verify_pc librsvg-2.0
cleanup "${SRC}"
