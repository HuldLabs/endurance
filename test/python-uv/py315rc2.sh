#!/bin/bash
set -e
source dev-container-features-test-lib

check "venv 3.15.0rc2" bash -c "/workspace/.venv/bin/python --version | grep -qx 'Python 3.15.0rc2'"

reportResults
