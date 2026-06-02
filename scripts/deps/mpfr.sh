#!/usr/bin/env bash
# MPFR — multiple-precision floating point. gcc build dependency (and used by gnutls' nettle).
# Needs GMP (built first). Static+shared. Runs before gcc.sh with the bootstrap seed compiler.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="4.2.1"
SRC="${SRCROOT}/mpfr"

fetch_tar "https://www.mpfr.org/mpfr-${VER}/mpfr-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --with-gmp="${PREFIX}" --enable-shared
make -j"${JOBS}"
make install
ldconfig

verify_pc mpfr
cleanup "${SRC}"
