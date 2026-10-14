#!/usr/bin/env bash
# Prova que o gen-catalogo.sh reprova ARG de versao/imagem sem `# catalogo:` (inclusive sem
# default e indentado) e aceita o Dockerfile real.
set -euo pipefail
cd "$(dirname "$0")/.."
t="$(mktemp)"; trap 'rm -f "$t"' EXIT
bash tools/gen-catalogo.sh --check
for caso in 'ARG FOO_VERSION' '  ARG BAR_IMAGE=x' 'ARG BAZ_VERSION=1'; do
  { cat images/base/Dockerfile; printf '%s\n' "$caso"; } > "$t"
  if ENDURANCE_DOCKERFILE="$t" bash tools/gen-catalogo.sh --check >/dev/null 2>&1; then
    echo "FALHOU: '$caso' sem marcador passou" >&2; exit 1
  fi
done
echo "gen-catalogo.test: ok"
