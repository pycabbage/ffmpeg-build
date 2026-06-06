#!/usr/bin/env bash
# libvdpau — Video Decode and Presentation API for Unix (NVIDIA); provides vdpau.pc.
# FFmpeg --enable-vdpau. The loader only; actual driver is host-provided at runtime.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.5"
SRC="${SRCROOT}/libvdpau"

# gitlab.freedesktop.org's Gitaly git backend intermittently returns HTTP 503 ("git server not
# available"). It is the only upstream for libvdpau, so retry the clone a few times before giving
# up rather than failing the whole image build on a transient outage.
ok=0
for attempt in 1 2 3 4 5; do
  if fetch_git "https://gitlab.freedesktop.org/vdpau/libvdpau.git" "${VER}" "${SRC}"; then
    ok=1; break
  fi
  echo "libvdpau: clone attempt ${attempt}/5 failed (gitlab.freedesktop.org 503?); retrying in $((attempt*15))s" >&2
  sleep "$((attempt * 15))"
done
[ "${ok}" = 1 ] || die "libvdpau: clone failed after 5 attempts (gitlab.freedesktop.org unavailable)"
meson setup "${SRC}/build" "${SRC}" \
  --prefix="${PREFIX}" \
  --buildtype=release \
  --default-library=shared \
  -Ddocumentation=false
ninja -C "${SRC}/build" -j"${JOBS}"
ninja -C "${SRC}/build" install
ldconfig

verify_pc vdpau
cleanup "${SRC}"
