#!/usr/bin/env bash
# pkgconf — pkg-config implementation; provides ${PREFIX}/bin/pkgconf + a pkg-config symlink
# and the pkg.m4 autoconf macros. No FFmpeg --enable flag, but it is the FIRST thing built:
# every later dependency script calls verify_pc (pkg-config), so pkg-config must already exist.
#
# Built in the bootstrap phase with the SEED compiler, BEFORE meson exists, so we use the
# release tarball's pre-generated autotools `./configure` (NOT the meson path) — meson would be
# a circular dependency this early. pkgconf is self-contained (vendors libpkgconf), needs only
# a C compiler + make.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2.5.1"
SRC="${SRCROOT}/pkgconf"

fetch_tar "https://distfiles.ariadne.space/pkgconf/pkgconf-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
# Default search/include paths so pkgconf resolves both our prefix and the multiarch dirs.
./configure --prefix="${PREFIX}" \
  --with-system-libdir="${PREFIX}/lib:/usr/lib/x86_64-linux-gnu:/usr/lib" \
  --with-system-includedir="${PREFIX}/include:/usr/include"
make -j"${JOBS}"
make install
ldconfig

# Canonical pkg-config name expected by autotools/cmake/meson consumers.
ln -sf pkgconf "${PREFIX}/bin/pkg-config"

# pkg.m4 must be where aclocal looks; verify both it and a working pkg-config.
test -f "${PREFIX}/share/aclocal/pkg.m4"
"${PREFIX}/bin/pkg-config" --version

cleanup "${SRC}"
