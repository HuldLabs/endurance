#!/usr/bin/env bash
# Feature opentofu: `tofu`, binario oficial do GitHub Releases, versao fixa, conferido pelo
# `tofu_<v>_SHA256SUMS` do proprio release (confianca na origem: TLS do GitHub).
# OpenTofu e nao terraform: nenhum repo do ecossistema versiona .tf nem usa state/cloud da
# HashiCorp (docs/ecossistema.md, L3) — so' skills vendorizadas que citam terraform.
#
# Idempotente: se o tofu pedido ja existe, nao faz nada.
set -euo pipefail

TOFU_VERSION="${VERSION:-1.13.1}"

if command -v tofu >/dev/null 2>&1 && tofu version | head -n1 | grep -qx "OpenTofu v${TOFU_VERSION}"; then
  echo "opentofu: ${TOFU_VERSION} ja instalado"
  exit 0
fi

case "$(dpkg --print-architecture)" in
  amd64|arm64) ARCH="$(dpkg --print-architecture)" ;;
  *) echo "opentofu: arquitetura nao suportada: $(dpkg --print-architecture)" >&2; exit 1 ;;
esac
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

file="tofu_${TOFU_VERSION}_linux_${ARCH}.tar.gz"
base="https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}"
curl -fsSL "$base/$file" -o "$tmp/$file"
curl -fsSL "$base/tofu_${TOFU_VERSION}_SHA256SUMS" | grep " ${file}$" | (cd "$tmp" && sha256sum -c -)
tar -xzf "$tmp/$file" -C "$tmp" tofu
install -m 0755 "$tmp/tofu" /usr/local/bin/tofu

tofu version | head -n1
echo "opentofu: pronto (${TOFU_VERSION})"
