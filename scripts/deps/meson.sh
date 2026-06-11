#!/usr/bin/env bash
# meson — build system used by libplacebo, pkgconf, and many other deps.
# Installed via pip from the official source release tarball (the ONLY script
# where pip install is permitted per spec). Requires python + ninja + cmake
# (all built prior). --no-build-isolation prevents pip from fetching build deps.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.8.2"
SRC="${SRCROOT}/meson"

fetch_tar "https://github.com/mesonbuild/meson/releases/download/${VER}/meson-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
"${PREFIX}/bin/python3" -m pip install --no-build-isolation --prefix="${PREFIX}" ./

meson --version
cleanup "${SRC}"
