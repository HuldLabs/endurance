#!/usr/bin/env bash
# Feature diag: ferramentas de diagnostico, todas do apt da distro (versao = a da trixie).
#
# POR QUE apt: sao ferramentas de inspecao, sem servidor nem formato para casar versao; o
# apt da distro e' assinado e atualiza junto com a base. O `perf` vem do pacote
# `linux-perf`; dentro do container ele so' mede o que o kernel do host permitir
# (`perf_event_paranoid`), e isso e' do host, nao daqui.
#
# Idempotente: so' instala o que falta.
set -euo pipefail

declare -A PKG=(
  [ss]=iproute2 [strace]=strace [lsof]=lsof [perf]=linux-perf
  [iostat]=sysstat [zstd]=zstd [hyperfine]=hyperfine
)
FALTA=()
for bin in "${!PKG[@]}"; do
  command -v "$bin" >/dev/null 2>&1 || FALTA+=("${PKG[$bin]}")
done

if [ "${#FALTA[@]}" -gt 0 ]; then
  apt-get update
  apt-get install -y --no-install-recommends "${FALTA[@]}"
  rm -rf /var/lib/apt/lists/*
fi

for bin in "${!PKG[@]}"; do
  command -v "$bin" >/dev/null 2>&1 || { echo "diag: '$bin' ausente depois do apt" >&2; exit 1; }
done
echo "diag: pronto (ss strace lsof perf iostat zstd hyperfine)"
