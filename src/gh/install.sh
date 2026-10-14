#!/usr/bin/env bash
# Feature gh: GitHub CLI do repositorio apt OFICIAL (cli.github.com/packages), versao fixa
# pela option. O apt confere a assinatura do repo com a chave publicada pelo proprio
# cli.github.com (instrucoes oficiais: github.com/cli/cli/blob/trunk/docs/install_linux.md).
# Substitui ghcr.io/devcontainers/features/github-cli (segtools usava 2.101.0).
#
# Idempotente: se o gh da versao pedida ja existe, nao faz nada.
set -euo pipefail

GH_VERSION="${VERSION:-2.102.0}"

if command -v gh >/dev/null 2>&1 && gh --version | head -n1 | grep -q "gh version ${GH_VERSION} "; then
  echo "gh: ${GH_VERSION} ja instalado"
  exit 0
fi

KEYRING=/etc/apt/keyrings/githubcli-archive-keyring.gpg
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o "$KEYRING"
chmod 0644 "$KEYRING"
echo "deb [arch=$(dpkg --print-architecture) signed-by=$KEYRING] https://cli.github.com/packages stable main" \
  > /etc/apt/sources.list.d/github-cli.list

apt-get update
apt-get install -y --no-install-recommends --allow-downgrades "gh=${GH_VERSION}"
rm -rf /var/lib/apt/lists/*

gh --version | head -n1
echo "gh: pronto (${GH_VERSION})"
