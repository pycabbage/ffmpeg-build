#!/usr/bin/env bash
# MPFR — multiple-precision floating point. gcc build dependency (and used by gnutls' nettle).
# Needs GMP (built first). Static+shared. Runs before gcc.sh with the bootstrap seed compiler.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="4.2.1"
SRC="${SRCROOT}/mpfr"

# Fetched from the GNU mirror (more reliable from CI than www.mpfr.org).
fetch_tar "https://ftp.gnu.org/gnu/mpfr/mpfr-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --with-gmp="${PREFIX}" --enable-shared
make -j"${JOBS}"
make install
ldconfig

verify_pc mpfr
cleanup "${SRC}"
