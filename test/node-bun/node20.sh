#!/bin/bash
set -e
source dev-container-features-test-lib

check "node 20" bash -c "node --version | grep -q ^v20\\."

reportResults
