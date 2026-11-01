#!/usr/bin/env bash
# Feature rust: rustup + toolchain + linker C (gcc), necessario a crates que compilam C.
#
# Idempotente. O rust-toolchain.toml do projeto vence: o rustup instala a versao dele no
# primeiro uso, entao RUSTUP_HOME e CARGO_HOME ficam gravaveis pelo usuario do container.
set -euo pipefail

RUST_VERSION="${VERSION:-stable}"
USERNAME="${_REMOTE_USER:-dev}"
export RUSTUP_HOME=/usr/local/rustup CARGO_HOME=/usr/local/cargo

if ! command -v gcc >/dev/null 2>&1; then
  apt-get update
  apt-get install -y --no-install-recommends gcc libc6-dev pkg-config
  rm -rf /var/lib/apt/lists/*
fi

if [ ! -x "$CARGO_HOME/bin/rustup" ]; then
  curl -fsSL https://sh.rustup.rs -o /tmp/rustup-init.sh
  sh /tmp/rustup-init.sh -y --no-modify-path --profile minimal --default-toolchain "$RUST_VERSION"
  rm -f /tmp/rustup-init.sh
fi

mkdir -p "$CARGO_HOME/registry"
chown -R "$USERNAME" "$RUSTUP_HOME" "$CARGO_HOME"
"$CARGO_HOME/bin/cargo" --version
