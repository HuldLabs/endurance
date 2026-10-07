#!/usr/bin/env bash
# Feature postgres-client: psql + pg_dump do major pedido, do repositorio PGDG.
#
# POR QUE NAO O apt DA DISTRO: o psql da trixie e' o 15, e o pg_dump 15 RECUSA um servidor
# 18 ("server version mismatch"). O major do cliente precisa ser >= o major do servidor do
# projeto — e o projeto declara esse major nesta option. Sintoma do descasamento aparece
# longe da causa (no dump, nao no build), por isso o major e' explicito aqui.
#
# Idempotente: se o binario pedido ja existe, nao faz nada.
set -euo pipefail

PG_VERSION="${VERSION:-18}"

if command -v psql >/dev/null 2>&1 \
   && [ "$(psql --version | awk '{print $3}' | cut -d. -f1)" = "$PG_VERSION" ]; then
  echo "postgres-client: psql $PG_VERSION ja instalado"
  exit 0
fi

# Repositorio PGDG, com a chave de assinatura verificada. Nao usamos o psql da distro
# porque o major dele segue a distro, nao o projeto.
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    | gpg --dearmor -o /usr/share/keyrings/pgdg.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pgdg.gpg] \
https://apt.postgresql.org/pub/repos/apt $(. /etc/os-release && echo "$VERSION_CODENAME")-pgdg main" \
    > /etc/apt/sources.list.d/pgdg.list
apt-get update
apt-get install -y --no-install-recommends "postgresql-client-${PG_VERSION}"
rm -rf /var/lib/apt/lists/*

psql --version
pg_dump --version
echo "postgres-client: pronto (major $PG_VERSION)"
