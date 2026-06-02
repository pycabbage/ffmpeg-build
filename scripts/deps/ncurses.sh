#!/usr/bin/env bash
# ncurses — terminal-handling library with wide-character support (ncursesw).
# Required by readline and Python. --enable-overwrite installs ncursesw headers
# under the plain ncurses names so downstream finds them without special paths.
# We build ONLY the libraries (+ pkg-config files): --without-cxx-binding/--without-progs/
# --without-tests/--without-manpages/--without-ada drop the C++ binding (its `demo` program
# fails to link _Unwind_Resume under gcc's --as-needed), the tic/infocmp progs, the test
# programs, man pages and Ada binding — none of which readline/Python need.
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
  --enable-overwrite \
  --without-cxx-binding \
  --without-ada \
  --without-manpages \
  --without-progs \
  --without-tests
make -j"${JOBS}"
make install
ldconfig

verify_pc ncursesw
cleanup "${SRC}"
