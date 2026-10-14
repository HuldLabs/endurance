#!/bin/bash
set -e
source dev-container-features-test-lib

check "kubectl 1.37.1" bash -c "kubectl version --client | grep -qx 'Client Version: v1.37.1'"
check "helm 4.3.0" bash -c "helm version --template '{{.Version}}' | grep -qx v4.3.0"

reportResults
