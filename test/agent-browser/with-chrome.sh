#!/bin/bash
set -e
source dev-container-features-test-lib

check "versao" agent-browser --version
check "chrome do sistema" bash -c '[ "$AGENT_BROWSER_EXECUTABLE_PATH" = "$(command -v google-chrome)" ]'
check "abre pagina e le titulo" bash -c 'agent-browser open "data:text/html,<title>endurance-ok</title>" && agent-browser get title | grep -q endurance-ok; r=$?; agent-browser close >/dev/null 2>&1; exit $r'
check "sessao 0700 do dev" bash -c '[ "$(stat -c %a:%U ~/.agent-browser)" = "700:dev" ]'

reportResults
