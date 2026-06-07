#!/usr/bin/env bash
# quirc — QR code DECODER; FFmpeg --enable-libquirc (qrdecode filter). FFmpeg detects it with
# check_lib (quirc.h + -lquirc), there is NO .pc. Plain Makefile: build only the shared lib (the
# bundled qrtest/demo/scanner targets pull jpeg/png/SDL we don't need), then install by hand.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.2"
SRC="${SRCROOT}/quirc"

fetch_git "https://github.com/dlbeer/quirc" "v${VER}" "${SRC}"
cd "${SRC}"
make -j"${JOBS}" libquirc.so          # builds libquirc.so.${VER}
install -m755 "libquirc.so.${VER}" "${PREFIX}/lib/"
ln -sf "libquirc.so.${VER}" "${PREFIX}/lib/libquirc.so"
ln -sf "libquirc.so.${VER}" "${PREFIX}/lib/libquirc.so.1"
install -m644 lib/quirc.h "${PREFIX}/include/quirc.h"
ldconfig

[ -e "${PREFIX}/lib/libquirc.so" ] && [ -e "${PREFIX}/include/quirc.h" ] || die "quirc install incomplete"
cleanup "${SRC}"
