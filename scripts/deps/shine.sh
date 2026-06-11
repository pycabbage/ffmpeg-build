#!/usr/bin/env bash
# libshine — fixed-point MP3 encoder; serves FFmpeg --enable-libshine.
# Uses autotools; upstream tarball has no configure — autoreconf required.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="3.1.1"
SRC="${SRCROOT}/shine"

fetch_tar "https://github.com/toots/shine/archive/refs/tags/${VER}.tar.gz" "${SRC}"
cd "${SRC}"
autoreconf -fiv
# Our freshly-built autoconf auto-selects -std=gnu23 for gcc-14 (it appends it to $CC). Under
# C23 an empty parameter list '()' means '(void)', so shine's K&R-style forward declaration
# `void shine_mdct_initialise();` conflicts with the real definition that takes an argument
# (l3mdct.c "conflicting types"). Force gnu17 via CFLAGS: automake places user CFLAGS AFTER
# $(CC) on the compile line, so this trailing -std wins over autoconf's injected -std=gnu23.
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static \
  CFLAGS="${CFLAGS:-} -O2 -std=gnu17"
make -j"${JOBS}"
make install
ldconfig

verify_pc shine
cleanup "${SRC}"
