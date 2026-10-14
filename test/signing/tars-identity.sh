#!/bin/bash
set -e
source dev-container-features-test-lib

check "sem logica propria de assinatura" bash -c 'for f in ssh-agent-init signing-git-config signing-write-key; do [ ! -e /usr/local/bin/$f ] || exit 1; done'
# O que o postStart chama, num repo qualquer: sign-setup escreve a config, verify sem
# identidade falha ALTO nomeando o comando do dono (automacao nunca se auto-provisiona).
check "sign-setup configura gpg.format=ssh" bash -c 'd=$(mktemp -d) && git -C "$d" init -q && cd "$d" && tars identity sign-setup >/dev/null && [ "$(git config gpg.format)" = ssh ]'
check "verify sem identidade falha alto" bash -c 'd=$(mktemp -d) && git -C "$d" init -q && cd "$d" && ! tars identity verify >/tmp/v.out 2>&1 && grep -q "tars identity provision" /tmp/v.out'

reportResults
