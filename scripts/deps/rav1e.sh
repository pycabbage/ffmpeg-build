#!/usr/bin/env bash
# rav1e: Rust AV1 encoder for FFmpeg --enable-librav1e.
# No Ubuntu apt package exists -> always built from source via cargo-c.
# Needs the full Rust toolchain (rustup) + cargo-c, plus nasm for x86_64 asm.
# Heavy/slow (network + full Rust compile); the toolchain is pinned to stable.
set -euxo pipefail

VER="v0.8.1"
SRC="/tmp/rav1e"

# Install Rust via rustup (apt rustc is too old for rav1e), pin to stable/minimal.
export RUSTUP_HOME="${RUSTUP_HOME:-/opt/rust/rustup}"
export CARGO_HOME="${CARGO_HOME:-/opt/rust/cargo}"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
  | sh -s -- -y --default-toolchain stable --profile minimal --no-modify-path
export PATH="${CARGO_HOME}/bin:${PATH}"

# rav1e.sh does not source common.sh, so the from-source libs in /usr/local are not yet on the
# linker's search path. cargo-c (via its openssl-sys / libz-sys deps) links -lssl/-lcrypto/-lz
# from /usr/local/lib; without this the final link fails with "unable to find library -lssl".
# Expose /usr/local to BOTH the cc-driven link (LIBRARY_PATH) and rustc's own link step
# (RUSTFLAGS -L), so the fix holds whether rustc drives GNU ld via cc or invokes rust-lld directly.
export LIBRARY_PATH="/usr/local/lib:/usr/local/lib64${LIBRARY_PATH:+:$LIBRARY_PATH}"
export RUSTFLAGS="-L native=/usr/local/lib -L native=/usr/local/lib64 ${RUSTFLAGS:-}"

# cargo-c provides the `cargo cinstall` subcommand (C-API .so + header + .pc).
cargo install cargo-c

git clone --depth 1 --branch "${VER}" \
  https://github.com/xiph/rav1e.git "${SRC}"

cd "${SRC}"
# Pass --libdir explicitly so rav1e.pc lands in lib/ (not lib64) on this distro.
cargo cinstall --release \
  --prefix=/usr/local \
  --libdir=/usr/local/lib \
  --includedir=/usr/local/include
ldconfig

pkg-config --exists --print-errors rav1e

rm -rf "${SRC}"
