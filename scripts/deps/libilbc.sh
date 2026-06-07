#!/usr/bin/env bash
# libilbc — iLBC narrowband speech codec (dropped from the Ubuntu archive); FFmpeg
# --enable-libilbc (pkg-config: libilbc). cmake build; installs libilbc.pc.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="3.0.4"
SRC="${SRCROOT}/libilbc"

fetch_git "https://github.com/TimothyGu/libilbc" "v${VER}" "${SRC}"
mkdir -p "${SRC}/build"
cd "${SRC}/build"
cmake .. \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON
make -j"${JOBS}"
make install
ldconfig

verify_pc libilbc
cleanup "${SRC}"
