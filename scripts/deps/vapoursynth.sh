#!/usr/bin/env bash
# VapourSynth — script-driven frameserver; FFmpeg --enable-vapoursynth (pkg-config:
# vapoursynth-script). meson build (R76 dropped autotools). Needs Cython (Python module) plus our
# from-source zimg + Python.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="R76"
SRC="${SRCROOT}/vapoursynth"

# Cython is a hard build dependency of VapourSynth's meson build (the _vapoursynth Python module).
python3 -m pip install --no-cache-dir --upgrade Cython

fetch_git "https://github.com/vapoursynth/vapoursynth" "${VER}" "${SRC}"
cd "${SRC}"
# Force OUR gcc for BOTH C and C++: meson otherwise picks the seed gcc-13 as `cc` for C while using
# our gcc-14 `c++` for C++, and vapoursynth's -flto link then fails on the LTO bytecode version
# mismatch (13.1 vs 14.0). gcc/g++ resolve to /usr/local (our 14.2.0) via common.sh's PATH.
export CC=gcc CXX=g++
meson setup build \
  --prefix="${PREFIX}" \
  --buildtype=release \
  --default-library=shared
ninja -C build -j"${JOBS}"
ninja -C build install
ldconfig

verify_pc vapoursynth vapoursynth-script
cleanup "${SRC}"
