#!/usr/bin/env bash
# librtmp — RTMP client library from rtmpdump. FFmpeg --enable-librtmp.
# No versioned releases; project lives at git.ffmpeg.org/rtmpdump. Build only the
# librtmp/ subdir with its Makefile. CRYPTO=GNUTLS links our gnutls instead of OpenSSL.
# SHARED=yes builds the .so alongside the .a.
# NOTE: librtmp Makefile uses INC/LIBS for crypto flags; pkg-config drives these for GNUTLS.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

COMMIT="6f6bb1353fc84f4cc37138baa99f586750028a01"
SRC="${SRCROOT}/rtmpdump"

fetch_git "https://git.ffmpeg.org/rtmpdump.git" "master" "${SRC}"
cd "${SRC}/librtmp"

# Derive GnuTLS compile/link flags from pkg-config so the Makefile CRYPTO override works.
GNUTLS_CFLAGS="$(pkg-config --cflags gnutls)"
GNUTLS_LIBS="$(pkg-config --libs gnutls)"

make -j"${JOBS}" \
  SYS=posix \
  CRYPTO=GNUTLS \
  SHARED=yes \
  prefix="${PREFIX}" \
  XCFLAGS="${GNUTLS_CFLAGS}" \
  XLIBS="${GNUTLS_LIBS}"

make install \
  SYS=posix \
  CRYPTO=GNUTLS \
  SHARED=yes \
  prefix="${PREFIX}" \
  XCFLAGS="${GNUTLS_CFLAGS}" \
  XLIBS="${GNUTLS_LIBS}"
ldconfig

verify_pc librtmp
cleanup "${SRC}"
