#!/usr/bin/env bash
# PulseAudio client (libpulse) for FFmpeg --enable-libpulse. We build only what libpulse needs
# and disable the daemon extras. libsndfile is a hard build dependency (built earlier).
#
# NOTE: this is one of the heaviest/most fragile from-source builds in the set (PulseAudio is a
# large meson project). If it proves brittle in CI, the pragmatic fix is to drop the three
# scripts pulse.sh/libsndfile.sh/flac.sh and remove --enable-libpulse from build-ffmpeg.sh.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="17.0"
SRC="${SRCROOT}/pulseaudio"

fetch_tar "https://freedesktop.org/software/pulseaudio/releases/pulseaudio-${VER}.tar.xz" "${SRC}"
meson setup "${SRC}/build" "${SRC}" \
  --buildtype release --prefix="${PREFIX}" \
  -Ddaemon=false -Ddoxygen=false -Dman=false -Dtests=false -Dgsettings=disabled \
  -Dbluez5=disabled -Djack=disabled -Dlirc=disabled -Dopenssl=disabled \
  -Davahi=disabled -Dasyncns=disabled -Dsystemd=disabled -Ddbus=disabled \
  -Dx11=disabled -Dudev=disabled -Dgtk=disabled -Dorc=disabled -Dwebrtc-aec=disabled
ninja -C "${SRC}/build"
ninja -C "${SRC}/build" install
ldconfig

verify_pc libpulse
cleanup "${SRC}"
