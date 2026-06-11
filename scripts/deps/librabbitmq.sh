#!/usr/bin/env bash
# rabbitmq-c (librabbitmq) — AMQP 0-9-1 client; FFmpeg --enable-librabbitmq (amqp:// protocol;
# pkg-config: librabbitmq). SSL via our from-source OpenSSL in /usr/local (enables amqps://).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="0.15.0"
SRC="${SRCROOT}/rabbitmq-c"

fetch_git "https://github.com/alanxz/rabbitmq-c" "v${VER}" "${SRC}"
mkdir -p "${SRC}/build"
cd "${SRC}/build"
cmake .. \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DBUILD_STATIC_LIBS=OFF \
  -DBUILD_EXAMPLES=OFF \
  -DBUILD_TOOLS=OFF \
  -DBUILD_TESTING=OFF \
  -DENABLE_SSL_SUPPORT=ON
make -j"${JOBS}"
make install
ldconfig

verify_pc librabbitmq
cleanup "${SRC}"
