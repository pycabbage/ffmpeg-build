#!/usr/bin/env bash
# gnutls — GNU TLS library. FFmpeg --enable-gnutls (TLS backend for network protocols).
# Must run after nettle, libtasn1, libunistring, p11-kit, gmp.
# Provides gnutls.pc. Note: --disable-hardware-acceleration avoids cpuid asm issues;
# --without-tpm2 avoids libtss2 dependency. The default trust store points at the HOST's
# /etc/ssl/certs/ca-certificates.crt -- a system resource the relocatable bundle relies on the
# host to provide (like glibc); ${PREFIX}/etc/... only exists inside the build image, which would
# leave TLS verification with no system CAs once the bundle is moved to a host.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="3.8.13"
SRC="${SRCROOT}/gnutls"

fetch_tar "https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/gnutls-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static \
  --with-included-libtasn1=no \
  --with-included-unistring=no \
  --with-p11-kit \
  --disable-doc \
  --disable-tests \
  --disable-tools \
  --disable-guile \
  --without-tpm2 \
  --without-idn \
  --disable-libdane \
  --disable-hardware-acceleration \
  --with-default-trust-store-file="/etc/ssl/certs/ca-certificates.crt"
make -j"${JOBS}"
make install
ldconfig

verify_pc gnutls
cleanup "${SRC}"
