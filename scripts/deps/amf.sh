#!/usr/bin/env bash
# AMF (AMD Advanced Media Framework) headers for FFmpeg --enable-amf.
# Header-only: FFmpeg dlopen()s libamfrt at runtime; no AMD driver needed at build time.
# FFmpeg's configure checks for <AMF/core/Version.h>, so headers MUST land at
# ${PREFIX}/include/AMF/ (AMF/core/ and AMF/components/ under an include dir).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v1.5.2"
SRC="${SRCROOT}/AMF"

fetch_git https://github.com/GPUOpen-LibrariesAndSDKs/AMF.git "${VER}" "${SRC}"

mkdir -p "${PREFIX}/include/AMF"
# Copy the CONTENTS of amf/public/include into ${PREFIX}/include/AMF.
cp -a "${SRC}/amf/public/include/." "${PREFIX}/include/AMF/"
ldconfig

# Sanity: the exact header FFmpeg configure looks for (header-only -> no .pc to verify_pc).
test -f "${PREFIX}/include/AMF/core/Version.h"

cleanup "${SRC}"
