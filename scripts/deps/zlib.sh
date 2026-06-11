#!/usr/bin/env bash
# zlib — compression library. Foundational: needed by gcc, binutils, python, libpng, gnutls,
# libxml2 and many media libs, and by FFmpeg --enable-zlib. Built with the bootstrap seed
# compiler (this runs before gcc.sh), installed shared into the prefix.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.3.1"
SRC="${SRCROOT}/zlib"

# Fetched from the GitHub release (zlib.net's TLS cert has intermittently tripped clients).
fetch_tar "https://github.com/madler/zlib/releases/download/v${VER}/zlib-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}"
make -j"${JOBS}"
make install
ldconfig

verify_pc zlib
cleanup "${SRC}"
