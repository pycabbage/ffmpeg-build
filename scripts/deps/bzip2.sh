#!/usr/bin/env bash
# bzip2 — bzip2 compression for FFmpeg --enable-bzlib. The stock Makefile builds only the
# static libbz2.a; the separate Makefile-libbz2_so builds the shared libbz2.so.1.0.8. We
# build both, install the shared lib + symlinks + header, and hand-write a bzip2.pc (upstream
# ships none) so downstream pkg-config checks resolve it. Runs before gcc.sh (seed compiler).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.0.8"
SRC="${SRCROOT}/bzip2"

fetch_git "https://gitlab.com/bzip2/bzip2.git" "bzip2-${VER}" "${SRC}"
cd "${SRC}"
# shared object
make -f Makefile-libbz2_so -j"${JOBS}"
# static lib + headers + tools
make -j"${JOBS}"
make install PREFIX="${PREFIX}"
# install the shared lib produced above and wire the soname symlinks
cp -a libbz2.so.${VER} "${PREFIX}/lib/"
ln -sf libbz2.so.${VER} "${PREFIX}/lib/libbz2.so.1.0"
ln -sf libbz2.so.1.0    "${PREFIX}/lib/libbz2.so.1"
ln -sf libbz2.so.1      "${PREFIX}/lib/libbz2.so"
mkdir -p "${PREFIX}/lib/pkgconfig"
cat > "${PREFIX}/lib/pkgconfig/bzip2.pc" <<PC
prefix=${PREFIX}
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: bzip2
Description: bzip2 compression library
Version: ${VER}
Libs: -L\${libdir} -lbz2
Cflags: -I\${includedir}
PC
ldconfig

verify_pc bzip2
cleanup "${SRC}"
