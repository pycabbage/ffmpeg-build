#!/usr/bin/env bash
# libtasn1 — ASN.1 structure parser used by GnuTLS (--with-included-libtasn1=no).
# Provides libtasn1.pc. No FFmpeg flag of its own; it is a gnutls build dep.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="4.21.0"
SRC="${SRCROOT}/libtasn1"

fetch_tar "https://ftp.gnu.org/gnu/libtasn1/libtasn1-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static \
  --disable-doc
make -j"${JOBS}"
make install
ldconfig

verify_pc libtasn1
cleanup "${SRC}"
