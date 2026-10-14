#!/usr/bin/env bash
# Feature signing: FINA (D4/R5). Nao instala nada de assinatura: o `tars identity` (da base,
# D17) e' quem escreve a config do git e confere a identidade, no postStartCommand do
# devcontainer-feature.json (rodar no build nao serve: a arvore do projeto so' existe em
# runtime). Guia: HuldLabs/tars docs/identity.md e docs/adocao.md §3 passo 5 (v0.0.1-dev.19).
#
# Por que o postStart NAO aborta quando o verify falha: sem identidade provisionada o
# container tem de subir mesmo assim (o dono provisiona DE DENTRO dele, com TTY). A falha
# fica alta no log e o `commit.gpgsign=true` faz o commit falhar, nunca sair sem assinatura.
# Por isso o gpgsign e' ligado AQUI, no sistema e no build: nao depende do sign-setup dar certo
# nem do cwd do postStart ser raiz de repo. O postStart tem `timeout`: sem TTY, nada pode pendurar.
set -euo pipefail

command -v tars >/dev/null 2>&1 || {
  echo "signing: 'tars' ausente — use a base do Endurance (o tars e' peca da base, D17)." >&2
  exit 1
}
command -v ssh-keygen >/dev/null 2>&1 || {
  echo "signing: ssh-keygen ausente (o git assina por ssh-keygen -Y sign)." >&2
  exit 1
}

git config --system commit.gpgsign true

echo "signing: pronto (postStart: tars identity sign-setup + verify)"
