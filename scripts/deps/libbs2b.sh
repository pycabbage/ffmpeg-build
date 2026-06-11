#!/usr/bin/env bash
# libbs2b — Bauer stereophonic-to-binaural DSP library; FFmpeg --enable-libbs2b.
# Autotools build from SourceForge tarball; produces libbs2b.pc.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="3.1.0"
SRC="${SRCROOT}/libbs2b"

fetch_tar "https://downloads.sourceforge.net/bs2b/libbs2b-${VER}.tar.bz2" "${SRC}"
cd "${SRC}"

# libbs2b's configure does PKG_CHECK_EXISTS([sndfile]) and hard-errors if absent, but libsndfile
# is ONLY used by its CLI tools (bs2bconvert/bs2bstream) — the libbs2b library FFmpeg links has no
# sndfile dependency, and we intentionally do not ship libsndfile. Satisfy the bare existence
# check with a throwaway sndfile.pc on a private PKG_CONFIG_PATH (scoped to this subshell), then
# build/install ONLY the library by overriding bin_PROGRAMS= so the sndfile-using tools are skipped.
FAKE_PCDIR="$(mktemp -d)"
cat > "${FAKE_PCDIR}/sndfile.pc" <<'EOF'
Name: sndfile
Description: stub to satisfy libbs2b's configure existence check (tools are not built)
Version: 1.0.31
Libs:
Cflags:
EOF
export PKG_CONFIG_PATH="${FAKE_PCDIR}:${PKG_CONFIG_PATH}"

./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static
make -j"${JOBS}" bin_PROGRAMS=
make install bin_PROGRAMS=
ldconfig
rm -rf "${FAKE_PCDIR}"

verify_pc libbs2b
cleanup "${SRC}"
