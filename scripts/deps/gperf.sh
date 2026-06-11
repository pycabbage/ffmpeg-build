#!/usr/bin/env bash
# GNU gperf — perfect-hash function generator; required by fontconfig at build time only.
# Not a library; installs only a binary. No .pc file — sanity via gperf --version.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="3.3"
SRC="${SRCROOT}/gperf"

fetch_tar "https://ftp.gnu.org/gnu/gperf/gperf-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}"
make -j"${JOBS}"
make install

gperf --version
cleanup "${SRC}"
