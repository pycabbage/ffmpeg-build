#!/usr/bin/env bash
# v4l-utils — Video4Linux utilities + libv4l2; provides libv4l2.so.
# FFmpeg --enable-libv4l2. We build only the libraries (disable utils/programs/plugins/wrappers)
# to avoid pulling in Qt5 and other heavy GUI tool dependencies.
# NOTE: large project (meson); -Dv4l-utils=false skips the CLI utility programs.
#       -Dqv4l2=disabled -Dqvidcap=disabled avoids Qt5 dependency entirely.
#       -Dgconv=disabled avoids glibc iconv module build (requires specific gconv dirs).
#       libv4l2.pc IS shipped (installed to the multiarch pkgconfig dir); verify via pkg-config
#       just like FFmpeg's --enable-libv4l2 (require_pkg_config libv4l2).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v4l-utils-1.32.0"
SRC="${SRCROOT}/v4l-utils"

# linuxtv.org downloads are flaky (503); fetch from the gjasny GitHub mirror archive instead.
fetch_tar "https://github.com/gjasny/v4l-utils/archive/refs/tags/${VER}.tar.gz" "${SRC}"
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

# Verify libv4l2.pc via pkg-config (it lands in the multiarch pkgconfig dir, on PKG_CONFIG_PATH).
# This matches what FFmpeg's --enable-libv4l2 requires; the old `test -f ${PREFIX}/lib/libv4l2.so`
# checked the wrong path (meson installs to ${PREFIX}/lib/x86_64-linux-gnu).
verify_pc libv4l2
cleanup "${SRC}"
