#!/bin/bash
set -e
source dev-container-features-test-lib

check "restic 0.19.1" bash -c "restic version | grep -q '^restic 0.19.1 '"
check "rclone 1.75.2" bash -c "rclone version | head -n1 | grep -qx 'rclone v1.75.2'"

reportResults
