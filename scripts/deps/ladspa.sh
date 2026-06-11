#!/usr/bin/env bash
# LADSPA SDK — Linux Audio Developer's Simple Plugin API; FFmpeg --enable-ladspa.
# Header-only install: only ladspa.h is needed at compile time. No shared lib, no .pc.
# Sanity check: verify the header landed at ${PREFIX}/include/ladspa.h.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.17"
SRC="${SRCROOT}/ladspa"

# HTTPS + a pinned sha256 (the SDK tarball is fetched over the network; verify its integrity).
fetch_tar "https://www.ladspa.org/download/ladspa_sdk_${VER}.tgz" "${SRC}" \
  "27d24f279e4b81bd17ecbdcc38e4c42991bb388826c0b200067ce0eb59d3da5b"
mkdir -p "${PREFIX}/include"
cp "${SRC}/src/ladspa.h" "${PREFIX}/include/ladspa.h"

test -f "${PREFIX}/include/ladspa.h"
log "ladspa.h installed at ${PREFIX}/include/ladspa.h"
cleanup "${SRC}"
