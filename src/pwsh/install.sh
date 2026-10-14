#!/usr/bin/env bash
# Feature pwsh: PowerShell 7 do tarball oficial (GitHub Releases), versao fixa, conferido
# pelo `hashes.sha256` do proprio release. Para o dotfiles (~50 scripts .ps1).
#
# Tarball em vez do repositorio apt da Microsoft: um so' caminho para amd64 e arm64, e a
# versao e' a da option, nao a ultima que o repo tiver.
#
# Idempotente: se o pwsh pedido ja existe, nao faz nada.
set -euo pipefail

PWSH_VERSION="${VERSION:-7.6.6}"

if command -v pwsh >/dev/null 2>&1 && pwsh -NoLogo -Command '$PSVersionTable.PSVersion.ToString()' | grep -qx "$PWSH_VERSION"; then
  echo "pwsh: $PWSH_VERSION ja instalado"
  exit 0
fi

case "$(dpkg --print-architecture)" in
  amd64) ARCH=x64 ;;
  arm64) ARCH=arm64 ;;
  *) echo "pwsh: arquitetura nao suportada: $(dpkg --print-architecture)" >&2; exit 1 ;;
esac

# Dependencias de runtime do .NET (libicu para globalizacao).
apt-get update
apt-get install -y --no-install-recommends ca-certificates libicu76 libssl3t64 zlib1g
rm -rf /var/lib/apt/lists/*

file="powershell-${PWSH_VERSION}-linux-${ARCH}.tar.gz"
base="https://github.com/PowerShell/PowerShell/releases/download/v${PWSH_VERSION}"
curl -fsSL "$base/$file" -o "/tmp/$file"
# O hashes.sha256 do release e' UTF-16 com CRLF (gerado no Windows): converte antes de ler.
curl -fsSL "$base/hashes.sha256" | iconv -f UTF-16 -t UTF-8 | tr -d '\r' \
  | grep " \*\?${file}$" | (cd /tmp && sha256sum -c -)

dest="/opt/microsoft/powershell/7"
rm -rf "$dest" && mkdir -p "$dest"
tar -xzf "/tmp/$file" -C "$dest"
rm -f "/tmp/$file"
chmod 0755 "$dest/pwsh"
ln -sf "$dest/pwsh" /usr/local/bin/pwsh

pwsh -NoLogo -Command '$PSVersionTable.PSVersion.ToString()'
echo "pwsh: pronto ($PWSH_VERSION)"
