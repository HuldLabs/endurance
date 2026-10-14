#!/bin/bash
set -e
source dev-container-features-test-lib

check "valkey-cli" valkey-cli --version
check "redis-cli" redis-cli --version

reportResults
