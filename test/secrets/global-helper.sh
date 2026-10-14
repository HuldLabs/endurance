#!/bin/bash
set -e
source dev-container-features-test-lib

check "helper no git do sistema" bash -c 'git config --system --get credential.helper | grep -qx "!tars secrets git-credential"'
check "sem logica propria de segredo" bash -c 'for f in git-credential-op.sh op-sops.sh gh-op.sh secrets-exec secrets-refresh signing-write-key; do [ ! -e /usr/local/bin/$f ] || exit 1; done'
# Repo QUALQUER (nao o do projeto): o git tem de chegar ao tars. Sem `[secrets]` declarado o
# tars recusa alto, nomeando o campo — e' essa recusa que prova o caminho.
check "helper chega ao tars fora do repo do projeto" bash -c 'd=$(mktemp -d) && git -C "$d" init -q && cd "$d" && printf "protocol=https\nhost=github.com\n\n" | GIT_TERMINAL_PROMPT=0 git credential fill 2>&1 | grep -q "tars secrets: \[secrets\] source"'

reportResults
