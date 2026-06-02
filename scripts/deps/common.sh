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
# Threading `-Wl,-rpath,$ORIGIN` through every project's LDFLAGS is unreliable: a literal
# `$ORIGIN` is mangled by make's `$(...)` expansion (`$O` -> empty, leaving `RIGIN`) and by
# the recipe shell. The robust, build-system-agnostic fix is to inject the rpath INSIDE the
# gcc driver, which runs AFTER make/shell expansion. Because we build gcc ourselves,
# scripts/deps/gcc.sh installs a `specs` file (see ORIGIN_SPECS below) into gcc's private
# directory so that EVERY non-static link gcc performs — for both executables and shared
# libraries — automatically gets:
#       DT_RPATH = $ORIGIN:$ORIGIN/../lib:$ORIGIN/lib   (OLD dtags, --disable-new-dtags)
# Verified: this lands the literal `$ORIGIN` even when the link goes through a Makefile.
#
# OLD dtags (DT_RPATH) — not DT_RUNPATH — is deliberate: DT_RPATH on the executable PROPAGATES
# to transitively-loaded libraries, whereas DT_RUNPATH does not. That propagation is what
# covers libstdc++.so.6 / libgcc_s.so.1, which gcc builds for itself BEFORE this specs file
# exists and which therefore carry no rpath of their own. (Both behaviours verified.)
#
# Consequence for THIS file: individual dependency scripts do NOT set any rpath flags. They
# build normally; our gcc makes their output relocatable for free. (The three rpath entries
# cover every layout: a lib resolving sibling libs in the same dir = $ORIGIN; the installed
# bin/->lib tree = $ORIGIN/../lib; the flat bundle `ffmpeg + lib/` = $ORIGIN/lib.)
#
# build-ffmpeg.sh re-verifies with `readelf -d` that each shipped ffmpeg/ffprobe/ffplay binary
# carries an $ORIGIN DT_RPATH and FAILS LOUDLY otherwise, so a binary that escapes the spec
# surfaces as a build error fixed at the recipe level — never via patchelf.
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

# The gcc `specs` snippet that bakes the relocatable DT_RPATH into every link. gcc.sh writes
# this verbatim into <gcc-private-dir>/specs so it is applied automatically (no -specs= flag,
# no LDFLAGS threading). `+` appends to gcc's built-in `*link` spec. $ORIGIN is literal here
# (gcc specs use % for substitution, not $), so it reaches the linker intact. --disable-new-dtags
# forces OLD-style DT_RPATH (propagates to transitive deps; see the header note above).
#
# --eh-frame-hdr is MANDATORY here: the mere presence of a default `specs` file makes gcc STOP
# emitting its built-in `--eh-frame-hdr`, which drops the PT_GNU_EH_FRAME segment and silently
# breaks C++ exception unwinding (catch is bypassed -> std::terminate -> abort). We restore it
# explicitly. (Verified: without it, `g++` C++ programs abort on any thrown+caught exception.)
read -r -d '' ORIGIN_SPECS <<'SPECS' || true
*link:
+ %{!static:%{!static-pie: --eh-frame-hdr -rpath=$ORIGIN -rpath=$ORIGIN/../lib -rpath=$ORIGIN/lib --disable-new-dtags}}
SPECS
export ORIGIN_SPECS

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
