#!/bin/bash
set -e
source dev-container-features-test-lib

# Sem servico: o compose do projeto e' quem sobe o Postgres (R4). Prova versao dos dois binarios.
check "psql 17" bash -c "psql --version | grep -q '(PostgreSQL) 17\\.'"
check "pg_dump 17" bash -c "pg_dump --version | grep -q '(PostgreSQL) 17\\.'"

reportResults
