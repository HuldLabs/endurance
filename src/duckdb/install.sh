#!/usr/bin/env bash
# Feature duckdb: CLI do duckdb, binario oficial do GitHub Releases, versao fixa (nexus).
#
# O release nao publica arquivo de hash: o sha256 vem do campo `digest` que o GitHub
# calcula para cada asset (embutido para a versao default; API so' como fallback) (API /releases/tags). Confianca na origem: TLS do GitHub.
#
# Idempotente: se o duckdb pedido ja existe, nao faz nada.
set -euo pipefail

DUCKDB_VERSION="${VERSION:-1.5.6}"

if command -v duckdb >/dev/null 2>&1 && duckdb --version | grep -q "^v${DUCKDB_VERSION} "; then
  echo "duckdb: ${DUCKDB_VERSION} ja instalado"
  exit 0
fi

case "$(dpkg --print-architecture)" in
  amd64|arm64) ARCH="$(dpkg --print-architecture)" ;;
  *) echo "duckdb: arquitetura nao suportada: $(dpkg --print-architecture)" >&2; exit 1 ;;
esac
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

file="duckdb_cli-linux-${ARCH}.gz"
curl -fsSL "https://github.com/duckdb/duckdb/releases/download/v${DUCKDB_VERSION}/${file}" -o "$tmp/$file"
# sha256 da versao default embutido (conferido pelo `digest` da API em 14/10); outra
# versao cai na API, e se ela falhar o install falha alto.
case "${DUCKDB_VERSION}/${ARCH}" in
  1.5.6/amd64) sum=cce2687a38681db644c248198b99ecd86170ff47e324c5f33e50c0042f142839 ;;
  1.5.6/arm64) sum=1af0541e649a3ae34eb20eec2ca564308bf0e8993e5d6dba6be77bfb289a2718 ;;
  *) sum="$(curl -fsSL "https://api.github.com/repos/duckdb/duckdb/releases/tags/v${DUCKDB_VERSION}" \
       | jq -r --arg f "$file" '.assets[] | select(.name==$f) | .digest' | sed 's/^sha256://')" ;;
esac
[ -n "$sum" ] && [ "$sum" != null ] || { echo "duckdb: sem digest para $file" >&2; exit 1; }
echo "$sum  $tmp/$file" | sha256sum -c -
gunzip -c "$tmp/$file" > "$tmp/duckdb"
install -m 0755 "$tmp/duckdb" /usr/local/bin/duckdb

duckdb --version
echo "duckdb: pronto (${DUCKDB_VERSION})"
