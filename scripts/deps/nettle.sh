#!/usr/bin/env bash
# nettle — GNU low-level cryptographic library (nettle.pc + hogweed.pc).
# Required by gnutls. Also a transitive dep of p11-kit and librist.
# Must run after gmp.sh (hogweed needs libgmp).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="3.10.2"
SRC="${SRCROOT}/nettle"

fetch_tar "https://ftp.gnu.org/gnu/nettle/nettle-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static \
  --disable-documentation
make -j"${JOBS}"
make install
ldconfig

verify_pc nettle hogweed
cleanup "${SRC}"
