#!/usr/bin/env bash
# Feature signing: commit assinado dentro do container.
#
# Portado da ideia de /benchmarks/fabber/.devcontainer/ssh-agent-init.sh + allowed_signers.
# Duas decisoes do original que valem a pena manter, e a razao de cada uma:
#
# 1. A chave NUNCA toca o disco: e' lida do cache sops (feature secrets) e injetada num
#    ssh-agent de caminho FIXO. O `write-signing-key` do segtools grava a chave em
#    arquivo — funciona, mas deixa a chave em repouso na arvore. O agente nao deixa.
#
# 2. O `allowed_signers` e' VERSIONADO no projeto. O host costuma apontar para um caminho
#    da maquina de alguem (C:/Users/...), que nao existe no container: toda assinatura
#    valida aparece como "unknown". O arquivo versionado e' o que faz o `%G?` responder
#    algo util.
#
# O que esta feature NAO faz: ler segredo no build. So' instala os scripts; o valor e'
# lido em RUNTIME pelo `secrets-exec` da feature secrets.
set -euo pipefail

AGENT_SOCKET="${AGENTSOCKET:-/tmp/endurance-ssh-agent.sock}"
ALLOWED_SIGNERS="${ALLOWEDSIGNERS:-}"
ALLOWED_SIGNERS_FILE="${ALLOWEDSIGNERSFILE:-.allowed_signers}"
USERNAME="${_REMOTE_USER:-dev}"

command -v ssh-agent >/dev/null 2>&1 || {
  echo "signing: ssh-agent ausente na imagem." >&2
  exit 1
}
[ -x /usr/local/bin/secrets-exec ] || {
  echo "signing: a feature 'secrets' precisa vir ANTES (installsAfter)." >&2
  exit 1
}

# ---------------------------------------------- allowed_signers (do projeto, versionado)
if [ -n "$ALLOWED_SIGNERS" ]; then
  printf '%s\n' "$ALLOWED_SIGNERS" > "/workspace/${ALLOWED_SIGNERS_FILE}"
  chown "$USERNAME:$USERNAME" "/workspace/${ALLOWED_SIGNERS_FILE}" 2>/dev/null || true
  chmod 0644 "/workspace/${ALLOWED_SIGNERS_FILE}"
fi

# ------------------------------------------------------------------------ ssh-agent-init
# Idempotente contra RESTART, nao so' contra chamada repetida: o arquivo do socket pode
# sobreviver ao processo do agente (o processo morre com o container, o arquivo nem
# sempre). Por isso "o socket existe?" NAO basta — o `ssh-add -l` responde com TRES
# significados, e so' um deles autoriza reuso:
#   0 = agente vivo COM chave   -> reusa
#   1 = agente vivo e VAZIO     -> carrega as chaves nele (nao reabre socket)
#   2 = agente inalcancavel     -> limpa o socket e abre um novo
# Tratar 1 como "reusa" e' o defeito sutil: um refresh falho deixa um agente vivo e vazio
# que passa a ser encontrado "vivo" para sempre, e o self-heal nunca cura.
#
# `|| status=$?` e' proposital: sob `set -e` um `ssh-add -l` retornando 1/2 mataria o
# script antes de olhar o codigo. Um `|| true` achataria tudo em 0 e traria o defeito de
# volta.
cat > /usr/local/bin/ssh-agent-init <<INIT
#!/usr/bin/env bash
set -euo pipefail
AGENT_SOCKET="\${ENDURANCE_SSH_AUTH_SOCK:-${AGENT_SOCKET}}"

status=0
ssh-add -l >/dev/null 2>&1 || status=\$?

case "\$status" in
  0) exit 0 ;;
  2) rm -f "\$AGENT_SOCKET"; ssh-agent -a "\$AGENT_SOCKET" >/dev/null ;;
esac

# A chave sai do CACHE sops (feature secrets) — nunca do 1Password a cada start, nunca
# impressa. O pipeline alimenta o `ssh-add -` por stdin.
if ! secrets-exec -- sh -c 'printf "%s" "\${GIT_SIGNING_KEY:-}"' | ssh-add - >/dev/null 2>&1; then
  echo "[signing] FATAL: a chave de assinatura nao carregou no agente." >&2
  echo "[signing] Rode 'secrets-refresh' (feature secrets) e reinicie o container." >&2
  exit 1
fi
echo "[signing] chave carregada em \$AGENT_SOCKET"
INIT
chmod 0755 /usr/local/bin/ssh-agent-init

# --------------------------------------------------------------------------- git config
# Aplicado SEMPRE, fora de qualquer `if`: e' o que transforma chave quebrada em commit que
# FALHA ALTO, em vez de commit sem assinatura e sem erro.
cat > /usr/local/bin/signing-git-config <<'CFG'
#!/usr/bin/env bash
# Chamado pelo post-create do projeto (ou na mao), depois do ssh-agent-init.
set -euo pipefail
TREE="${1:-/workspace}"
SOCKET="${ENDURANCE_SSH_AUTH_SOCK:-/tmp/endurance-ssh-agent.sock}"
FILE="${ENDURANCE_ALLOWED_SIGNERS_FILE:-.allowed_signers}"

git -C "$TREE" config gpg.format ssh
git -C "$TREE" config commit.gpgsign true
git -C "$TREE" config user.signingkey "$SOCKET"
if [ -f "$TREE/$FILE" ]; then
  git -C "$TREE" config gpg.ssh.allowedSignersFile "$TREE/$FILE"
fi
echo "[signing] git config: format=ssh, gpgsign=true, signingkey=$SOCKET"
CFG
chmod 0755 /usr/local/bin/signing-git-config

echo "signing: pronto (socket=$AGENT_SOCKET, allowed_signers=${ALLOWED_SIGNERS_FILE})"
