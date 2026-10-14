#!/bin/bash
set -e
source dev-container-features-test-lib

check "node 24" bash -c "node --version | grep -q ^v24\\."

reportResults
