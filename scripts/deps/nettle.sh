#!/usr/bin/env bash
# nettle — GNU low-level cryptographic library (nettle.pc + hogweed.pc).
# Required by gnutls. Also a transitive dep of p11-kit and librist.
# Must run after gmp.sh (hogweed needs libgmp).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="3.10.2"
SRC="${SRCROOT}/nettle"

fetch_tar "https://ftp.gnu.org/gnu/nettle/nettle-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
# nettle's configure defaults libdir to lib64 on x86_64, which would put libnettle.so /
# nettle.pc under /usr/local/lib64{,/pkgconfig} — off our PKG_CONFIG_PATH and -L search dir, so
# verify_pc (and downstream gnutls/p11-kit/librist) would not find it. Pin --libdir to lib to
# stay consistent with every other from-source lib.
./configure \
  --prefix="${PREFIX}" \
  --libdir="${PREFIX}/lib" \
  --enable-shared \
  --disable-static \
  --disable-documentation
make -j"${JOBS}"
make install
ldconfig

verify_pc nettle hogweed
cleanup "${SRC}"
