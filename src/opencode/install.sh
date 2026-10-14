#!/usr/bin/env bash
# Feature opencode: CLI do opencode (github.com/anomalyco/opencode), binario oficial do GitHub
# Releases, versao fixa. O seo-brain roda nele (README do seo-brain: skills registradas no
# opencode); 1.18.29 e' a versao que o dono usa hoje no host.
#
# O release nao publica arquivo de hash: o sha256 vem do campo `digest` que o GitHub calcula
# para cada asset (embutido para a versao default; API /releases/tags so' como fallback).
# Confianca na origem: TLS do GitHub.
#
# Idempotente: se o opencode pedido ja existe, nao faz nada.
set -euo pipefail

OC_VERSION="${VERSION:-1.18.29}"

if command -v opencode >/dev/null 2>&1 && [ "$(opencode --version 2>/dev/null)" = "${OC_VERSION}" ]; then
  echo "opencode: ${OC_VERSION} ja instalado"
  exit 0
fi

case "$(dpkg --print-architecture)" in
  amd64) ARCH=x64 ;;
  arm64) ARCH=arm64 ;;
  *) echo "opencode: arquitetura nao suportada: $(dpkg --print-architecture)" >&2; exit 1 ;;
esac
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

file="opencode-linux-${ARCH}.tar.gz"
curl -fsSL "https://github.com/anomalyco/opencode/releases/download/v${OC_VERSION}/${file}" -o "$tmp/$file"
# sha256 da versao default embutido (conferido pelo `digest` da API em 14/10); outra
# versao cai na API, e se ela falhar o install falha alto.
case "${OC_VERSION}/${ARCH}" in
  1.18.29/x64)   sum=ea800b7ff56226b70952126c9fc1e2517ca4c4b5682fd9d3f9e87449697a1194 ;;
  1.18.29/arm64) sum=70baf769395ca4e7a68924026530c390eace194f3b7e4919d4efcb2aa2eed3c0 ;;
  *) sum="$(curl -fsSL "https://api.github.com/repos/anomalyco/opencode/releases/tags/v${OC_VERSION}" \
       | jq -r --arg f "$file" '.assets[] | select(.name==$f) | .digest' | sed 's/^sha256://')" ;;
esac
[ -n "$sum" ] && [ "$sum" != null ] || { echo "opencode: sem digest para $file" >&2; exit 1; }
echo "$sum  $tmp/$file" | sha256sum -c -
tar -xzf "$tmp/$file" -C "$tmp" opencode
install -m 0755 "$tmp/opencode" /usr/local/bin/opencode

opencode --version
echo "opencode: pronto (${OC_VERSION})"
