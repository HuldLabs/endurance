#!/bin/bash
set -e
source dev-container-features-test-lib

check "ss" bash -c "ss -ltn >/dev/null"
check "strace" bash -c "strace -V | grep -q strace"
check "lsof" bash -c "lsof -v 2>&1 | grep -qi revision"
check "perf" bash -c "command -v perf"
check "iostat" bash -c "iostat -V 2>&1 | grep -q sysstat"
check "zstd ida e volta" bash -c "f=\$(mktemp); echo endurance > \$f; zstd -q \$f -o \$f.zst && [ \"\$(zstd -dc \$f.zst)\" = endurance ]; rm -f \$f \$f.zst"
check "hyperfine" bash -c "hyperfine --runs 3 'true' >/dev/null"

reportResults
