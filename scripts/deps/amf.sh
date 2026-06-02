#!/usr/bin/env bash
# AMF (AMD Advanced Media Framework) headers for FFmpeg --enable-amf.
# Header-only: FFmpeg dlopen()s libamfrt at runtime; no AMD driver needed at build time.
# FFmpeg's configure checks for <AMF/core/Version.h>, so headers MUST land at
# /usr/local/include/AMF/ (AMF/core/ and AMF/components/ under an include dir).
set -euxo pipefail

VER="v1.5.2"
SRC="/tmp/AMF"

git clone --depth 1 --branch "${VER}" \
  https://github.com/GPUOpen-LibrariesAndSDKs/AMF.git "${SRC}"

mkdir -p /usr/local/include/AMF
# Copy the CONTENTS of amf/public/include into /usr/local/include/AMF.
cp -a "${SRC}/amf/public/include/." /usr/local/include/AMF/
ldconfig

# Sanity: the exact header FFmpeg configure looks for.
test -f /usr/local/include/AMF/core/Version.h

rm -rf "${SRC}"
