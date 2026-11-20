#!/bin/bash
# Volume nomeado com venv de OUTRO python (consumidor de 20/11/2026: 3.13 -> 3.15.2): o symlink do
# interpretador quebra e o `uv` falha. Simula quebrando o symlink e roda o check do postStart.
set -e
source dev-container-features-test-lib

ln -sfn /nao/existe/python /workspace/.venv/bin/python
check "venv quebrado de fato" bash -c "! /workspace/.venv/bin/python -V"
check "check refaz o venv" endurance-venv-check
check "python do venv = pythonVersion" bash -c "/workspace/.venv/bin/python -c 'import sys; assert sys.version_info[:2] == (3, 13), sys.version'"
check "segunda rodada nao mexe (idempotente)" bash -c "endurance-venv-check | grep -q 'venv ok'"

reportResults
