#!/usr/bin/env bash
# GMP — GNU Multiple Precision arithmetic. A gcc build dependency (used by mpfr/mpc/isl and
# gcc itself) AND a FFmpeg dependency (--enable-gmp) and a gnutls/nettle dependency. Built
# with the bootstrap seed compiler, before gcc.sh. C++ support enabled (some consumers want it).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="6.3.0"
SRC="${SRCROOT}/gmp"

fetch_tar "https://gmplib.org/download/gmp/gmp-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
# Keep BOTH static + shared: gcc's in-tree build prefers to statically absorb gmp/mpfr/mpc/isl.
./configure --prefix="${PREFIX}" --enable-cxx --enable-shared
make -j"${JOBS}"
make install
ldconfig

verify_pc gmp
cleanup "${SRC}"
