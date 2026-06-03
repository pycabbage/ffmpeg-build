#!/usr/bin/env bash
# librist — Reliable Internet Stream Transport library. FFmpeg --enable-librist.
# Meson build. Provides librist.pc. Must run after gnutls (used as crypto backend).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v0.2.11"
SRC="${SRCROOT}/librist"

fetch_git "https://code.videolan.org/rist/librist.git" "${VER}" "${SRC}"
cd "${SRC}"
# Crypto backend = GnuTLS (project standard): librist defaults to use_mbedtls=true (builds a
# bundled mbedtls), so force it off and select gnutls, which pulls nettle+hogweed+gnutls
# (all built earlier in the TLS phase; nettle's --libdir=lib fix makes nettle.pc/hogweed.pc
# resolvable). builtin_cjson=true uses librist's bundled cJSON since we do not ship libcjson.
# (The previous -Dhave_cjson=false was rejected: the real option name is builtin_cjson.)
meson setup build \
  --prefix="${PREFIX}" \
  --buildtype=release \
  --default-library=shared \
  -Dtest=false \
  -Dbuilt_tools=false \
  -Dbuiltin_cjson=true \
  -Duse_mbedtls=false \
  -Duse_gnutls=true
ninja -C build -j"${JOBS}"
ninja -C build install
ldconfig

verify_pc librist
cleanup "${SRC}"
