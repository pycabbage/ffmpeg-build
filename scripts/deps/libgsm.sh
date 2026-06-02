#!/usr/bin/env bash
# libgsm — Jutta Degener GSM 06.10 lossy speech compression; serves FFmpeg --enable-libgsm.
# Quirky: Makefile-based, builds only static lib and no shared lib by default, ships no .pc.
# We patch the Makefile to build a shared libgsm.so, then install header + lib manually.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.0.24"
SRC="${SRCROOT}/libgsm"

fetch_tar "https://www.quut.com/gsm/gsm-${VER}.tar.gz" "${SRC}"
cd "${SRC}"

# Build the static lib first (needed by the shared build too), then the shared lib.
# NOTE: gsm's Makefile keeps -c *inside* its CCFLAGS; overriding CCFLAGS drops it, so the .c.o
# rule would LINK instead of compile ("Scrt1.o: undefined reference to `main'"). Keep -c here.
make -j"${JOBS}" CC="${PREFIX}/bin/gcc" CCFLAGS="-c -O2 -fPIC -DSASR -DWAV49" lib/libgsm.a

# Build shared library by linking all object files.
mkdir -p lib
${PREFIX}/bin/gcc -shared -Wl,-soname,libgsm.so.1 \
  -o lib/libgsm.so.${VER} src/*.o
ln -sf libgsm.so.${VER} lib/libgsm.so.1
ln -sf libgsm.so.1      lib/libgsm.so

# Install header.
mkdir -p "${PREFIX}/include/gsm"
cp inc/gsm.h "${PREFIX}/include/gsm/gsm.h"

# Install shared lib + symlinks.
cp lib/libgsm.so.${VER} "${PREFIX}/lib/"
ln -sf libgsm.so.${VER} "${PREFIX}/lib/libgsm.so.1"
ln -sf libgsm.so.1      "${PREFIX}/lib/libgsm.so"
ldconfig

test -f "${PREFIX}/lib/libgsm.so"
cleanup "${SRC}"
