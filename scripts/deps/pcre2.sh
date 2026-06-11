#!/usr/bin/env bash
# PCRE2 — Perl-compatible regex (8/16/32-bit + JIT); required by glib (GRegex). autotools.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="10.46"
SRC="${SRCROOT}/pcre2"

fetch_tar "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${VER}/pcre2-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --enable-shared --disable-static \
  --enable-pcre2-16 --enable-pcre2-32 --enable-jit
make -j"${JOBS}"
make install
ldconfig

verify_pc libpcre2-8
cleanup "${SRC}"
