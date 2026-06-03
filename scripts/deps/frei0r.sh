#!/usr/bin/env bash
# frei0r-plugins — minimalist plugin API for video effects; FFmpeg --enable-frei0r.
# CMake build; installs frei0r.h header, plugin .so files, and frei0r.pc.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v3.1.3"
SRC="${SRCROOT}/frei0r"

fetch_git "https://github.com/dyne/frei0r.git" "${VER}" "${SRC}"

# frei0r's CMakeLists does find_package(... REQUIRED) for OpenCV, Cairo and gavl (all default-on)
# to gate optional plugin groups. We ship none of those libs, and FFmpeg --enable-frei0r only
# needs frei0r.h plus the dependency-free plugins (loaded via dlopen at runtime), so disable all
# three; the remaining plugins build fine. (Threads is a standard CMake module, always present.)
cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DWITHOUT_OPENCV=ON \
  -DWITHOUT_CAIRO=ON \
  -DWITHOUT_GAVL=ON
cmake --build "${SRC}/build" --parallel "${JOBS}"
cmake --install "${SRC}/build"
ldconfig

verify_pc frei0r
cleanup "${SRC}"
