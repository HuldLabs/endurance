#!/bin/bash
set -e
source dev-container-features-test-lib

check "shellcheck 0.11.0" bash -c "shellcheck --version | grep -qx 'version: 0.11.0'"
check "shellcheck acha erro" bash -c "printf '#!/bin/sh\necho \$1\n' > /tmp/x.sh; ! shellcheck /tmp/x.sh"
check "actionlint 1.7.12" bash -c "actionlint --version | head -n1 | grep -qx 1.7.12"

reportResults
