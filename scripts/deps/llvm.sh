#!/usr/bin/env bash
# clang/LLVM from source — provides `clang`, used at FFmpeg-compile time by FFmpeg's
# --enable-cuda-llvm to compile the bundled CUDA filter kernels (.cu) to PTX. This is the open,
# nvcc-free CUDA path the project's design mandates (no proprietary NVIDIA CUDA toolkit).
#
# Build-time tool ONLY: clang/LLVM are NOT linked into the FFmpeg bundle — cuda_llvm embeds only
# the compiled PTX into libavfilter. The from-source toolchain (gcc) builds clang; clang then
# only needs to emit NVPTX device code, so we build a deliberately minimal LLVM to stay tractable
# on a constrained host:
#   * Release (Debug LLVM is enormous),
#   * only the host (X86) + CUDA device (NVPTX) targets, not all backends,
#   * clang project only; no tests/examples/benchmarks/bindings/static-analyzer,
#   * LLVM_PARALLEL_LINK_JOBS=1 so the memory-heavy link phase can't OOM at JOBS=3.
# Placed AFTER the media libraries on purpose: nothing in phase 3 depends on clang, so adding it
# as the last dep layer never cache-busts the ~100 media-lib layers. Deps (cmake/ninja/python/gcc)
# all come from phase 2.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="19.1.7"
SRC="${SRCROOT}/llvm-project"

fetch_tar "https://github.com/llvm/llvm-project/releases/download/llvmorg-${VER}/llvm-project-${VER}.src.tar.xz" "${SRC}"
cmake -S "${SRC}/llvm" -B "${SRC}/build" -G Ninja \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_PROJECTS=clang \
  -DLLVM_TARGETS_TO_BUILD="X86;NVPTX" \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DLLVM_INCLUDE_EXAMPLES=OFF \
  -DLLVM_INCLUDE_BENCHMARKS=OFF \
  -DLLVM_ENABLE_BINDINGS=OFF \
  -DLLVM_ENABLE_TERMINFO=OFF \
  -DLLVM_ENABLE_LIBXML2=OFF \
  -DLLVM_ENABLE_ZSTD=OFF \
  -DLLVM_PARALLEL_LINK_JOBS=1 \
  -DCLANG_ENABLE_STATIC_ANALYZER=OFF \
  -DCLANG_ENABLE_ARCMT=OFF
ninja -C "${SRC}/build" -j"${JOBS}" clang
ninja -C "${SRC}/build" install-clang install-clang-resource-headers
ldconfig

command -v clang >/dev/null && clang --version || die "clang not installed/working"
# Sanity: clang must be able to target the CUDA device backend (NVPTX) for cuda_llvm.
clang -print-targets 2>/dev/null | grep -qi nvptx || die "clang lacks the NVPTX target"
cleanup "${SRC}"
