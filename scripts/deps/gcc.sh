#!/usr/bin/env bash
# gcc — our from-source C/C++ compiler. THE pivotal layer of the full-build:
#
#  1. It is built by the throwaway bootstrap seed compiler, against our own from-source
#     binutils + gmp/mpfr/mpc/isl + zlib/zstd, and installed into the prefix. With
#     /usr/local/bin first on PATH, every later layer (build tools + all media libs) and the
#     FFmpeg compile itself are driven by THIS gcc — not the seed and not anything from apt.
#
#  2. After install it writes the $ORIGIN RPATH `specs` file (common.sh:ORIGIN_SPECS) into
#     gcc's private directory. gcc auto-reads a file named `specs` there, so from now on EVERY
#     non-static link gcc performs bakes a relocatable OLD-style DT_RPATH ($ORIGIN:$ORIGIN/../lib:
#     $ORIGIN/lib) into the output — executables AND shared libraries. DT_RPATH (not DT_RUNPATH)
#     is required: it propagates to transitively-loaded libs (libstdc++ -> libgcc_s). THIS is what
#     makes the shipped FFmpeg bundle relocatable WITHOUT patchelf. Injection happens inside the
#     gcc driver, after make/shell variable expansion, so the literal `$ORIGIN` is never mangled.
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

# --- install the relocatable-RPATH specs so OUR gcc bakes $ORIGIN into every link ----------
SPECDIR="$(dirname "$("${PREFIX}/bin/gcc" -print-libgcc-file-name)")"
printf '%s\n' "${ORIGIN_SPECS}" > "${SPECDIR}/specs"
echo "installed RPATH specs -> ${SPECDIR}/specs"

# --- prove the toolchain is correct: $ORIGIN DT_RPATH baked AND C++ exceptions actually work --
# Two invariants the specs must preserve (both have bitten this build):
#   1. every non-static link gets an $ORIGIN DT_RPATH (old dtags) — patchelf-free relocation.
#   2. C++ exception unwinding still works. Installing a default specs file makes gcc STOP
#      emitting its built-in --eh-frame-hdr, dropping PT_GNU_EH_FRAME so `catch` is bypassed
#      (std::terminate/abort). common.sh:ORIGIN_SPECS re-adds --eh-frame-hdr; we verify by
#      actually COMPILING + RUNNING a throw/catch (a C-only check would not catch this).
hash -r
T="$(mktemp -d)"
echo 'int main(void){return 0;}' > "${T}/t.c"
"${PREFIX}/bin/gcc" -o "${T}/t" "${T}/t.c"
readelf -d "${T}/t" | grep '(RPATH)' | grep -q '\$ORIGIN' \
  || die "gcc specs did not bake an \$ORIGIN DT_RPATH (old dtags) — patchelf-free relocation would break"
printf 'int main(){try{throw 1;}catch(...){return 0;}return 3;}\n' > "${T}/e.cpp"
"${PREFIX}/bin/g++" -O2 -o "${T}/e" "${T}/e.cpp"
readelf -l "${T}/e" | grep -q 'GNU_EH_FRAME' \
  || die "g++ output lacks PT_GNU_EH_FRAME — C++ exception unwinding broken (specs dropped --eh-frame-hdr)"
"${T}/e" \
  || die "g++ C++ exception test aborted (catch bypassed) — broken C++ exception handling at runtime"
readelf -d "${T}/e" | grep '(RPATH)' | grep -q '\$ORIGIN' \
  || die "g++ output lacks an \$ORIGIN DT_RPATH"
echo "verified: $("${PREFIX}/bin/gcc" --version | head -1) bakes \$ORIGIN DT_RPATH and links+runs C++ exceptions"
rm -rf "${T}"

cleanup "${SRC}"
