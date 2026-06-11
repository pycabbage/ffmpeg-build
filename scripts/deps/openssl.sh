#!/usr/bin/env bash
# OpenSSL — TLS/crypto library built ONLY to give Python a working ssl/hashlib module.
# NOT enabled as an FFmpeg TLS backend (FFmpeg uses GnuTLS). install_sw installs
# libraries + headers only (no man pages); install_ssldirs writes config dirs.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="3.6.2"
SRC="${SRCROOT}/openssl"

fetch_tar "https://github.com/openssl/openssl/releases/download/openssl-${VER}/openssl-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./Configure linux-x86_64 \
  --prefix="${PREFIX}" \
  --libdir=lib \
  shared
make -j"${JOBS}"
make install_sw install_ssldirs
ldconfig

test -f "${PREFIX}/lib/libssl.so"
cleanup "${SRC}"
