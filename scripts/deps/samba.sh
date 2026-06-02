#!/usr/bin/env bash
# samba — provides libsmbclient for FFmpeg --enable-libsmbclient (smb:// protocol).
# Samba's own waf-based build system. We build only the client libraries, not the AD-DC
# or file server, to minimise build time and dependencies.
#
# NOTE: This is a VERY heavy build (~40 MB source, Python 3 required for waf, large
# transitive dependency tree including gnutls, readline, ncurses, cmocka, Perl, etc.).
# Build is brittle — it probes many system headers and may fail if a dep is missing.
# Samba versions frequently break configure across environments. This recipe is
# best-effort and LIKELY NEEDS ITERATION or may need to be dropped in favour of an
# apt-provided libsmbclient-dev if the from-source build proves too fragile.
# The Dockerfile can keep apt's libsmbclient-dev as a fallback in a separate layer.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="4.22.1"
SRC="${SRCROOT}/samba"

fetch_tar "https://download.samba.org/pub/samba/stable/samba-${VER}.tar.gz" "${SRC}"
cd "${SRC}"

# waf configure: skip AD-DC, Kerberos server, python bindings, cups, systemd.
# --enable-fhs keeps paths under PREFIX in a standard FHS layout.
# --bundled-libraries=ALL bundles everything waf can't find via pkg-config rather than
# hard-failing so that missing optional deps don't abort the configure.
./configure \
  --prefix="${PREFIX}" \
  --enable-fhs \
  --without-ad-dc \
  --without-acl-support \
  --without-systemd \
  --without-gpgme \
  --without-ldb-lmdb \
  --disable-cups \
  --disable-iprint \
  --nopyc \
  --nopyo \
  --bundled-libraries=ALL \
  --with-shared-modules=!vfs_snapper

make -j"${JOBS}"
make install
ldconfig

# samba installs smbclient.pc under PREFIX/lib/pkgconfig
verify_pc smbclient
cleanup "${SRC}"
