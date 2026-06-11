#!/usr/bin/env bash
# fftw — Fast Fourier Transform library (FFTW3); double + single (float) precision builds.
# chromaprint requires fftw3 (double) and/or fftw3f (float); build both to satisfy either.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="3.3.11"
SRC="${SRCROOT}/fftw"

fetch_tar "https://fftw.org/fftw-${VER}.tar.gz" "${SRC}"

# --- double precision (default) ---
cd "${SRC}"
./configure --prefix="${PREFIX}" \
            --enable-shared --disable-static \
            --enable-threads
make -j"${JOBS}"
make install

# --- single (float) precision ---
# Re-configure in-place with --enable-float; FFTW supports this cleanly.
make distclean
./configure --prefix="${PREFIX}" \
            --enable-shared --disable-static \
            --enable-threads \
            --enable-float
make -j"${JOBS}"
make install

ldconfig

verify_pc fftw3 fftw3f
cleanup "${SRC}"
