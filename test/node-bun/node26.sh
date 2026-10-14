#!/bin/bash
set -e
source dev-container-features-test-lib

check "node 26" bash -c "node --version | grep -q ^v26\\."

reportResults
