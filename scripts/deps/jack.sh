#!/usr/bin/env bash
# JACK (jack2 / libjack) for FFmpeg --enable-libjack. jack2 uses a waf (python) build system,
# driven by our from-source python. ALSA support comes from alsa-lib (built earlier).
#
# NOTE: waf builds are comparatively fragile. If this proves brittle in CI, drop jack.sh and
# remove --enable-libjack from build-ffmpeg.sh. (libjack only provides the JACK audio device.)
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v1.9.22"
SRC="${SRCROOT}/jack2"

fetch_git "https://github.com/jackaudio/jack2.git" "${VER}" "${SRC}"
cd "${SRC}"
python3 ./waf configure --prefix="${PREFIX}" --classic --autostart=none
python3 ./waf build -j"${JOBS}"
python3 ./waf install
ldconfig

verify_pc jack
cleanup "${SRC}"
