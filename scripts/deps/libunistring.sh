#!/usr/bin/env bash
# libunistring — GNU Unicode string library. Required by GnuTLS
# (--with-included-unistring=no). Does not install a .pc; sanity-checked via .so.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.4.2"
SRC="${SRCROOT}/libunistring"

fetch_tar "https://ftp.gnu.org/gnu/libunistring/libunistring-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static
make -j"${JOBS}"
make install
ldconfig

test -f "${PREFIX}/lib/libunistring.so" || die "libunistring.so not found after install"
cleanup "${SRC}"
