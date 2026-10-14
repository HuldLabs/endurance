#!/bin/bash
set -e
source dev-container-features-test-lib

check "node" node --version
check "npm" npm --version
check "sem bun" bash -c "! command -v bun"

reportResults
