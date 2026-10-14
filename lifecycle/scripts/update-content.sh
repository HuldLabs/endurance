#!/usr/bin/env bash
# Roda a CADA mudanca de conteudo do workspace (updateContentCommand), separado do
# onCreate — o hook que o segtools nao tinha (farmega/.devcontainer/devcontainer.json:32).
#
# Duas responsabilidades, nesta ordem:
#
# 1. VENV ORFAO (ideia de farmega/.devcontainer/scripts/update-content.sh:6-31).
#    O `.venv` de um projeto Python e' um VOLUME NOMEADO, e volume nomeado sobrevive a
#    rebuild. Se ele nasceu com outro interpretador (a option pythonVersion mudou) ou
#    ficou pela metade, o binario de dentro aponta para um python que nao existe mais: o
#    `uv sync` seguinte falha com um erro de symlink, longe da causa. Aqui o venv e'
#    PROVADO executando o interpretador; se nao responde, e' removido para nascer outro.
#
# 2. SYNC (idempotente). So' quando ha lockfile — o projeto declara a versao, a feature
#    obedece.
#
# Uso (devcontainer.json do projeto):
#   "updateContentCommand": "bash .devcontainer/scripts/update-content.sh"
set -euo pipefail

cd "${1:-/workspace}"
log() { echo "[update-content] $*"; }

# ---------------------------------------------------------------- .venv (so' Python)
if [ -d .venv ] && [ ! -x .venv/bin/python ]; then
  # Julga pelo que o proprio venv diz: `pyvenv.cfg` aponta o interpretador de origem.
  # Um venv sem ele, ou cujo python nao executa, esta' orfao.
  PY=""
  [ -f .venv/bin/python ] && PY=".venv/bin/python"
  [ -z "$PY" ] && [ -f .venv/bin/python3 ] && PY=".venv/bin/python3"

  if [ -z "$PY" ] || ! "$PY" -c 'import sys' >/dev/null 2>&1; then
    log "venv orfao (sem interpretador executavel) — removendo para o uv recriar."
    rm -rf .venv
  fi
fi

# --------------------------------------------------------------------------- sync
command -v uv >/dev/null 2>&1 || exit 0

if [ -f uv.lock ]; then
  log "uv sync --frozen (uv.lock presente)"
  uv sync --frozen || log "AVISO: uv sync --frozen falhou — rode 'uv sync' na mao."
elif [ -f pyproject.toml ] && [ ! -d .venv ]; then
  log "uv sync (sem lock; criando o venv)"
  uv sync || log "AVISO: uv sync falhou — rode 'uv sync' na mao."
fi
