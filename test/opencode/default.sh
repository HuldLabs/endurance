#!/bin/bash
set -e
source dev-container-features-test-lib

check "opencode 1.18.29" bash -c "[ \"\$(opencode --version)\" = 1.18.29 ]"
check "opencode resolve os caminhos do dev" bash -c "opencode debug paths | grep -q '^data .*/home/dev/.local/share/opencode'"

reportResults
