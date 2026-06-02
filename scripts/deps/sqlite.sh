#!/usr/bin/env bash
# SQLite — embedded SQL database engine; required by Python's sqlite3 module.
# Uses the official autoconf amalgamation tarball from sqlite.org (single .c + header).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="3530100"   # encodes SQLite version 3.53.1.0
SRC="${SRCROOT}/sqlite"

fetch_tar "https://www.sqlite.org/2026/sqlite-autoconf-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --disable-static --enable-shared \
  --enable-fts5 --enable-json1
make -j"${JOBS}"
make install
ldconfig

verify_pc sqlite3
cleanup "${SRC}"
