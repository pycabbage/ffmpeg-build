#!/usr/bin/env bash
# xz / liblzma — LZMA compression for FFmpeg --enable-lzma (and used by many archives).
# Pinned to the 5.4.x branch, which predates the CVE-2024-3094 backdoor that was injected into
# the 5.6.0/5.6.1 release tarballs; 5.4.7 is the clean, widely-vetted stable. We fetch the .gz
# tarball (not .xz) so extraction never depends on an xz binary. Runs before gcc.sh (seed cc).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="5.4.7"
SRC="${SRCROOT}/xz"

fetch_tar "https://github.com/tukaani-project/xz/releases/download/v${VER}/xz-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --disable-static --enable-shared --disable-doc
make -j"${JOBS}"
make install
ldconfig

verify_pc liblzma
cleanup "${SRC}"
