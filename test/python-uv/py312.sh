#!/bin/bash
set -e
source dev-container-features-test-lib

check "venv 3.12" bash -c "/workspace/.venv/bin/python --version | grep -q '^Python 3.12\\.'"

check "profile nao exporta UV_PYTHON_INSTALL_DIR do root" bash -lc '[ -z "${UV_PYTHON_INSTALL_DIR:-}" ]'

reportResults
