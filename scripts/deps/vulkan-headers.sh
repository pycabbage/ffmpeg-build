#!/usr/bin/env bash
# Vulkan-Headers (header-only) for FFmpeg --enable-vulkan and the libplacebo vulkan backend.
#
# WHY: Ubuntu 24.04 ships libvulkan-dev whose vulkan.pc reports 1.3.275 (VK_HEADER_VERSION 275).
# FFmpeg 8.1.1 configure requires `vulkan >= 1.3.277` (require_pkg_config) AND a cpp check
# `VK_HEADER_VERSION >= 277`. So we install NEWER Khronos Vulkan-Headers into /usr/local and
# write our own /usr/local/lib/pkgconfig/vulkan.pc reporting the new header version while still
# linking the apt-provided libvulkan loader (.so). PKG_CONFIG_PATH lists /usr/local first, so
# this vulkan.pc shadows apt's. No driver/loader is rebuilt -- headers + .pc metadata only.
set -euxo pipefail

# A recent stable tag well above the 1.3.277 floor FFmpeg 8.1.1 requires.
VER="v1.4.323"
# The version string our generated vulkan.pc advertises (tag without the leading 'v').
PC_VERSION="1.4.323"
SRC="/tmp/vkh"

git clone --depth 1 --branch "${VER}" \
  https://github.com/KhronosGroup/Vulkan-Headers.git "${SRC}"

# Header-only install: drops vulkan/ and vk_video/ headers under /usr/local/include.
cmake -S "${SRC}" -B "${SRC}/build" -DCMAKE_INSTALL_PREFIX=/usr/local
cmake --install "${SRC}/build"

# Shadow apt's vulkan.pc: report the NEW header version, point Cflags at the new headers,
# and link the apt loader (libvulkan.so) from the multiarch libdir.
mkdir -p /usr/local/lib/pkgconfig
cat > /usr/local/lib/pkgconfig/vulkan.pc <<PC
prefix=/usr/local
includedir=/usr/local/include
libdir=/usr/lib/x86_64-linux-gnu

Name: Vulkan-Headers
Description: Vulkan headers (Khronos) overriding apt's vulkan.pc; links the system loader.
Version: ${PC_VERSION}
Cflags: -I/usr/local/include
Libs: -L/usr/lib/x86_64-linux-gnu -lvulkan
PC

ldconfig

# Verify: pkg-config reports the new version and the installed header is >= 277.
test "$(pkg-config --modversion vulkan)" = "${PC_VERSION}"
grep 'define VK_HEADER_VERSION ' /usr/local/include/vulkan/vulkan_core.h

rm -rf "${SRC}"
