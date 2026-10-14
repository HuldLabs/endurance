#!/bin/bash
set -e
source dev-container-features-test-lib

check "sem checkout falha alto" bash -c 'tars --version 2>&1 | grep -q "checkout do Tars ausente"'
# Checkout falso minimo: o shim tem de executar o tars.mjs de TARS_HOME com os argumentos.
check "roda o tars.mjs de TARS_HOME" bash -c 'd=$(mktemp -d) && mkdir -p $d/tools/framework && echo "console.log(\"tars-fake \" + process.argv.slice(2).join(\" \"))" > $d/tools/framework/tars.mjs && TARS_HOME=$d tars --version | grep -qx "tars-fake --version"'

reportResults
