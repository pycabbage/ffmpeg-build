#!/usr/bin/env bash
# sndio — OpenBSD audio/MIDI framework ported to Linux; installs libsndio.so + sndio.h.
# FFmpeg --enable-sndio. Uses a custom non-autotools ./configure; ships no .pc file.
# NOTE custom configure: no --enable-shared/--disable-static flags; shared lib is the default.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.10.0"
SRC="${SRCROOT}/sndio"

fetch_tar "https://sndio.org/sndio-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
# sndio's configure accepts --prefix and --enable-alsa but NOT standard autotools flags.
./configure --prefix="${PREFIX}" --enable-alsa
make -j"${JOBS}"
make install
ldconfig

# No .pc shipped; verify the shared lib and header are present.
test -f "${PREFIX}/lib/libsndio.so" || die "libsndio.so not found"
test -f "${PREFIX}/include/sndio.h"  || die "sndio.h not found"
cleanup "${SRC}"
