#!/usr/bin/env bash
# Feature redis-client: `valkey-cli` (e `redis-cli`) para falar com o Valkey/Redis do
# compose do projeto (o SERVIDOR fica no compose, nunca na imagem).
#
# Valkey e' o fork de licenca aberta do Redis e fala o mesmo protocolo: um cliente serve
# os dois (Fabber usa valkey 8, segtools usa redis 7). Pacote da distro.
#
# Idempotente: se o cliente ja existe, nao faz nada.
set -euo pipefail

if ! command -v valkey-cli >/dev/null 2>&1; then
  apt-get update
  apt-get install -y --no-install-recommends valkey-tools
  rm -rf /var/lib/apt/lists/*
fi
# `redis-cli` e' o nome que scripts e docs usam; o mesmo binario atende.
command -v redis-cli >/dev/null 2>&1 || ln -s "$(command -v valkey-cli)" /usr/local/bin/redis-cli

valkey-cli --version
echo "redis-client: pronto"
