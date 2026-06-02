#!/usr/bin/env bash
# CPython 3.13 — required by ninja bootstrap, meson, and some dep build scripts.
# Built with --with-openssl so ssl/hashlib work and --with-system-ffi for ctypes.
# The optional _sqlite3 module is intentionally NOT built (no libsqlite3 in this image; the
# FFmpeg build chain — ninja/cmake/meson/pip — does not need it). ensurepip runs post-install
# so pip is available for meson.sh.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="3.13.3"
SRC="${SRCROOT}/python"

fetch_tar "https://www.python.org/ftp/python/${VER}/Python-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --with-openssl="${PREFIX}" \
  --with-system-ffi \
  --with-ensurepip=upgrade
make -j"${JOBS}"
make install
ldconfig

# Make python3 the default if not already present.
if [ ! -e "${PREFIX}/bin/python3" ]; then
  ln -sf "${PREFIX}/bin/python3.13" "${PREFIX}/bin/python3"
fi
if [ ! -e "${PREFIX}/bin/python" ]; then
  ln -sf "${PREFIX}/bin/python3" "${PREFIX}/bin/python"
fi

# Ensure pip is present.
"${PREFIX}/bin/python3" -m ensurepip --upgrade

"${PREFIX}/bin/python3" --version
cleanup "${SRC}"
