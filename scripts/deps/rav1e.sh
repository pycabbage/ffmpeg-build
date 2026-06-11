#!/usr/bin/env bash
# rav1e: Rust AV1 encoder for FFmpeg --enable-librav1e.
# No Ubuntu apt package exists -> always built from source via cargo-c.
# Needs the full Rust toolchain (rustup) + cargo-c, plus nasm for x86_64 asm.
# Heavy/slow (network + full Rust compile); the toolchain is pinned to stable.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v0.8.1"
SRC="${SRCROOT}/rav1e"

# Install Rust via rustup (apt rustc is too old for rav1e), pin to stable/minimal. The toolchain
# lands in /opt/rust and persists in the image layer (librsvg.sh reuses it).
export RUSTUP_HOME="${RUSTUP_HOME:-/opt/rust/rustup}"
export CARGO_HOME="${CARGO_HOME:-/opt/rust/cargo}"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
  | sh -s -- -y --default-toolchain stable --profile minimal --no-modify-path
export PATH="${CARGO_HOME}/bin:${PATH}"

# common.sh exports LD_RUN_PATH (so ld bakes the $ORIGIN DT_RPATH into librav1e.so) and
# LDFLAGS=-L${PREFIX}/lib, but rustc/rust-lld does NOT consult LDFLAGS for its link search path.
# cargo-c (via its openssl-sys/libz-sys deps) links -lssl/-lcrypto/-lz from ${PREFIX}/lib; expose
# it to BOTH the cc-driven link (LIBRARY_PATH) and rustc's own link step (RUSTFLAGS -L) or the
# final link fails with "unable to find library -lssl".
export LIBRARY_PATH="${PREFIX}/lib:${PREFIX}/lib64${LIBRARY_PATH:+:$LIBRARY_PATH}"
export RUSTFLAGS="-L native=${PREFIX}/lib -L native=${PREFIX}/lib64 ${RUSTFLAGS:-}"

# cargo-c provides the `cargo cinstall` subcommand (C-API .so + header + .pc).
cargo install cargo-c

fetch_git https://github.com/xiph/rav1e.git "${VER}" "${SRC}"

cd "${SRC}"
# Pass --libdir explicitly so rav1e.pc lands in lib/ (not lib64) on this distro.
cargo cinstall --release \
  --prefix="${PREFIX}" \
  --libdir="${PREFIX}/lib" \
  --includedir="${PREFIX}/include"
ldconfig

verify_pc rav1e
cleanup "${SRC}"
