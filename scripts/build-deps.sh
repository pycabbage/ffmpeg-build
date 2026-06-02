#!/usr/bin/env bash
# build-deps.sh — convenience driver that runs every source-lib build script in order.
#
# NOTE: The Dockerfile does NOT call this script. For layer cacheability and so that a
# failure in one library does not invalidate the others, the Dockerfile runs each
# scripts/deps/<lib>.sh in its OWN RUN layer. This driver exists for local/manual builds
# and as living documentation of the source-built set and its ordering.
#
# Libraries built from source (NOT available, or not adequate, via Ubuntu 24.04 apt):
#   nv-codec-headers  - NVENC/NVDEC/CUVID/ffnvcodec/cuda-llvm headers (no apt pkg)
#   amf               - AMD AMF headers (no apt pkg)
#   vvenc             - H.266/VVC encoder (no reliable apt pkg)
#   xeve              - MPEG-5 EVC encoder (no apt pkg)
#   xevd              - MPEG-5 EVC decoder (no apt pkg)
#   uavs3d            - AVS3 decoder (no apt pkg)
#   xavs2             - AVS2 encoder, GPL (no apt pkg)
#   davs2             - AVS2 decoder, GPL (no apt pkg)
#   libaribcaption    - ARIB STD-B24 caption renderer (no apt pkg)
#   libvmaf           - Netflix VMAF (NO libvmaf-dev in 24.04 -> source required)
#   rav1e             - Rust AV1 encoder (NO apt pkg -> source required)
#
# Everything else (x264, x265, vpx, aom, dav1d, svt-av1, opus, vorbis, lame, fdk-aac,
# libass, freetype, fontconfig, harfbuzz, etc.) is installed via apt -dev packages.
set -euxo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPS="${HERE}/deps"

for lib in \
  nv-codec-headers \
  amf \
  vvenc \
  xeve \
  xevd \
  uavs3d \
  xavs2 \
  davs2 \
  libaribcaption \
  libvmaf \
  rav1e ; do
  echo "==== building ${lib} ===="
  bash "${DEPS}/${lib}.sh"
done

echo "All source dependencies built."
