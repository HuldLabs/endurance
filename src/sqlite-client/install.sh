#!/usr/bin/env bash
# Feature sqlite-client: o shell `sqlite3` da distro.
#
# POR QUE O apt DA DISTRO: o SQLite e' biblioteca embutida em cada projeto (rusqlite bundled, sqlite3 do Python);
# o shell so le e consulta o arquivo, e o formato de disco e' estavel desde a 3.0. Nao ha servidor para casar versao.
#
# Idempotente: se o sqlite3 ja existe, nao faz nada.
set -euo pipefail

if command -v sqlite3 >/dev/null 2>&1; then
  echo "sqlite-client: ja instalado ($(sqlite3 --version | awk '{print $1}'))"
  exit 0
fi

apt-get update
apt-get install -y --no-install-recommends sqlite3
rm -rf /var/lib/apt/lists/*

sqlite3 --version
echo "sqlite-client: pronto"
