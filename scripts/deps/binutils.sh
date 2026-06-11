#!/usr/bin/env bash
# binutils — the assembler (as), linker (ld) and binary tools our from-source gcc drives.
# Built before gcc.sh with the bootstrap seed compiler and installed into the prefix so that
# /usr/local/bin/{as,ld,...} (first on PATH) are used by every subsequent compile. Out-of-tree
# build. Uses our zlib/zstd for compressed-section support.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2.42"
SRC="${SRCROOT}/binutils"

fetch_tar "https://ftp.gnu.org/gnu/binutils/binutils-${VER}.tar.xz" "${SRC}"
mkdir -p "${SRC}/build"
cd "${SRC}/build"
../configure \
  --prefix="${PREFIX}" \
  --enable-shared --enable-ld=default --enable-gold \
  --enable-plugins --enable-64-bit-bfd \
  --with-system-zlib --disable-new-dtags \
  --disable-werror --disable-nls
make -j"${JOBS}"
make install
ldconfig

"${PREFIX}/bin/ld" --version | head -1
cleanup "${SRC}"
