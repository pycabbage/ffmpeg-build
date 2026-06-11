#!/usr/bin/env bash
# gcc — our from-source C/C++ compiler. THE pivotal layer of the full-build:
#
#  1. It is built by the throwaway bootstrap seed compiler, against our own from-source
#     binutils + gmp/mpfr/mpc/isl + zlib/zstd, and installed into the prefix. With
#     /usr/local/bin first on PATH, every later layer (build tools + all media libs) and the
#     FFmpeg compile itself are driven by THIS gcc — not the seed and not anything from apt.
#
#  2. Relocatability (the patchelf replacement) is NOT done with a gcc `specs` file: a default
#     specs file silently breaks gcc's built-in --eh-frame-hdr (PT_GNU_EH_FRAME -> C++ exception
#     unwinding) and libgcc_s auto-linking. Instead common.sh exports LD_RUN_PATH=$ORIGIN:... ,
#     which our --disable-new-dtags ld (scripts/deps/binutils.sh) bakes as a relocatable OLD-style
#     DT_RPATH into every executable + shared library. DT_RPATH (not DT_RUNPATH) propagates to
#     transitively-loaded libs (libstdc++ -> libgcc_s), making the bundle relocatable WITHOUT
#     patchelf. This script only VERIFIES it (below).
#
# Single-stage (--disable-bootstrap): the seed compiler is trusted here and a 3-stage bootstrap
# would roughly triple build time for no benefit to a build-only toolchain.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="14.2.0"
SRC="${SRCROOT}/gcc"

fetch_tar "https://ftp.gnu.org/gnu/gcc/gcc-${VER}/gcc-${VER}.tar.xz" "${SRC}"
mkdir -p "${SRC}/build"
cd "${SRC}/build"
../configure \
  --prefix="${PREFIX}" \
  --enable-languages=c,c++ \
  --disable-multilib \
  --disable-bootstrap \
  --enable-shared --enable-threads=posix --enable-__cxa_atexit \
  --enable-default-pie \
  --with-system-zlib \
  --with-gmp="${PREFIX}" --with-mpfr="${PREFIX}" --with-mpc="${PREFIX}" --with-isl="${PREFIX}" \
  --disable-werror --disable-nls
make -j"${JOBS}"
make install
ldconfig

# --- prove the toolchain is correct: $ORIGIN DT_RPATH baked AND C++ exceptions actually work --
# Relocatability is injected via LD_RUN_PATH (common.sh) baked by our --disable-new-dtags ld as
# DT_RPATH — NOT a gcc `specs` file (a default specs file silently breaks gcc's built-in
# --eh-frame-hdr and libgcc_s auto-linking). Two invariants to verify (both have bitten this
# build):
#   1. every non-static link gets an $ORIGIN DT_RPATH (old dtags) — patchelf-free relocation.
#   2. C++ exception unwinding works end-to-end. A C-only check misses it, so we COMPILE + RUN
#      a throw/catch and require a PT_GNU_EH_FRAME segment.
hash -r
T="$(mktemp -d)"
echo 'int main(void){return 0;}' > "${T}/t.c"
"${PREFIX}/bin/gcc" -o "${T}/t" "${T}/t.c"
readelf -d "${T}/t" | grep '(RPATH)' | grep -q '\$ORIGIN' \
  || die "no \$ORIGIN DT_RPATH baked (expected via LD_RUN_PATH + --disable-new-dtags ld) — relocation would break"
printf 'int main(){try{throw 1;}catch(...){return 0;}return 3;}\n' > "${T}/e.cpp"
"${PREFIX}/bin/g++" -O2 -o "${T}/e" "${T}/e.cpp"
readelf -l "${T}/e" | grep -q 'GNU_EH_FRAME' \
  || die "g++ output lacks PT_GNU_EH_FRAME — C++ exception unwinding is broken"
"${T}/e" \
  || die "g++ C++ exception test aborted (catch bypassed) — broken C++ exception handling at runtime"
readelf -d "${T}/e" | grep '(RPATH)' | grep -q '\$ORIGIN' \
  || die "g++ output lacks an \$ORIGIN DT_RPATH"
echo "verified: $("${PREFIX}/bin/gcc" --version | head -1) bakes \$ORIGIN DT_RPATH and links+runs C++ exceptions"
rm -rf "${T}"

cleanup "${SRC}"
