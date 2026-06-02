#!/usr/bin/env bash
# libraw1394 — raw IEEE 1394 (FireWire) access library; dependency of libdc1394.
# SourceForge hosts 2.0.5; upstream git at kernel.org has 2.1.2 — use git for latest.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v2.1.2"
SRC="${SRCROOT}/libraw1394"

fetch_git "https://git.kernel.org/pub/scm/libs/ieee1394/libraw1394.git" "${VER}" "${SRC}"
cd "${SRC}"
./autogen.sh --prefix="${PREFIX}" --enable-shared --disable-static
make -j"${JOBS}"
make install
ldconfig

verify_pc libraw1394
cleanup "${SRC}"
