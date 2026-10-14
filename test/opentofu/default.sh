#!/bin/bash
set -e
source dev-container-features-test-lib

check "tofu 1.13.1" bash -c "tofu version | head -n1 | grep -qx 'OpenTofu v1.13.1'"

reportResults
