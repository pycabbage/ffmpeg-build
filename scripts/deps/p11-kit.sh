#!/usr/bin/env bash
# p11-kit — PKCS#11 module loader/enumeration. Required by GnuTLS for PKCS#11 support.
# Must run after libffi (already built). Meson build; provides p11-kit-1.pc.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="0.26.2"
SRC="${SRCROOT}/p11-kit"

fetch_tar "https://github.com/p11-glue/p11-kit/releases/download/${VER}/p11-kit-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
mkdir -p build
meson setup build \
  --prefix="${PREFIX}" \
  --buildtype=release \
  --default-library=shared \
  -Dtrust_paths="${PREFIX}/etc/ssl/certs" \
  -Dman=false \
  -Dgtk_doc=false
ninja -C build -j"${JOBS}"
ninja -C build install
ldconfig

verify_pc p11-kit-1
cleanup "${SRC}"
