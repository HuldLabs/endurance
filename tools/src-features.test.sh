#!/usr/bin/env bash
# Toda pasta de src/ e' publicada como feature (devcontainers/action): sem devcontainer-feature.json o
# publish da tag falha depois de a base ja' ter subido. Pasta que nao e' feature fica fora de src/.
set -euo pipefail
cd "$(dirname "$0")/.."
falta=0
for d in src/*/; do
  [ -f "${d}devcontainer-feature.json" ] || { echo "sem devcontainer-feature.json: $d" >&2; falta=1; }
done
[ "$falta" = 0 ] && echo "src-features.test: ok"
exit "$falta"
