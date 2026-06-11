#!/usr/bin/env bash
# libplacebo (VideoLAN) for FFmpeg --enable-libplacebo (the vf_libplacebo filter + ffplay
# vulkan renderer). Built from source so the API matches FFmpeg 8.1.1.
#
# MUST run AFTER vulkan-headers.sh: the vulkan backend needs the newer Vulkan-Headers in
# /usr/local and the shadowing vulkan.pc that vulkan-headers.sh installs.
#
# --recursive is REQUIRED: libplacebo vendors the `glad` GL/Vulkan loader as a git submodule;
# without it meson setup fails on the missing 3rdparty/glad source.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

# v7.349.0 satisfies FFmpeg 8.1.1's requirement (configure wants libplacebo >= 5.229.0). The
# HAVE_AV_CONFIG_H header bug below is independent of the version (present through latest 7.360.x).
VER="v7.349.0"
SRC="${SRCROOT}/placebo"

fetch_git https://code.videolan.org/videolan/libplacebo.git "${VER}" "${SRC}" --recursive

# FFmpeg's own build defines HAVE_AV_CONFIG_H, under which <libavformat/avformat.h> includes only
# version_major.h (NOT version.h), so LIBAVFORMAT_VERSION_INT is left undefined. libplacebo's
# utils/libav_internal.h gates its stream side-data API on that macro; undefined -> it falls back
# to the pre-7.0 av_stream_get_side_data() (removed in FFmpeg 8.x), so FFmpeg's vf_libplacebo.c
# fails to compile ("implicit declaration of av_stream_get_side_data"). Force the full version
# header into libplacebo's public libav.h so the gate sees the real libavformat version. This is a
# source fix applied before build (not a post-hoc binary edit); the bug is present in every
# libplacebo release incl. latest, and the extra include is harmless to external users (version.h
# is include-guarded).
LIBAV_H="${SRC}/src/include/libplacebo/utils/libav.h"
[ -f "${LIBAV_H}" ] || { echo "ERROR: ${LIBAV_H} not found"; exit 1; }
sed -i 's@#include <libavformat/avformat.h>@#include <libavformat/avformat.h>\n#include <libavformat/version.h>@' "${LIBAV_H}"
grep -q '#include <libavformat/version.h>' "${LIBAV_H}" || { echo "ERROR: libplacebo libav.h version.h patch failed"; exit 1; }

meson setup "${SRC}/build" "${SRC}" \
  --buildtype release \
  --prefix="${PREFIX}" \
  -Dvulkan=enabled \
  -Dshaderc=enabled \
  -Dlcms=enabled \
  -Dglslang=disabled \
  -Ddemos=false \
  -Dtests=false
ninja -C "${SRC}/build" -j"${JOBS}" install
ldconfig

verify_pc libplacebo
cleanup "${SRC}"
