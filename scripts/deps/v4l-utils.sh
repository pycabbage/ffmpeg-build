#!/usr/bin/env bash
# v4l-utils — Video4Linux utilities + libv4l2; provides libv4l2.so.
# FFmpeg --enable-libv4l2. We build only the libraries (disable utils/programs/plugins/wrappers)
# to avoid pulling in Qt5 and other heavy GUI tool dependencies.
# NOTE: large project (meson); -Dv4l-utils=false skips the CLI utility programs.
#       -Dqv4l2=disabled -Dqvidcap=disabled avoids Qt5 dependency entirely.
#       -Dgconv=disabled avoids glibc iconv module build (requires specific gconv dirs).
#       No .pc is shipped for libv4l2 upstream; sanity-test via -f.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v4l-utils-1.32.0"
SRC="${SRCROOT}/v4l-utils"

fetch_tar "https://www.linuxtv.org/downloads/v4l-utils/v4l-utils-1.32.0.tar.xz" "${SRC}"
meson setup "${SRC}/build" "${SRC}" \
  --prefix="${PREFIX}" \
  --buildtype=release \
  --default-library=shared \
  -Dv4l-utils=false \
  -Dv4l-plugins=false \
  -Dv4l-wrappers=false \
  -Dqv4l2=disabled \
  -Dqvidcap=disabled \
  -Dgconv=disabled \
  -Dlibdvbv5=disabled \
  -Dv4l2-tracer=disabled \
  -Ddoxygen-doc=disabled
ninja -C "${SRC}/build" -j"${JOBS}"
ninja -C "${SRC}/build" install
ldconfig

# No .pc for libv4l2; verify the shared lib is present.
test -f "${PREFIX}/lib/libv4l/libv4l2.so" || \
  test -f "${PREFIX}/lib/libv4l2.so" || \
  die "libv4l2.so not found under ${PREFIX}/lib"
cleanup "${SRC}"
