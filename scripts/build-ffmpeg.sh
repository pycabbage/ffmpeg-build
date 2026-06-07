#!/usr/bin/env bash
# build-ffmpeg.sh — download, configure, build, install and verify FFmpeg.
#
# This script is the BUILD-IMAGE ENTRYPOINT: it runs at `docker run` time, NOT during
# `docker build`. The image contains NEITHER FFmpeg source NOR an FFmpeg binary; this
# script downloads the source itself and compiles it inside the running container.
#
# Every --enable-libX flag below maps to a library that IS present in the image
# (an apt -dev package, or a source build under scripts/deps). Flags whose provider
# is unavailable on Ubuntu 24.04 are intentionally OMITTED (see CLAUDE.md "Omitted libs").
#
# The build is the maximal GPL + version3 + nonfree variant. Because it links fdk-aac
# (nonfree) together with GPL libs, the resulting binary is NOT redistributable.
set -euxo pipefail

FFMPEG_VERSION="${FFMPEG_VERSION:-8.1.1}"
PREFIX="${PREFIX:-/usr/local}"
SRC="/tmp/ffmpeg-src"

# pkg-config must see /usr/local FIRST for the source-built libs.
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:${PKG_CONFIG_PATH:-}"
# Relocatable RPATH for the FFmpeg binaries + libav* .so: our --disable-new-dtags ld bakes
# LD_RUN_PATH as DT_RPATH at link time (no patchelf). Single-quoted so $ORIGIN stays literal.
export LD_RUN_PATH='$ORIGIN:$ORIGIN/../lib:$ORIGIN/lib'
# lib64 on the loader path so the in-image ffmpeg run (verification below) finds our
# libstdc++/libgcc_s, which gcc installs under /usr/local/lib64.
export LD_LIBRARY_PATH="/usr/local/lib:/usr/local/lib64:/usr/local/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

# ---- download + extract source --------------------------------------------
# The image does NOT bake FFmpeg source. We always download the requested release into a
# fresh working dir and extract it, then build there.
echo "Downloading ffmpeg-${FFMPEG_VERSION}.tar.xz ..."
TARBALL="/tmp/ffmpeg-${FFMPEG_VERSION}.tar.xz"
rm -rf "${SRC}"
mkdir -p "${SRC}"
curl -fSL --retry 5 --retry-delay 3 \
  -o "${TARBALL}" \
  "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz"
tar -xJf "${TARBALL}" -C "${SRC}" --strip-components=1
rm -f "${TARBALL}"
cd "${SRC}"
# ---- fix truncated dependency .pc version strings --------------------------
# The pkuvcl libs davs2 and xavs2 ship a build system that writes a TRUNCATED `Version:` field
# into their installed pkg-config files: e.g. `1.6.` and `1.3.` (a trailing dot, missing the
# patch component). FFmpeg's configure performs strict pkg-config version checks
# (`davs2 >= 1.6.0`, `xavs2 >= 1.3.0`) which a string like `1.6.` FAILS even though the INSTALLED
# library is the correct, new-enough upstream release (davs2 tag 1.7, xavs2 tag 1.4) that builds
# fine against FFmpeg 8.1.1. We normalise the malformed Version field in place to a value that
# satisfies the minimum. This is purely a metadata fix; the .so/.a and headers are unchanged.
# NOTE: uavs3d is intentionally NOT patched here -- its v1.1 release is a genuine API mismatch
# (missing seqh colour fields) and --enable-libuavs3d is dropped below, not version-faked.
fix_pc_version() {
  # $1 = .pc basename, $2 = corrected version
  local pc
  for dir in /usr/local/lib/pkgconfig /usr/local/lib/x86_64-linux-gnu/pkgconfig; do
    pc="${dir}/$1.pc"
    if [ -f "${pc}" ]; then
      sed -i -E "s/^Version:.*/Version: $2/" "${pc}"
      echo "patched ${pc} -> Version: $2"
    fi
  done
}
fix_pc_version davs2  1.7.0
fix_pc_version xavs2  1.4.0


# ---- configure -------------------------------------------------------------
# Flag groups mirror the research spec. Each flag has a verified provider in the image.
# NOTE: --pkg-config-flags="--static" is intentionally NOT passed: this is a SHARED build
# and forcing static pkg-config resolution can break shared-dependency linking.
#
# The full list of desired --enable-* flags. libpostproc is built automatically and has NO
# configure flag, so it is deliberately absent here.
ENABLE_FLAGS=(
  --enable-gpl
  --enable-version3
  --enable-nonfree
  --enable-shared
  --enable-pic
  --enable-pthreads
  --enable-network
  --enable-gnutls
  --enable-iconv
  --enable-zlib
  --enable-bzlib
  --enable-lzma
  --enable-libxml2
  --enable-libsnappy
  --enable-gmp
  --enable-runtime-cpudetect
  --enable-libx264
  --enable-libx265
  --enable-libxvid
  --enable-libvpx
  --enable-libaom
  --enable-libdav1d
  --enable-libsvtav1
  --enable-librav1e
  --enable-libtheora
  --enable-libopenh264
  --enable-libvvenc
  --enable-libxeve
  --enable-libxevd
  # --enable-libuavs3d  # DROPPED: the image's uavs3d (upstream tag v1.1) is older than the
  # 1.1.41 API FFmpeg 8.1.1 needs. ffmpeg's libavcodec/libuavs3d.c references seqh fields
  # colour_primaries / transfer_characteristics / matrix_coefficients / colour_description that
  # do NOT exist in this struct uavs3d_com_seqh_t -> compile error. No Ubuntu 24.04 / installed
  # uavs3d provides the newer API, so genuinely unsupported here. (The earlier davs2/xavs2 .pc
  # version normalisation is unrelated and retained; those libs are new enough and DO compile.)
  --enable-libxavs2
  --enable-libdavs2
  --enable-libwebp
  --enable-libopenjpeg
  --enable-libmp3lame
  --enable-libopus
  --enable-libvorbis
  --enable-libfdk-aac
  --enable-libtwolame
  --enable-libgsm
  --enable-libspeex
  --enable-libopencore-amrnb
  --enable-libopencore-amrwb
  --enable-libvo-amrwbenc
  --enable-libshine
  --enable-libcodec2
  --enable-libmysofa
  --enable-libass
  --enable-libfreetype
  --enable-libfribidi
  --enable-libfontconfig
  --enable-libharfbuzz
  --enable-libaribb24
  --enable-libaribcaption
  --enable-libzimg
  --enable-librubberband
  --enable-libsoxr
  --enable-libvidstab
  --enable-libvmaf
  --enable-frei0r
  --enable-ladspa
  --enable-libbs2b
  --enable-libflite
  # RESTORED: provided by source builds (scripts/deps/libplacebo.sh, built against the newer
  # Vulkan-Headers from scripts/deps/vulkan-headers.sh). Ubuntu 24.04's apt versions were too old.
  --enable-libplacebo
  --enable-libtesseract
  # --enable-liblensfun  # DROPPED: Ubuntu 24.04 ships lensfun 0.3.4, which exports lf_db_new()
  # but NOT lf_db_create(). FFmpeg 8.1.1's configure does `require_pkg_config liblensfun lensfun
  # lensfun.h lf_db_create`, and vf_lensfun.c calls lf_db_create() -> link test fails
  # ("lensfun not found using pkg-config"; undefined reference to lf_db_create). lf_db_create was
  # added upstream after 0.3.4, so no Ubuntu 24.04 package provides it. Genuinely unsupported here.
  --enable-librtmp
  --enable-libsrt
  --enable-libssh
  --enable-libzmq
  --enable-librist
  --enable-libbluray
  --enable-libopenmpt
  --enable-libgme
  --enable-libmodplug
  --enable-chromaprint
  --enable-libcaca
  --enable-libdc1394
  --enable-libcdio
  --enable-openal
  --enable-sndio
  --enable-sdl2
  --enable-libxcb
  --enable-libxcb-shm
  --enable-libxcb-xfixes
  --enable-libxcb-shape
  --enable-libv4l2
  --enable-vaapi
  --enable-vdpau
  # RESTORED: provided by source build (scripts/deps/vulkan-headers.sh installs newer
  # Vulkan-Headers + a shadowing vulkan.pc reporting >= 1.3.277, satisfying FFmpeg 8.1.1's
  # `vulkan >= 1.3.277` require_pkg_config and the VK_HEADER_VERSION >= 277 cpp check).
  --enable-vulkan
  --enable-libshaderc
  --enable-opencl
  --enable-opengl
  --enable-amf
  --enable-nvenc
  --enable-nvdec
  --enable-cuvid
  --enable-ffnvcodec
  --enable-cuda-llvm
  --enable-libvpl
  --enable-libdrm
  --enable-v4l2-m2m
  # restored "omitted" libs (see Dockerfile / build-deps.sh). batch 1:
  --enable-libkvazaar
  --enable-libqrencode
  --enable-librabbitmq
  --enable-liblc3
  # batch 2:
  --enable-libilbc
  --enable-libsvtjpegxs
  # batch 3:
  --enable-libdvdread
  --enable-libdvdnav
)

# ---- safety net: drop any --enable flag this configure does not recognise --------------
# Per the known good flag set this should drop nothing, but it protects against an FFmpeg
# version that renamed/removed a flag (e.g. an old --enable-postproc that no longer exists).
CONFIGURE_HELP="$(./configure --help 2>/dev/null || true)"
VALID_FLAGS=()
for flag in "${ENABLE_FLAGS[@]}"; do
  name="${flag#--enable-}"
  if printf '%s\n' "${CONFIGURE_HELP}" | grep -q -- "--enable-${name}\b" \
     || printf '%s\n' "${CONFIGURE_HELP}" | grep -q -- "--disable-${name}\b"; then
    VALID_FLAGS+=("${flag}")
  else
    echo "WARNING: dropping unknown configure flag for this FFmpeg version: ${flag}"
  fi
done

# ---- relocatability: strip pkg-config link flags that fight our $ORIGIN bundle ----------
# Some libs (notably SDL2) bake `-Wl,-rpath,<abs> -Wl,--enable-new-dtags` into their .pc Libs:.
# Any FFmpeg binary that links such a lib (ffplay links SDL2) then gets an absolute DT_RUNPATH
# instead of the relocatable $ORIGIN DT_RPATH the bundle needs, and the readelf verify below
# would (correctly) fail. Strip those flags from every .pc on PKG_CONFIG_PATH so all three
# binaries link uniformly under our LD_RUN_PATH + --disable-new-dtags scheme. This edits build
# inputs (pkg-config metadata) before configure — not the output binary (no patchelf).
for pcdir in /usr/local/lib/pkgconfig /usr/local/lib/x86_64-linux-gnu/pkgconfig /usr/local/share/pkgconfig; do
  [ -d "${pcdir}" ] || continue
  find "${pcdir}" -name '*.pc' -exec sed -i -E \
    -e 's@ *-Wl,-rpath,[^ ]+@@g' \
    -e 's@ *-Wl,--enable-new-dtags@@g' {} +
done

./configure \
  --prefix="${PREFIX}" \
  --extra-cflags="-I/usr/local/include" \
  --extra-ldflags="-L/usr/local/lib" \
  --extra-libs="-lstdc++ -lm -lpthread -ldl" \
  --ld="g++" \
  --disable-debug \
  "${VALID_FLAGS[@]}"

# ---- build + install -------------------------------------------------------
make -j"$(nproc)"
make install
ldconfig

# ---- verification suite ----------------------------------------------------
# Proof the build works: version + full build config + feature counts + protocols/hwaccels.
# The count lines are guarded with `|| true` so a transient grep exit code can never abort
# the script under `set -e -o pipefail`.
ffmpeg -version
ffmpeg -hide_banner -buildconf
ffprobe -hide_banner -version
echo "encoders : $(ffmpeg -hide_banner -encoders  2>/dev/null | grep -c '^ [A-Z.]\{6,\}' || true)"
echo "decoders : $(ffmpeg -hide_banner -decoders  2>/dev/null | grep -c '^ [A-Z.]\{6,\}' || true)"
echo "muxers   : $(ffmpeg -hide_banner -muxers    2>/dev/null | grep -c '^ ' || true)"
echo "demuxers : $(ffmpeg -hide_banner -demuxers  2>/dev/null | grep -c '^ ' || true)"
echo "filters  : $(ffmpeg -hide_banner -filters   2>/dev/null | grep -c '^ ' || true)"
echo "formats  : $(ffmpeg -hide_banner -formats   2>/dev/null | grep -c '^ ' || true)"
echo "protocols: $(ffmpeg -hide_banner -protocols 2>/dev/null | grep -c '^ ' || true)"
echo "hwaccels : $(ffmpeg -hide_banner -hwaccels  2>/dev/null | grep -cv '^Hardware\|^$' || true)"
echo "libs     : $(ldd "$(command -v ffmpeg)" | grep -c '=>' || true)"
ffmpeg -hide_banner -protocols
ffmpeg -hide_banner -hwaccels

# ---- export a SELF-CONTAINED, RELOCATABLE bundle to the host ----------------
# The naive "copy the binaries" export does NOT work on the host: ffmpeg links the
# image-internal shared libs (libavdevice.so.62, libx264.so, ...) that live under
# /usr/local/lib and the multiarch dirs. On the host those are absent ->
# "libavdevice.so.62: cannot open shared object file".
#
# Instead we assemble a relocatable bundle:
#   <bundle>/ffmpeg  <bundle>/ffprobe  <bundle>/ffplay     (the binaries)
#   <bundle>/lib/<soname> ...                              (EVERY non-glibc shared dep)
# The binaries ALREADY carry an $ORIGIN DT_RPATH baked at LINK time via LD_RUN_PATH (exported
# above) + our --disable-new-dtags ld (scripts/deps/binutils.sh) -- no gcc specs file, no
# patchelf. OLD DT_RPATH on the executable resolves <bundle>/lib via $ORIGIN/lib AND propagates
# to every transitively-loaded lib there, so the tree runs directly from ./out on the host and
# from any directory it is later moved/extracted to -- with NO patchelf rewriting the binaries.
#
# Only glibc core + the dynamic loader are EXCLUDED (provided by the host). Everything else
# (libstdc++, libgcc_s, libcrypt, and all codec/feature libs) is bundled.
if [ -d /output ]; then
  echo "Assembling relocatable bundle ..."

  BUNDLE="/tmp/ffbundle"
  rm -rf "${BUNDLE}"
  mkdir -p "${BUNDLE}/lib"

  # glibc core + dynamic loader: provided by the host, must NOT be bundled (mixing a bundled
  # libc with the host loader breaks things). Everything else IS bundled.
  EXCLUDE_SONAMES=" \
    ld-linux-x86-64.so.2 \
    linux-vdso.so.1 \
    libc.so.6 \
    libm.so.6 \
    libmvec.so.1 \
    libpthread.so.0 \
    libdl.so.2 \
    librt.so.1 \
    libresolv.so.2 \
    libanl.so.1 \
    libnsl.so.1 \
    libutil.so.1 \
    libBrokenLocale.so.1 \
  "

  is_excluded() {
    # $1 = soname; returns 0 (true) if it is in the exclude set.
    case " ${EXCLUDE_SONAMES} " in
      *" $1 "*) return 0 ;;
      *)        return 1 ;;
    esac
  }

  # Copy the binaries that exist into the bundle root.
  WORKLIST=()
  for bin in ffmpeg ffprobe ffplay; do
    binpath=""
    if [ -x "${PREFIX}/bin/${bin}" ]; then
      binpath="${PREFIX}/bin/${bin}"
    elif command -v "${bin}" >/dev/null 2>&1; then
      binpath="$(command -v "${bin}")"
    fi
    if [ -n "${binpath}" ]; then
      cp -f "${binpath}" "${BUNDLE}/${bin}"
      chmod +x "${BUNDLE}/${bin}"
      WORKLIST+=("${BUNDLE}/${bin}")
      echo "bundled binary: ${bin} (from ${binpath})"
    fi
  done

  # Fixpoint walk: for every ELF in the worklist, read its ldd lines of the form
  #   <soname> => <path> (0x...)
  # For each (soname,path): skip glibc/loader; otherwise copy the dereferenced real file to
  # <bundle>/lib/<soname> (if not already present) and add it to the worklist. Repeat until
  # no new libs appear.
  while [ "${#WORKLIST[@]}" -gt 0 ]; do
    elf="${WORKLIST[0]}"
    WORKLIST=("${WORKLIST[@]:1}")

    # ldd can exit non-zero for a perfectly-linked binary (e.g. statically-linked notice);
    # guard with || true so set -e/pipefail never aborts the export.
    ldd_out="$(ldd "${elf}" 2>/dev/null || true)"

    # Parse only the "soname => path (0x...)" lines.
    while IFS= read -r line; do
      # Trim leading whitespace.
      line="${line#"${line%%[![:space:]]*}"}"
      case "${line}" in
        *"=>"*)
          soname="${line%%=>*}"
          soname="${soname%"${soname##*[![:space:]]}"}"   # rtrim
          rhs="${line#*=>}"
          rhs="${rhs#"${rhs%%[![:space:]]*}"}"            # ltrim
          # rhs is "<path> (0x...)" ; strip the trailing " (0x...)".
          libpath="${rhs%% (0x*}"
          libpath="${libpath%"${libpath##*[![:space:]]}"}" # rtrim
          ;;
        *)
          continue
          ;;
      esac

      [ -z "${soname}" ] && continue
      [ -z "${libpath}" ] && continue
      # "not found" or vdso-style entries have no real path.
      [ ! -e "${libpath}" ] && continue

      if is_excluded "${soname}"; then
        continue
      fi

      dest="${BUNDLE}/lib/${soname}"
      if [ ! -e "${dest}" ]; then
        # cp -L dereferences the symlink chain (libfoo.so.62 -> libfoo.so.62.1.100) and
        # stores the REAL file under the soname name, so the bundle is symlink-free.
        cp -L -f "${libpath}" "${dest}"
        chmod +x "${dest}" 2>/dev/null || true
        WORKLIST+=("${dest}")
        echo "bundled lib: ${soname} (from ${libpath})"
      fi
    done <<EOF_LDD
${ldd_out}
EOF_LDD
  done

  # ---- verify relocatability (NO patchelf) ----------------------------------
  # The bundle is relocatable BY CONSTRUCTION: our from-source gcc baked an $ORIGIN DT_RPATH
  # into ffmpeg/ffprobe/ffplay at link time, and OLD-style DT_RPATH on the executable
  # propagates to every transitively-loaded lib in <bundle>/lib. We ASSERT that here and FAIL
  # the build if a binary lost its $ORIGIN rpath, so a regression surfaces loudly instead of
  # shipping a broken bundle -- and is fixed at the toolchain/recipe level, never by rewriting
  # the finished binary.
  # Require OLD-style DT_RPATH specifically (readelf prints it as "(RPATH)"). DT_RUNPATH is NOT
  # acceptable: it does not propagate to transitively-loaded libs (libstdc++ -> libgcc_s), so a
  # bundle whose binaries only had RUNPATH would break on the host even though $ORIGIN is present.
  for bin in ffmpeg ffprobe ffplay; do
    [ -f "${BUNDLE}/${bin}" ] || continue
    rpath_line="$(readelf -d "${BUNDLE}/${bin}" 2>/dev/null | grep '(RPATH)' || true)"
    if printf '%s' "${rpath_line}" | grep -q '\$ORIGIN'; then
      echo "rpath OK: ${bin} -> $(printf '%s' "${rpath_line}" | sed 's/^[[:space:]]*//')"
    else
      echo "FATAL: ${bin} carries no \$ORIGIN DT_RPATH (old dtags) -- the relocatable bundle" >&2
      echo "       would break on the host. DT_RUNPATH is insufficient (it does not propagate to" >&2
      echo "       transitive deps like libstdc++->libgcc_s). Expected LD_RUN_PATH + our" >&2
      echo "       --disable-new-dtags ld to bake it. NOT patching post-hoc; failing instead." >&2
      exit 1
    fi
  done
  # Informational: most bundled libs also carry their own $ORIGIN rpath; the handful of
  # toolchain runtime libs gcc built for itself (libstdc++/libgcc_s, linked before the specs
  # file existed) carry none and rely on the propagating executable DT_RPATH, which is fine.
  _withrp=0; _total=0
  for lib in "${BUNDLE}"/lib/*.so*; do
    [ -e "${lib}" ] || continue
    _total=$((_total + 1))
    if readelf -d "${lib}" 2>/dev/null | grep '(RPATH)' | grep -q '\$ORIGIN'; then
      _withrp=$((_withrp + 1))
    fi
  done
  echo "bundled libs carrying their own \$ORIGIN rpath: ${_withrp}/${_total}"

  # ---- export the bundle to /output ----------------------------------------
  echo "Exporting relocatable bundle to /output ..."
  mkdir -p /output/lib
  for bin in ffmpeg ffprobe ffplay; do
    if [ -f "${BUNDLE}/${bin}" ]; then
      cp -f "${BUNDLE}/${bin}" /output/
    fi
  done
  # Replace any stale /output/lib then copy the fresh bundled libs.
  rm -rf /output/lib
  cp -a "${BUNDLE}/lib" /output/lib

  # Relocatable tarball: created from INSIDE the bundle so paths are ffmpeg/ffprobe/ffplay/lib/
  # (relative) -- extracting it anywhere yields a self-contained, runnable tree.
  TARBALL_NAME="ffmpeg-${FFMPEG_VERSION}-linux-x86_64.tar.gz"
  TAR_MEMBERS=()
  for m in ffmpeg ffprobe ffplay lib; do
    [ -e "${BUNDLE}/${m}" ] && TAR_MEMBERS+=("${m}")
  done
  if [ "${#TAR_MEMBERS[@]}" -gt 0 ]; then
    tar -czf "/output/${TARBALL_NAME}" -C "${BUNDLE}" "${TAR_MEMBERS[@]}"
  fi

  echo "Bundled $(ls -1 "${BUNDLE}/lib" 2>/dev/null | wc -l) shared libraries into out/lib."
  echo "Artifacts written to /output:"
  ls -la /output

  echo ""
  echo "NOTE: this bundle relies on the HOST's glibc (must be >= the glibc this image built"
  echo "      against; Ubuntu 24.04 ships glibc 2.39). Runtime HARDWARE ACCELERATION"
  echo "      (nvenc/nvdec/cuda, vaapi, vdpau, vulkan, opencl, ...) additionally needs the"
  echo "      matching HOST DRIVERS / loaders installed (e.g. NVIDIA driver, libva drivers);"
  echo "      those are intentionally NOT bundled."
else
  echo "No /output volume mounted; skipping artifact export."
  echo "Mount a host dir to receive the bundle, e.g.: docker run --rm -v \"\$PWD/out:/output\" ffmpeg-build"
fi
