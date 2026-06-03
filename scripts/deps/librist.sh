#!/usr/bin/env bash
# librist — Reliable Internet Stream Transport library. FFmpeg --enable-librist.
# Meson build. Provides librist.pc. Must run after gnutls (used as crypto backend).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v0.2.11"
SRC="${SRCROOT}/librist"

fetch_git "https://code.videolan.org/rist/librist.git" "${VER}" "${SRC}"
cd "${SRC}"
# Crypto backend = GnuTLS/nettle (project standard), NOT the default bundled mbedtls.
# librist v0.2.11 has an internal inconsistency: it compiles eap.c when
# have_srp = (mbedcrypto_lib_found or use_gnutls), but the public librist_config.h gates the SRP
# types on HAVE_SRP_SUPPORT = (mbedcrypto_lib_found or use_NETTLE). With use_gnutls alone, eap.c
# is built but the SRP types are not defined -> "unknown type librist_verifier_lookup_data_t".
# So set BOTH use_gnutls and use_nettle to keep the two gates consistent (nettle+hogweed+gnutls
# were built in the TLS phase). builtin_cjson=true uses the bundled cJSON (we ship no libcjson).
meson setup build \
  --prefix="${PREFIX}" \
  --buildtype=release \
  --default-library=shared \
  -Dtest=false \
  -Dbuilt_tools=false \
  -Dbuiltin_cjson=true \
  -Duse_mbedtls=false \
  -Duse_gnutls=true \
  -Duse_nettle=true
ninja -C build -j"${JOBS}"
ninja -C build install
ldconfig

verify_pc librist
cleanup "${SRC}"
