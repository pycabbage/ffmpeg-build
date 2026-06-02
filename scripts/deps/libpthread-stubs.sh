#!/usr/bin/env bash
# libpthread-stubs — stub replacements for POSIX thread functions not provided by libc;
# provides pthread-stubs.pc. Small helper required by libxcb's configure checks.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="0.5"
SRC="${SRCROOT}/libpthread-stubs"

fetch_tar "https://xcb.freedesktop.org/dist/libpthread-stubs-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}"
make -j"${JOBS}"
make install
ldconfig

verify_pc pthread-stubs
cleanup "${SRC}"
