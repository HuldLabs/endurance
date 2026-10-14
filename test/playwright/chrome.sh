#!/bin/bash
set -e
source dev-container-features-test-lib

check "google-chrome real" bash -c "google-chrome --version | grep -q 'Google Chrome'"
check "sem chromium baixado (so chrome)" bash -c "! ls /workspace/.cache/ms-playwright/chromium-* 2>/dev/null"

reportResults
