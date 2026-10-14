#!/bin/bash
set -e
source dev-container-features-test-lib

# Projeto FORA de /workspace: prova que o uv segue UV_PROJECT_ENVIRONMENT (venvPath) e nao
# cria `.venv` no diretorio do projeto (no bind do repo, esse `.venv` e' o do host).
proj="$(mktemp -d)"
cat > "$proj/pyproject.toml" <<'TOML'
[project]
name = "prova"
version = "0.0.0"
requires-python = ">=3.12"
dependencies = []
TOML

check "containerEnv (shell nao-login)" bash -c '[ "$UV_PROJECT_ENVIRONMENT" = /workspace/.venv ]'
check "profile (shell de login)" bash -lc '[ "$UV_PROJECT_ENVIRONMENT" = /workspace/.venv ]'
check "uv sync como dev" bash -c "[ \"\$(id -un)\" = dev ] && cd '$proj' && uv sync --offline -q"
check "sem .venv no projeto" bash -c "[ ! -e '$proj/.venv' ]"
check "venvPath usado" bash -c "[ -f /workspace/.venv/pyvenv.cfg ] && cd '$proj' && uv run --offline python -c 'import sys; assert sys.prefix == \"/workspace/.venv\", sys.prefix'"

reportResults
