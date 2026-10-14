#!/usr/bin/env bash
# Casos simulados do tars-atual.sh (sem rede): em dia, atrasado (aviso x --strict), digest divergente,
# pre-release anterior a final.
set -euo pipefail
cd "$(dirname "$0")/.."
t="$(mktemp)"; trap 'rm -f "$t"' EXIT
D1=sha256:1111111111111111111111111111111111111111111111111111111111111111
D2=sha256:2222222222222222222222222222222222222222222222222222222222222222
printf 'ARG TARS_IMAGE=ghcr.io/huldlabs/tars:0.0.1-dev.22@%s\n' "$D1" > "$t"
run() { ENDURANCE_DOCKERFILE="$t" TARS_LATEST="$1" TARS_LATEST_DIGEST="$D2" TARS_DECLARED_DIGEST="$2" bash tools/tars-atual.sh "${@:3}"; }
espera() { # rc esperado, texto esperado, args...
  local rc=0 out; out="$(run "${@:3}" 2>&1)" || rc=$?
  [ "$rc" = "$1" ] && grep -q -- "$2" <<<"$out" || { echo "FALHOU ($*): rc=$rc saida=$out" >&2; exit 1; }
}
espera 0 'em dia' 0.0.1-dev.22 "$D1"
espera 0 'em dia' 0.0.1-dev.22 "$D1" --strict
espera 0 'em dia' 0.0.1-dev.9 "$D1" --strict           # dev.9 < dev.22 (ordem numerica)
espera 0 '::warning::tars atrasado' 0.0.1-dev.23 "$D1"
espera 1 '::error::tars atrasado' 0.0.1-dev.23 "$D1" --strict
espera 1 '::error::tars atrasado' 0.0.1 "$D1" --strict  # final > pre-release
espera 1 '::error::ARG TARS_IMAGE fixa' 0.0.1-dev.22 "$D2"
espera 1 '::error::ARG TARS_IMAGE fixa' 0.0.1-dev.23 "$D2"  # digest divergente falha mesmo sem --strict
printf 'ARG TARS_IMAGE=ghcr.io/huldlabs/tars:0.0.1-dev.22\n' > "$t"
espera 1 'sem tag+digest' 0.0.1-dev.22 "$D1"
echo "tars-atual.test: ok"
