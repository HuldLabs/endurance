#!/usr/bin/env bash
# Feature tars: o binario do assistente, do Release do HuldLabs/tars.
#
# O binario NAO e' versionado nem embutido na imagem: ele sai do Release, entao a versao
# pedida e' a que roda. Atualizar o TARS num projeto e' trocar a option, nao reconstruir
# imagem.
#
# Idempotente: a versao pedida ja' no PATH (e' a mesma) faz o install sair sem rede.
set -euo pipefail

TARS_VERSION="${VERSION:-latest}"
TARS_REPO="${REPO:-HuldLabs/tars}"

# Plataforma do Release no formato `uname`: linux-x86_64 / linux-aarch64.
case "$(dpkg --print-architecture)" in
  amd64) TARS_ARCH=x86_64 ;;
  arm64) TARS_ARCH=aarch64 ;;
  *) echo "tars: arquitetura nao suportada: $(dpkg --print-architecture)" >&2; exit 1 ;;
esac

if [ "$TARS_VERSION" = "latest" ]; then
  TARS_URL="https://github.com/${TARS_REPO}/releases/latest/download/tars-linux-${TARS_ARCH}"
else
  TARS_URL="https://github.com/${TARS_REPO}/releases/download/${TARS_VERSION}/tars-linux-${TARS_ARCH}"
fi

if command -v tars >/dev/null 2>&1 && [ "$TARS_VERSION" != "latest" ]; then
  # Com versao EXATA, o que ja' esta no PATH serve: nao ha o que perguntar ao Release.
  echo "tars: $TARS_VERSION ja instalado"
  exit 0
fi

curl -fsSL "$TARS_URL" -o /usr/local/bin/tars
chmod 0755 /usr/local/bin/tars
tars --version 2>/dev/null || echo "tars: binario instalado (sem --version)"
echo "tars: pronto ($TARS_REPO @ $TARS_VERSION)"
