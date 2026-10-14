#!/bin/bash
set -e
source dev-container-features-test-lib

check "gh 2.102.0" bash -c "gh --version | grep -q 'gh version 2.102.0 '"

reportResults
