#!/usr/bin/env bash
# readline — command-line editing library; required by Python interactive mode.
# Needs ncursesw (built prior).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="8.3"
SRC="${SRCROOT}/readline"

fetch_tar "https://ftp.gnu.org/gnu/readline/readline-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --disable-static --enable-shared
make -j"${JOBS}"
make install
ldconfig

verify_pc readline
cleanup "${SRC}"
