#!/usr/bin/env bash
# libaom — AV1 codec reference implementation; FFmpeg --enable-libaom.
# cmake build. Fetched via git tag: the googlesource `+archive` tarball has NO top-level dir,
# which fetch_tar's --strip-components=1 would mangle (dropping CMakeLists.txt).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="3.14.1"
SRC="${SRCROOT}/aom"

fetch_git "https://aomedia.googlesource.com/aom" "v${VER}" "${SRC}"
mkdir -p "${SRC}/build"
cd "${SRC}/build"
cmake .. \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DENABLE_TESTS=0 \
  -DENABLE_EXAMPLES=0 \
  -DENABLE_DOCS=0
make -j"${JOBS}"
make install
ldconfig

verify_pc aom
cleanup "${SRC}"
