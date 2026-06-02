#!/usr/bin/env bash
# CPython 3.13 — required by ninja bootstrap, meson, and some dep build scripts.
# Built with --with-openssl so ssl/hashlib work and --with-system-ffi for ctypes.
# Optional modules _sqlite3, readline and _curses/_curses_panel are intentionally NOT built:
# the FFmpeg build chain (ninja/cmake/meson/pip) does not use them, and the readline/curses
# extension links are fragile (readline.so failed to build, breaking `make install`).
# py_cv_module_<name>=n/a disables a module in CPython's configure. ensurepip runs
# post-install so pip is available for meson.sh.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="3.13.3"
SRC="${SRCROOT}/python"

fetch_tar "https://www.python.org/ftp/python/${VER}/Python-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
# Canonical CPython mechanism to exclude modules from BOTH the build and sharedinstall (the
# configure cache vars below are a second, redundant safeguard).
cat > Modules/Setup.local <<'EOF'
*disabled*
readline
_curses
_curses_panel
EOF
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --with-openssl="${PREFIX}" \
  --with-system-ffi \
  --with-ensurepip=upgrade \
  py_cv_module_readline=n/a \
  py_cv_module__curses=n/a \
  py_cv_module__curses_panel=n/a
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
