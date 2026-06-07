#!/usr/bin/env bash
# libqrencode — QR code encoder; FFmpeg --enable-libqrencode (qrencode/qrencodesrc filters;
# pkg-config: libqrencode). cmake build; tools/tests off (the CLI tool would pull libpng/SDL).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="4.1.1"
SRC="${SRCROOT}/libqrencode"

fetch_git "https://github.com/fukuchi/libqrencode" "v${VER}" "${SRC}"
mkdir -p "${SRC}/build"
cd "${SRC}/build"
cmake .. \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DWITH_TOOLS=NO \
  -DWITH_TESTS=NO
make -j"${JOBS}"
make install
ldconfig

verify_pc libqrencode
cleanup "${SRC}"
