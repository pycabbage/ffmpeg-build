#!/usr/bin/env bash
# fontconfig — font discovery and configuration library; FFmpeg --enable-libfontconfig.
# Depends on freetype, expat, and gperf (build-time tool). Autotools build.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2.18.0"
SRC="${SRCROOT}/fontconfig"

# GitHub read-only mirror of gitlab.freedesktop.org/fontconfig/fontconfig
fetch_git "https://github.com/fontconfig/fontconfig.git" "${VER}" "${SRC}"
cd "${SRC}"
# fontconfig's configure.ac uses AM_GNU_GETTEXT, whose macro (gettext.m4) ships with the apt
# bootstrap-seed gettext in /usr/share/aclocal — but our from-source aclocal (/usr/local) does
# not search there by default, so autoreconf fails "undefined macro: AM_GNU_GETTEXT". Point
# aclocal at the seed's macro dir. Safe: that dir holds only gettext macros here (pkgconf and
# libtool are from-source under /usr/local, so no pkg.m4/libtool.m4 collision).
export ACLOCAL_PATH="/usr/share/aclocal${ACLOCAL_PATH:+:$ACLOCAL_PATH}"
autoreconf -fiv
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static \
  --disable-docs \
  --enable-libxml2=no
make -j"${JOBS}"
make install
ldconfig

verify_pc fontconfig
cleanup "${SRC}"
