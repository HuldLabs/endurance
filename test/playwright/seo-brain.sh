#!/bin/bash
set -e
source dev-container-features-test-lib

# Os quatro motores REAIS que o coletor do seo-brain roda (ADR-006 de la'): o UA vem do
# proprio motor, nunca spoofado.
check "google-chrome" bash -c "google-chrome --version | grep -q 'Google Chrome'"
check "microsoft-edge" bash -c "microsoft-edge --version | grep -q 'Microsoft Edge'"
check "firefox do playwright" bash -c "ls -d /workspace/.cache/ms-playwright/firefox-*"
check "webkit do playwright" bash -c "ls -d /workspace/.cache/ms-playwright/webkit-*"

reportResults
