#!/usr/bin/env bash
# libzvbi — VBI / teletext / closed-caption decoding; FFmpeg --enable-libzvbi (pkg-config: zvbi-0.2).
# git source needs ./autogen.sh (it forwards args to ./configure). Build only src/ (the lib) — the
# test/contrib programs pull X/SDL we don't want; install the generated zvbi-0.2.pc by hand.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="0.2.44"
SRC="${SRCROOT}/zvbi"

fetch_git "https://github.com/zapping-vbi/zvbi" "v${VER}" "${SRC}"
cd "${SRC}"
./autogen.sh --prefix="${PREFIX}" --enable-shared --disable-static
make -j"${JOBS}" -C src
make -C src install
install -m644 zvbi-0.2.pc "${PREFIX}/lib/pkgconfig/"
ldconfig

verify_pc zvbi-0.2
cleanup "${SRC}"
