#!/usr/bin/env bash
# SVT-AV1 — Scalable Video Technology AV1 encoder; FFmpeg --enable-libsvtav1.
# FFmpeg 8.1.1 requires SvtAv1Enc >= 0.9.0; v4.1.0 satisfies this.
# Tarball fetched from GitLab archive endpoint.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="4.1.0"
SRC="${SRCROOT}/svtav1"

fetch_tar "https://gitlab.com/AOMediaCodec/SVT-AV1/-/archive/v${VER}/SVT-AV1-v${VER}.tar.gz" "${SRC}"
mkdir -p "${SRC}/build"
cd "${SRC}/build"
cmake .. \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DBUILD_TESTING=OFF \
  -DBUILD_APPS=OFF
make -j"${JOBS}"
make install
ldconfig

verify_pc SvtAv1Enc
cleanup "${SRC}"
