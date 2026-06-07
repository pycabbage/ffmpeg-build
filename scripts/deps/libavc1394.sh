#!/usr/bin/env bash
# libavc1394 — FireWire AV/C protocol lib; its tarball ALSO bundles librom1394 (CSR/ROM reading),
# so one build yields both libavc1394.so + librom1394.so — exactly the -lavc1394 -lrom1394 that
# FFmpeg's --enable-libiec61883 links (check_lib, no .pc). Needs libraw1394 (already built).
# Upstream 0.5.4 (the version carrying the librom1394/ subdir) is only on the Debian source mirror;
# the SourceForge project tops out at 0.5.3. autotools; the orig tarball ships ./configure.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="0.5.4"
SRC="${SRCROOT}/libavc1394"

fetch_tar "https://deb.debian.org/debian/pool/main/liba/libavc1394/libavc1394_${VER}.orig.tar.gz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --enable-shared --disable-static
make -j"${JOBS}"
make install
ldconfig

# FFmpeg links -lavc1394 and -lrom1394 directly; make sure both shared libs landed.
test -f "${PREFIX}/lib/libavc1394.so" && test -f "${PREFIX}/lib/librom1394.so" \
  || die "libavc1394/librom1394 shared libs not installed"
cleanup "${SRC}"
