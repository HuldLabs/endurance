#!/usr/bin/env bash
# Feature agent-browser: a CLI `agent-browser` (vercel-labs/agent-browser, npm) que dirige
# o Chrome por CDP. E' o que abre paginas que bloqueiam HTTP simples (Ahrefs, Semrush atras
# do Cloudflare) para os subagentes pesquisadores do seo-brain.
#
# Usa o Chrome REAL do SISTEMA (feature playwright com browser=chrome) — NUNCA roda o
# `agent-browser install`, que baixaria um segundo browser e duplicaria a playwright.
#
# SESSAO E' CREDENCIAL: o `--session-name` grava cookies logados em ~/.agent-browser/ do
# usuario. O projeto monta ali um volume nomeado POR USUARIO E PROJETO (nunca compartilhado,
# nunca na imagem). O `--profile` do Chrome do dono nunca entra em container de automacao
# (decisoes-20261008, item 4).
#
# Idempotente: se a versao pedida ja existe, so' regrava o perfil de shell.
set -euo pipefail

AB_VERSION="${VERSION:-0.39.1}"
USERNAME="${_REMOTE_USER:-dev}"

command -v npm >/dev/null 2>&1 || {
  echo "agent-browser: 'npm' ausente — ligue a feature node-bun ANTES desta (installsAfter)." >&2
  exit 1
}
command -v google-chrome >/dev/null 2>&1 || {
  echo "agent-browser: 'google-chrome' ausente — ligue a playwright com browser=chrome ANTES desta." >&2
  exit 1
}

if ! agent-browser --version 2>/dev/null | grep -q " ${AB_VERSION}$"; then
  npm install -g "agent-browser@${AB_VERSION}"
  npm cache clean --force
fi

# O Chrome do sistema e o `--no-sandbox` vao pelo `containerEnv` do devcontainer-feature.json
# (todo processo do container, inclusive shell NAO-login do agente) — nao por /etc/profile.d,
# que so' shell de login le. Sem sandbox do Chrome: no container nao ha user namespaces para
# ele, e o isolamento e' o proprio container. Aqui so' se confere que o caminho bate.
[ "$(command -v google-chrome)" = /usr/bin/google-chrome ] || {
  echo "agent-browser: google-chrome fora de /usr/bin (containerEnv aponta para la')" >&2
  exit 1
}
# Pasta da sessao com o dono e o modo certos, para o volume montado por cima herdar.
home="$(getent passwd "$USERNAME" | cut -d: -f6)"
install -d -m 0700 -o "$USERNAME" -g "$USERNAME" "$home/.agent-browser"

agent-browser --version
echo "agent-browser: pronto ($AB_VERSION, chrome=$(command -v google-chrome), sessao=$home/.agent-browser)"
