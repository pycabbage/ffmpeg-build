#!/usr/bin/env bash
# common.sh — shared conventions + helpers sourced by every scripts/deps/<lib>.sh.
#
# The full-build flow compiles EVERYTHING from source: the toolchain (gcc + binutils and
# their deps gmp/mpfr/mpc/isl), the build tools (cmake/ninja/meson/nasm/yasm/autotools/
# python and their deps), and every media library FFmpeg links. The only things taken from
# the ubuntu:24.04 base are the OS floor (kernel, glibc, bash/coreutils) and a throwaway
# bootstrap *seed* compiler used solely to compile our from-source gcc (a compiler cannot
# compile itself from nothing — even Linux From Scratch bootstraps off the host toolchain).
#
# ---------------------------------------------------------------------------------------
# RPATH / patchelf elimination (THE central design point)
# ---------------------------------------------------------------------------------------
# The OLD flow ran `patchelf --set-rpath '$ORIGIN'` AFTER the build to make the bundle
# relocatable. That post-hoc binary rewriting is the "侵害" (invasive tampering) the
# 001-full-build task removes. We replace it with a relocatable RPATH baked at LINK time.
#
# Mechanism: the LD_RUN_PATH environment variable. `ld` reads it and, when a link specifies no
# explicit -rpath, stores its value verbatim as the binary's RPATH. We export it (below) as the
# literal string `$ORIGIN:$ORIGIN/../lib:$ORIGIN/lib`, so EVERY executable and shared library
# linked under this environment becomes relocatable with NO post-processing and NO per-recipe
# flags. As an env var it is immune to the make `$(...)`/shell `$O`->'' expansion traps that
# make threading `-Wl,-rpath,$ORIGIN` through LDFLAGS unreliable.
#
# We deliberately do NOT use a gcc `specs` file for this: installing a default specs file makes
# gcc stop emitting its built-in `--eh-frame-hdr` (dropping PT_GNU_EH_FRAME -> C++ exception
# unwinding silently breaks) and disturbs libgcc_s auto-linking. LD_RUN_PATH leaves gcc's
# built-in link behaviour completely intact. (Both failure modes were observed + verified.)
#
# OLD dtags (DT_RPATH), not DT_RUNPATH: scripts/deps/binutils.sh builds ld with
# `--disable-new-dtags` so LD_RUN_PATH yields DT_RPATH. DT_RPATH on the executable PROPAGATES to
# transitively-loaded libraries; DT_RUNPATH does not. That propagation covers libstdc++.so.6 /
# libgcc_s.so.1 (built during gcc, carrying no rpath of their own). The three entries cover
# every layout: sibling libs = $ORIGIN; the installed bin/->lib tree = $ORIGIN/../lib; the flat
# bundle `ffmpeg + lib/` = $ORIGIN/lib.
#
# Consequence: individual dependency scripts set NO rpath flags. build-ffmpeg.sh re-verifies
# with `readelf -d` that each shipped ffmpeg/ffprobe/ffplay binary carries an $ORIGIN DT_RPATH
# and FAILS LOUDLY otherwise — fixed at the recipe/toolchain level, never via patchelf.
set -euxo pipefail

# Install prefix for every source-built component. Listed first on all search paths so our
# from-source libs always win over anything the base image happens to provide.
: "${PREFIX:=/usr/local}"
: "${JOBS:=$(nproc)}"
: "${SRCROOT:=/tmp/src}"

export PATH="${PREFIX}/bin:${PATH}"
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PREFIX}/lib/x86_64-linux-gnu/pkgconfig:${PREFIX}/share/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"
# Build-time loader visibility for the in-image libs (the SHIPPED artifact relies on the
# baked $ORIGIN DT_RPATH instead, not on this).
# lib64 too: our from-source gcc installs libstdc++.so/libgcc_s.so under ${PREFIX}/lib64.
export LD_LIBRARY_PATH="${PREFIX}/lib:${PREFIX}/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
# Many autotools projects honour these; cmake/meson read the toolchain directly.
export CPPFLAGS="-I${PREFIX}/include${CPPFLAGS:+ ${CPPFLAGS}}"
export LDFLAGS="-L${PREFIX}/lib${LDFLAGS:+ ${LDFLAGS}}"

# THE relocatable-RPATH mechanism (see the header note). `ld` bakes this literal value as the
# binary's RPATH when the link has no explicit -rpath of its own. Single-quoted so `$ORIGIN`
# stays literal. With binutils built --disable-new-dtags this becomes DT_RPATH (old dtags),
# which propagates to transitive deps. Build-system-agnostic and free of make/shell $ traps.
export LD_RUN_PATH='$ORIGIN:$ORIGIN/../lib:$ORIGIN/lib'

log()  { echo "==== $* ===="; }
die()  { echo "ERROR: $*" >&2; exit 1; }

# fetch_git <url> <ref> <dest> [extra git-clone args...]
# Shallow-clones a tag/branch. Extra args allow e.g. --recursive for submodule vendors.
fetch_git() {
  local url="$1" ref="$2" dest="$3"; shift 3
  rm -rf "${dest}"
  git clone --depth 1 --branch "${ref}" "$@" "${url}" "${dest}"
}

# fetch_tar <url> <dest> [sha256]
# Downloads a release tarball (retrying), optionally verifies its sha256, then extracts it
# into <dest> stripping the leading top-level directory. Handles .gz/.xz/.bz2/.zst via tar -a.
fetch_tar() {
  local url="$1" dest="$2" sha="${3:-}"
  local tmp; tmp="$(mktemp /tmp/src.XXXXXX.tar)"
  curl -fSL --connect-timeout 30 --retry 5 --retry-delay 3 -o "${tmp}" "${url}"
  if [ -n "${sha}" ]; then
    echo "${sha}  ${tmp}" | sha256sum -c - || die "checksum mismatch for ${url}"
  fi
  rm -rf "${dest}"; mkdir -p "${dest}"
  tar -xf "${tmp}" -C "${dest}" --strip-components=1
  rm -f "${tmp}"
}

# verify_pc <pkg> [pkg...]  — assert each is discoverable via pkg-config (post-install sanity).
verify_pc() { pkg-config --exists --print-errors "$@"; pkg-config --modversion "$@" || true; }

# cleanup <dir...> — remove source/build trees to keep image layers small.
cleanup() { rm -rf "$@"; }
