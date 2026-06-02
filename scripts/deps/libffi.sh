#!/usr/bin/env bash
# libffi — foreign function interface library; needed by Python ctypes and p11-kit.
# No FFmpeg --enable flag; indirect build-tool dependency via Python.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="3.5.2"
SRC="${SRCROOT}/libffi"

fetch_tar "https://github.com/libffi/libffi/releases/download/v${VER}/libffi-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --disable-static --enable-shared
make -j"${JOBS}"
make install
ldconfig

verify_pc libffi
cleanup "${SRC}"
