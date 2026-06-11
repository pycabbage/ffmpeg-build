#!/usr/bin/env bash
# ISL — integer set library, used by gcc's Graphite loop optimizations. gcc build dependency.
# Needs GMP. Static+shared. Runs before gcc.sh with the bootstrap seed compiler.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

# Pinned to 0.24 and fetched from gcc's infrastructure mirror: it is the isl version gcc 14.2
# bundles (contrib/download_prerequisites) and the host is rock-solid from CI (the sourceforge
# host is comparatively flaky).
VER="0.24"
SRC="${SRCROOT}/isl"

fetch_tar "https://gcc.gnu.org/pub/gcc/infrastructure/isl-${VER}.tar.bz2" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --with-gmp-prefix="${PREFIX}" --enable-shared
make -j"${JOBS}"
make install
ldconfig

cleanup "${SRC}"
