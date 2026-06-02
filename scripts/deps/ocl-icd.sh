#!/usr/bin/env bash
# ocl-icd — OpenCL Installable Client Driver (ICD) loader; provides libOpenCL.so + OpenCL.pc.
# The real ICD/driver is provided by the host at runtime. Must run after opencl-headers.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v2.3.4"
SRC="${SRCROOT}/ocl-icd"

fetch_git "https://github.com/OCL-dev/ocl-icd.git" "${VER}" "${SRC}"
cd "${SRC}"
autoreconf -fiv
./configure --prefix="${PREFIX}" --disable-static --enable-shared
make -j"${JOBS}"
make install
ldconfig

verify_pc OpenCL
cleanup "${SRC}"
