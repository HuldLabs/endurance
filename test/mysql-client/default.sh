#!/bin/bash
set -e
source dev-container-features-test-lib

check "mysql" mysql --version
check "mysqldump" mysqldump --version

reportResults
