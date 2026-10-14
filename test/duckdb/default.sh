#!/bin/bash
set -e
source dev-container-features-test-lib

check "duckdb 1.5.6" bash -c "duckdb --version | grep -q '^v1.5.6 '"
check "duckdb consulta" bash -c "duckdb -c 'select 41+1' | grep -q 42"

reportResults
