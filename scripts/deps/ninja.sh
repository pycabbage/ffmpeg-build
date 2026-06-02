#!/usr/bin/env bash
# ninja — fast build system; required by cmake bootstrap and meson builds.
# Built from source using our python3 (configure.py --bootstrap compiles ninja.cc
# into a self-contained binary with no external dependencies).
# Must be built BEFORE cmake.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.13.2"
SRC="${SRCROOT}/ninja"

fetch_tar "https://github.com/ninja-build/ninja/archive/refs/tags/v${VER}.tar.gz" "${SRC}"
cd "${SRC}"
"${PREFIX}/bin/python3" configure.py --bootstrap
install -m 755 ninja "${PREFIX}/bin/ninja"

ninja --version
cleanup "${SRC}"
