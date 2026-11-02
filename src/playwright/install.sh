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
  case "$b" in ""|chrome|msedge) continue ;; esac
  apt-get update
  npx --yes "playwright@${PLAYWRIGHT_VERSION}" install-deps "$b"
  rm -rf /var/lib/apt/lists/*
done

# Browser na IMAGEM, em /opt/ms-playwright (dono = usuario do container). NUNCA sob
# /workspace: no build o /workspace e' uma pasta da imagem, mas no container o bind do
# projeto a cobre e o browser baixado some (achado do Kerr no rc.1 da dev.7). O perfil e o
# containerEnv da feature apontam o PLAYWRIGHT_BROWSERS_PATH para ca', entao o
# `playwright install` do projeto acha o mesmo diretorio.
BROWSERS_DIR=/opt/ms-playwright
cat > /etc/profile.d/endurance-playwright.sh <<EOF
export PLAYWRIGHT_BROWSERS_PATH="\${PLAYWRIGHT_BROWSERS_PATH:-$BROWSERS_DIR}"
EOF
chmod 0644 /etc/profile.d/endurance-playwright.sh
install -d -o "$USERNAME" -g "$USERNAME" -m 755 "$BROWSERS_DIR"

# Chrome REAL (google-chrome-stable) e' do SISTEMA, nao do cache: o `install chrome` do
# Playwright roda o script oficial do Google (apt, /opt/google/chrome) e por isso exige
# ROOT — e' aqui, no build, nunca a mao com sudo (somem no rebuild). Motivo de existir: o
# coletor de SERP do seo-brain usa channel="chrome"; com o Chromium o Google responde
# blocked_by_google (portado do remendo segtools `22f4f5e6`). So' amd64: o Google nao
# publica .deb arm64.
#
# EXCECAO DELIBERADA de versao (como o `op` da base): os repos apt do Google e da Microsoft
# so' guardam a ULTIMA stable, entao nao ha' o que fixar — um pino quebraria o build quando
# ela sai do repo. A integridade vem da assinatura de cada repo (o .deb oficial registra a
# chave do fornecedor).
CACHE_BROWSERS=()
for b in "${BROWSERS[@]}"; do
  case "$b" in
    chrome|msedge)
      # Canais de SISTEMA (Google Chrome / Microsoft Edge estaveis): o `install <canal>` do
      # Playwright roda o .deb oficial de cada fornecedor. So' amd64.
      [ "$(dpkg --print-architecture)" = amd64 ] || {
        echo "playwright: browser=$b so' existe em amd64 (sem .deb arm64 do fornecedor)" >&2
        exit 1
      }
      bin=google-chrome; [ "$b" = msedge ] && bin=microsoft-edge
      if ! command -v "$bin" >/dev/null 2>&1; then
        apt-get update
        npx --yes "playwright@${PLAYWRIGHT_VERSION}" install --with-deps "$b"
        rm -rf /var/lib/apt/lists/*
      fi
      "$bin" --version ;;
    "") ;;
    *) CACHE_BROWSERS+=("$b") ;;
  esac
done
npm cache clean --force

# Browser ja' instalado: roda como o usuario do container — o dono dos arquivos tem de ser
# quem vai usa-los, senao a primeira execucao do e2e falha por permissao no cache.
# O `install chrome|msedge` acima roda como root e, com o PLAYWRIGHT_BROWSERS_PATH do
# containerEnv ja' valendo no build, grava ffmpeg e `.links` aqui como root: devolve a pasta
# ao usuario antes do install dele (achado do Kerr no rc.2 com "chromium,chrome").
chown -R "$USERNAME:$USERNAME" "$BROWSERS_DIR"
if [ "${#CACHE_BROWSERS[@]}" -gt 0 ]; then
  su "$USERNAME" -c "PLAYWRIGHT_BROWSERS_PATH=$BROWSERS_DIR \
    npx --yes 'playwright@${PLAYWRIGHT_VERSION}' install ${CACHE_BROWSERS[*]}" || {
    echo "playwright: ERRO: o download de ${CACHE_BROWSERS[*]} falhou (ver acima)" >&2
    exit 1
  }
fi

echo "playwright: pronto (playwright $PLAYWRIGHT_VERSION, browser=$BROWSER, cache=$BROWSERS_DIR)"
