#!/usr/bin/env bash
# Feature lint: shellcheck + actionlint, binarios oficiais do GitHub Releases, versoes fixas.
#
# Verificacao: o actionlint publica `checksums.txt`; o shellcheck NAO publica arquivo de
# hash, entao o sha256 vem do campo `digest` que o GitHub calcula para cada asset (embutido para a versao default; API so' como fallback) do
# release (API /releases/tags). Em ambos a confianca na origem e' o TLS do GitHub.
#
# Idempotente: cada binario so' e' baixado se a versao pedida nao estiver instalada.
set -euo pipefail

SC_VERSION="${SHELLCHECKVERSION:-0.11.0}"
AL_VERSION="${ACTIONLINTVERSION:-1.7.12}"

case "$(dpkg --print-architecture)" in
  amd64) SC_ARCH=x86_64;  AL_ARCH=amd64 ;;
  arm64) SC_ARCH=aarch64; AL_ARCH=arm64 ;;
  *) echo "lint: arquitetura nao suportada: $(dpkg --print-architecture)" >&2; exit 1 ;;
esac
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

if ! { command -v shellcheck >/dev/null 2>&1 && shellcheck --version | grep -qx "version: ${SC_VERSION}"; }; then
  file="shellcheck-v${SC_VERSION}.linux.${SC_ARCH}.tar.xz"
  curl -fsSL "https://github.com/koalaman/shellcheck/releases/download/v${SC_VERSION}/${file}" -o "$tmp/$file"
  # sha256 da versao default embutido (conferido pelo `digest` da API em 14/10); outra
  # versao cai na API, e se ela falhar o install falha alto.
  case "${SC_VERSION}/${SC_ARCH}" in
    0.11.0/x86_64)  sum=8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198 ;;
    0.11.0/aarch64) sum=12b331c1d2db6b9eb13cfca64306b1b157a86eb69db83023e261eaa7e7c14588 ;;
    *) sum="$(curl -fsSL "https://api.github.com/repos/koalaman/shellcheck/releases/tags/v${SC_VERSION}" \
         | jq -r --arg f "$file" '.assets[] | select(.name==$f) | .digest' | sed 's/^sha256://')" ;;
  esac
  [ -n "$sum" ] && [ "$sum" != null ] || { echo "lint: sem digest para $file" >&2; exit 1; }
  echo "$sum  $tmp/$file" | sha256sum -c -
  tar -xJf "$tmp/$file" -C "$tmp"
  install -m 0755 "$tmp/shellcheck-v${SC_VERSION}/shellcheck" /usr/local/bin/shellcheck
fi

if ! { command -v actionlint >/dev/null 2>&1 && actionlint --version | head -n1 | grep -qx "${AL_VERSION}"; }; then
  file="actionlint_${AL_VERSION}_linux_${AL_ARCH}.tar.gz"
  base="https://github.com/rhysd/actionlint/releases/download/v${AL_VERSION}"
  curl -fsSL "$base/$file" -o "$tmp/$file"
  curl -fsSL "$base/actionlint_${AL_VERSION}_checksums.txt" | grep " ${file}$" | (cd "$tmp" && sha256sum -c -)
  tar -xzf "$tmp/$file" -C "$tmp" actionlint
  install -m 0755 "$tmp/actionlint" /usr/local/bin/actionlint
fi

shellcheck --version | grep '^version:'
actionlint --version | head -n1
echo "lint: pronto (shellcheck ${SC_VERSION}, actionlint ${AL_VERSION})"
