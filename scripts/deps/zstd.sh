#!/usr/bin/env bash
# zstd — Zstandard compression. Used by binutils/gcc (compressed debug/LTO) and several media
# libs. Plain Makefile build; install shared lib + zstd.pc. Runs before gcc.sh (seed compiler).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.5.6"
SRC="${SRCROOT}/zstd"

fetch_git "https://github.com/facebook/zstd.git" "v${VER}" "${SRC}"
cd "${SRC}"
make -j"${JOBS}" PREFIX="${PREFIX}"
make install PREFIX="${PREFIX}"
ldconfig

verify_pc libzstd
cleanup "${SRC}"
