#!/usr/bin/env bash
# LADSPA SDK — Linux Audio Developer's Simple Plugin API; FFmpeg --enable-ladspa.
# Header-only install: only ladspa.h is needed at compile time. No shared lib, no .pc.
# Sanity check: verify the header landed at ${PREFIX}/include/ladspa.h.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.17"
SRC="${SRCROOT}/ladspa"

fetch_tar "http://www.ladspa.org/download/ladspa_sdk_${VER}.tgz" "${SRC}"
mkdir -p "${PREFIX}/include"
cp "${SRC}/src/ladspa.h" "${PREFIX}/include/ladspa.h"

test -f "${PREFIX}/include/ladspa.h"
log "ladspa.h installed at ${PREFIX}/include/ladspa.h"
cleanup "${SRC}"
