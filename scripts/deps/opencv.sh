#!/usr/bin/env bash
# OpenCV — for FFmpeg --enable-libopencv (the `ocv` video filter: dilate/erode/smooth via OpenCV's
# legacy C API). FFmpeg only needs opencv2/core/core_c.h + cvCreateImageHeader from opencv_core /
# opencv_imgproc (pkg-config opencv4). Build ONLY core+imgproc (all the filter uses) to keep this
# small and fast, with OPENCV_GENERATE_PKGCONFIG so opencv4.pc exists. 4.11.0 still ships the
# legacy C API (removed only in OpenCV 5.x). Use our gcc-14 for the whole (LTO-safe) C++ build.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="4.11.0"
SRC="${SRCROOT}/opencv"

fetch_git "https://github.com/opencv/opencv" "${VER}" "${SRC}"
mkdir -p "${SRC}/build"
cd "${SRC}/build"
export CC=gcc CXX=g++
cmake .. \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DBUILD_LIST=core,imgproc \
  -DOPENCV_GENERATE_PKGCONFIG=ON \
  -DBUILD_TESTS=OFF -DBUILD_PERF_TESTS=OFF -DBUILD_EXAMPLES=OFF \
  -DBUILD_opencv_apps=OFF -DBUILD_DOCS=OFF \
  -DBUILD_opencv_python3=OFF -DBUILD_JAVA=OFF \
  -DWITH_FFMPEG=OFF -DWITH_GTK=OFF -DWITH_QT=OFF -DWITH_OPENGL=OFF \
  -DWITH_CUDA=OFF -DWITH_OPENCL=OFF -DWITH_IPP=OFF -DWITH_TBB=OFF \
  -DWITH_GSTREAMER=OFF -DWITH_V4L=OFF -DWITH_1394=OFF -DWITH_GTK_2_X=OFF
make -j"${JOBS}"
make install
ldconfig

verify_pc opencv4
cleanup "${SRC}"
