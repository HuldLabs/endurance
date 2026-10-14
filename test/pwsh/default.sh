#!/bin/bash
set -e
source dev-container-features-test-lib

check "pwsh 7.6.6" bash -c "pwsh -NoLogo -c '\$PSVersionTable.PSVersion.ToString()' | grep -qx 7.6.6"

reportResults
