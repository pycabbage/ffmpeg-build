#!/usr/bin/env bash
# MPC — complex-number arithmetic over MPFR. gcc build dependency. Needs GMP + MPFR.
# Static+shared. Runs before gcc.sh with the bootstrap seed compiler.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.3.1"
SRC="${SRCROOT}/mpc"

fetch_tar "https://ftp.gnu.org/gnu/mpc/mpc-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --with-gmp="${PREFIX}" --with-mpfr="${PREFIX}" --enable-shared
make -j"${JOBS}"
make install
ldconfig

cleanup "${SRC}"
