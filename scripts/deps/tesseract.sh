#!/usr/bin/env bash
# Tesseract OCR engine — required by FFmpeg --enable-libtesseract (OCR subtitle filter).
# CMake build; depends on leptonica. Produces tesseract.pc.
# NOTE: tesseract itself is heavy; the OCR data (tessdata) is NOT bundled here —
# FFmpeg only needs the library headers/so at build time; tessdata must be present at runtime.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="5.5.2"
SRC="${SRCROOT}/tesseract"

fetch_git "https://github.com/tesseract-ocr/tesseract.git" "${VER}" "${SRC}"
cd "${SRC}"
cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DBUILD_SHARED_LIBS=ON \
  -DBUILD_TRAINING_TOOLS=OFF \
  -DDISABLE_TIFF=ON
cmake --build "${SRC}/build" --parallel "${JOBS}"
cmake --install "${SRC}/build"
ldconfig

verify_pc tesseract
cleanup "${SRC}"
