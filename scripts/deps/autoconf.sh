#!/usr/bin/env bash
# GNU autoconf — generates configure scripts from configure.ac.
# Requires m4 (built prior) and perl (from base OS).
# No FFmpeg --enable flag; pure build-tool dependency.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2.73"
SRC="${SRCROOT}/autoconf"

fetch_tar "https://ftp.gnu.org/gnu/autoconf/autoconf-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}"
make -j"${JOBS}"
make install
ldconfig

test -f "${PREFIX}/bin/autoconf"
cleanup "${SRC}"
