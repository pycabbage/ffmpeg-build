#!/usr/bin/env bash
# ISL — integer set library, used by gcc's Graphite loop optimizations. gcc build dependency.
# Needs GMP. Static+shared. Runs before gcc.sh with the bootstrap seed compiler.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="0.26"
SRC="${SRCROOT}/isl"

fetch_tar "https://libisl.sourceforge.io/isl-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --with-gmp-prefix="${PREFIX}" --enable-shared
make -j"${JOBS}"
make install
ldconfig

cleanup "${SRC}"
