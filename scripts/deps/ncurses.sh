#!/usr/bin/env bash
# ncurses — terminal-handling library with wide-character support (ncursesw).
# Required by readline and Python. --enable-overwrite installs ncursesw headers
# under the plain ncurses names so downstream finds them without special paths.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="6.6"
SRC="${SRCROOT}/ncurses"

fetch_tar "https://ftp.gnu.org/gnu/ncurses/ncurses-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure \
  --prefix="${PREFIX}" \
  --with-shared \
  --without-debug \
  --enable-widec \
  --enable-pc-files \
  --with-pkg-config-libdir="${PREFIX}/lib/pkgconfig" \
  --enable-overwrite
make -j"${JOBS}"
make install
ldconfig

verify_pc ncursesw
cleanup "${SRC}"
