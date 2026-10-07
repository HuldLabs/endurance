#!/usr/bin/env bash
# Feature playwright: as bibliotecas de SISTEMA do Chromium e o browser.
#
# Por que isto e' uma feature e nao um passo do projeto: `playwright install --with-deps`
# roda `apt-get` e portanto exige ROOT. O post-create do projeto roda como o usuario do
# container (uid 1000) e nao pode — sem esta feature o e2e so' quebra na hora de abrir o
# browser, com "Host system is missing dependencies", longe da causa (o passo que faltou).
#
# A lista de pacotes NAO esta escrita aqui: vem do `install-deps` DA VERSAO pedida. Sao
# ~40 nomes que mudam de forma por distro (`libasound2` x `libasound2t64`, `libicu70` x
# `libicu76`) e a cada bump — uma copia envelheceria em SILENCIO.
#
# Idempotente: `install-deps` e `install` sao baratos quando ja esta tudo no lugar.
set -euo pipefail

PLAYWRIGHT_VERSION="${VERSION:-1.63.0}"
BROWSER="${BROWSER:-chromium}"
USERNAME="${_REMOTE_USER:-dev}"

command -v npx >/dev/null 2>&1 || {
  echo "playwright: 'npx' ausente — ligue a feature node-bun ANTES desta (installsAfter)." >&2
  exit 1
}

# Um browser por vez: o `--with-deps` de varios browsers num so' apt-get e' menos legivel
# no log e a lista completa raramente e' querida.
IFS=',' read -r -a BROWSERS <<< "$BROWSER"
for b in "${BROWSERS[@]}"; do
  [ -n "$b" ] || continue
  apt-get update
  npx --yes "playwright@${PLAYWRIGHT_VERSION}" install-deps "$b"
  rm -rf /var/lib/apt/lists/*
done
npm cache clean --force

# Browser em pasta de CACHE do container, a mesma que o projeto usa. Sem
# PLAYWRIGHT_BROWSERS_PATH o Playwright escreve em ~/.cache/ms-playwright do usuario que
# chamou, e um rebuild/volume novo obriga a baixar ~150 MB de novo. O perfil e' lido por
# qualquer shell, entao o `playwright install` do projeto acha o mesmo diretorio.
cat > /etc/profile.d/endurance-playwright.sh <<'EOF'
export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-/workspace/.cache/ms-playwright}"
EOF
chmod 0644 /etc/profile.d/endurance-playwright.sh
mkdir -p /workspace/.cache/ms-playwright
chown -R "$USERNAME:$USERNAME" /workspace/.cache 2>/dev/null || true

# Browser ja' instalado: roda como o usuario do container — o dono dos arquivos tem de ser
# quem vai usa-los, senao a primeira execucao do e2e falha por permissao no cache.
if [ -w /workspace/.cache ]; then
  su "$USERNAME" -c "PLAYWRIGHT_BROWSERS_PATH=/workspace/.cache/ms-playwright \
    npx --yes 'playwright@${PLAYWRIGHT_VERSION}' install ${BROWSER//,/ }" || \
    echo "playwright: AVISO: o download do browser falhou (rode 'npx playwright install ${BROWSER//,/ }' na mao)" >&2
fi

echo "playwright: pronto (playwright $PLAYWRIGHT_VERSION, browser=$BROWSER, cache=/workspace/.cache/ms-playwright)"
