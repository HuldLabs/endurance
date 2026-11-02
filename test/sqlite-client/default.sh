#!/bin/bash
set -e
source dev-container-features-test-lib

# Prova o binario e uma ida e volta num banco temporario.
check "sqlite3 presente" bash -c "sqlite3 --version"
check "le e grava" bash -c "db=\$(mktemp); sqlite3 \"\$db\" 'create table t(x); insert into t values (42);' && [ \"\$(sqlite3 \"\$db\" 'select x from t')\" = 42 ]; rm -f \"\$db\""

reportResults
