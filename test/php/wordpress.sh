#!/bin/bash
set -e
source dev-container-features-test-lib

check "php 8.3" bash -c "php -r 'echo PHP_MAJOR_VERSION.\".\".PHP_MINOR_VERSION;' | grep -qx 8.3"
check "mysqli" bash -c "php -m | grep -qx mysqli"
check "composer" bash -c "composer --version | grep -q 2.10.3"
check "wp-cli" bash -c "wp --version | grep -q 2.12.0"

reportResults
