#!/usr/bin/env bash
# Feature secrets: FINA (D4/R5). So' liga o helper do git no `tars secrets`, que vem da base
# (D17). Cofre, cache cifrado, token da service account e a lista de hosts que recebem
# credencial sao do `[secrets]` do `.ai/tars.toml` do PROJETO — nunca daqui.
#
# O tars dev.19 so' entrega credencial para host declarado em `[secrets].git_hosts`, lendo a
# chave do cache nomeada em `[secrets].git_credential`. Host fora da lista: nada.
# Guia: HuldLabs/tars docs/adocao.md §3 passo 4 (tag v0.0.1-dev.19, 974028a).
set -euo pipefail

command -v tars >/dev/null 2>&1 || {
  echo "secrets: 'tars' ausente — use a base do Endurance (o tars e' peca da base, D17)." >&2
  exit 1
}

# Nivel SISTEMA e para TODO host: vale em qualquer repo do container (F2). Quem filtra o
# host e' o `git_hosts` do projeto, nao esta linha. `--replace-all`: idempotente.
git config --system --replace-all credential.helper '!tars secrets git-credential'

echo "secrets: pronto (credential.helper do sistema = tars secrets git-credential)"
