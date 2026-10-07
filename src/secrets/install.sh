#!/usr/bin/env bash
# Feature secrets: os tres scripts de credencial do ecossistema, genericamente.
#
# O que esta feature NAO faz: ler segredo nenhum no build. Ela instala os SCRIPTS e a
# fiacao; o valor so' e' lido em RUNTIME, quando o git/gh pedem a credencial.
#
# Separacao das fontes (o desenho todo depende disto):
#   * CACHE sops    -> o PAT e a chave de assinatura do DIA A DIA (rapido, local, cifrado)
#   * 1Password     -> a FONTE; so' e' tocado no REFRESH do cache (`secrets-refresh`)
#   * op-sops.sh    -> o unico que injeta o token da service account no `op`
# Trocar isso por `op read` a cada fetch/push (como era antes) faz todo `git fetch` pagar
# uma ida ao 1Password — e o 1Password tem limite de leitura na conta INTEIRA, nao por
# processo. Por isso os consumidores leem do CACHE, e nao do cofre.
set -euo pipefail

PROJECT="${PROJECT:-}"
PAT_REF="${PATREF:-}"
SIGNING_KEY_VAR="${SIGNINGKEYVAR:-GIT_SIGNING_KEY}"
USERNAME="${_REMOTE_USER:-dev}"

if [ -z "$PROJECT" ]; then
  echo "secrets: a option 'project' e' obrigatoria (ex.: \"secrets\": { \"project\": \"meusite\" })" >&2
  exit 1
fi
# Referencia padrao do PAT: o cofre E o projeto, pelo nome. Vazio aqui vira um fallback
# previsivel em vez de um op:// sem nome que falha so' no primeiro fetch.
[ -n "$PAT_REF" ] || PAT_REF="op://${PROJECT}/secrets-dev/github/${PROJECT}-pat-full"

BIN="/usr/local/bin"
CONF="/etc/endurance"
mkdir -p "$CONF"

# ---------------------------------------------------------------- configuracao (SSOT)
# UM arquivo com os nomes; os tres scripts o leem. Sem isso, o nome do projeto apareceria
# repetido em cada script e uma renomeacao deixaria copias divergentes.
cat > "$CONF/secrets.conf" <<EOF
ENDURANCE_PROJECT="${PROJECT}"
ENDURANCE_PAT_REF="${PAT_REF}"
ENDURANCE_SIGNING_KEY_VAR="${SIGNING_KEY_VAR}"
ENDURANCE_CACHE_DIR="\${ENDURANCE_CACHE_DIR:-\$HOME/.cache/${PROJECT}}"
ENDURANCE_TOKEN_FILE="\${ENDURANCE_TOKEN_FILE:-/run/op-token/token}"
EOF
chmod 0644 "$CONF/secrets.conf"

# ------------------------------------------------------------------------- op-sops.sh
# O UNICO lugar que posa o token da service account no `op`. Guarda RUIDOSA, sem fallback
# silencioso: um `op` sem token morre com "not signed in" generico, longe da causa (o
# volume nao semeado). "existe e nao posso ler" e' um estado DIFERENTE de "nao existe": o
# primeiro tem conserto mecanico imediato, o segundo e' o passo manual do bootstrap.
#
# O token vai por ENV DO PROCESSO do `op` (inevitavel — e' assim que a CLI o le), nunca
# como argumento de linha de comando e nunca impresso.
cat > "$BIN/op-sops.sh" <<'OP_SOPS'
#!/usr/bin/env bash
# Uso: op-sops.sh <args do op...>   Ex.: op-sops.sh read op://<cofre>/<item>/<campo>
set -euo pipefail
. /etc/endurance/secrets.conf
TOKEN_FILE="$ENDURANCE_TOKEN_FILE"

if [ ! -e "$TOKEN_FILE" ]; then
  echo "op-sops: FATAL: token da service account AUSENTE em $TOKEN_FILE" >&2
  echo "op-sops: este token E o unico passo manual do bootstrap (semeie o volume em 0400)." >&2
  exit 1
fi
if [ ! -r "$TOKEN_FILE" ]; then
  # Metadados de POSSE e MODO, nunca o conteudo: e' o que torna o diagnostico acionavel.
  echo "op-sops: FATAL: token existe mas NAO e legivel por $(id -un) (uid $(id -u))" >&2
  echo -n "op-sops: posse/modo atuais: " >&2; stat -c '%A %U:%G' "$TOKEN_FILE" >&2
  echo "op-sops: o volume foi semeado como root e o container roda como uid $(id -u)." >&2
  echo "op-sops: conserto (por FORA, o volume e por-maquina):" >&2
  echo "op-sops:   docker run --rm -v ${ENDURANCE_PROJECT}-op:/v alpine chown $(id -u):$(id -g) /v/token" >&2
  exit 1
fi

TOKEN="$(cat "$TOKEN_FILE")"
[ -n "$TOKEN" ] || { echo "op-sops: FATAL: token VAZIO em $TOKEN_FILE" >&2; exit 1; }

# `env -u OP_CONNECT_HOST -u OP_CONNECT_TOKEN` SO' nesta chamada: o `op` NAO cai sozinho
# para a service account quando OP_CONNECT_HOST esta setado mas o Connect nao responde —
# ele FALHA. Aqui nao usamos Connect, entao as duas saem, e so' para este processo.
exec env -u OP_CONNECT_HOST -u OP_CONNECT_TOKEN \
  OP_SERVICE_ACCOUNT_TOKEN="$TOKEN" op "$@"
OP_SOPS

# ------------------------------------------------------------------ cache de segredos
# Le o cofre UMA vez e guarda TUDO no .sops. E' este cache que os consumidores leem.
# Semeia a chave age na primeira vez (nunca sai da maquina).
#
# O `--extract` monta um env-file simples (CHAVE=valor) que o sops cifra inteiro.
# A chave de assinatura NUNCA e' impressa: `--extract ... 'github/signing-private-key'`
# so' vai para o arquivo cifrado.
cat > "$BIN/secrets-refresh" <<'REFRESH'
#!/usr/bin/env bash
# Le as referencias op:// e reescreve o cache cifrado. O unico passo do dia a dia que
# toca o 1Password — de proposito.
set -euo pipefail
. /etc/endurance/secrets.conf
CACHE_DIR="$ENDURANCE_CACHE_DIR"
CACHE_FILE="$CACHE_DIR/dev.env.sops"
AGE_KEY="$CACHE_DIR/age.key"
mkdir -p "$CACHE_DIR" && chmod 0700 "$CACHE_DIR"

if [ ! -f "$AGE_KEY" ]; then
  # Chave age de DEV, derivada localmente: identidade do cache, nunca a de producao.
  age-keygen -o "$AGE_KEY" 2>/dev/null
  chmod 0600 "$AGE_KEY"
  echo "secrets-refresh: chave age de dev criada em $AGE_KEY (0600)"
fi
export SOPS_AGE_KEY_FILE="$AGE_KEY"

# O PAT vem do op:// declarado; a chave de assinatura, do campo convencional do mesmo
# item. `op read` aqui e' FONTE, nao caminho do dia a dia.
PAT="$(op-sops.sh read "$ENDURANCE_PAT_REF")"
[ -n "$PAT" ] || { echo "secrets-refresh: PAT vazio em $ENDURANCE_PAT_REF" >&2; exit 1; }

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
{
  echo "GH_PAT=$PAT"
} > "$TMP"

# Campos OPCIONAIS do mesmo item: se o cofre nao os tiver, o refresh NAO morre — o
# consumidor que precisa deles e' que avisa alto.
SIGN_URL="op://${ENDURANCE_PROJECT}/secrets-dev/github/signing-private-key"
if KEY="$(op-sops.sh read "$SIGN_URL" 2>/dev/null)" && [ -n "$KEY" ]; then
  { echo "${ENDURANCE_SIGNING_KEY_VAR}=$KEY"; } >> "$TMP"
fi

sops --encrypt --age "$(age-keygen -y "$AGE_KEY")" "$TMP" > "$CACHE_FILE"
chmod 0600 "$CACHE_FILE"
echo "secrets-refresh: cache atualizado em $CACHE_FILE"
REFRESH

# ------------------------------------------------------- exec: roda um comando com os campos do cache
# `secrets exec -- <comando>` exporta as variaveis do cache so' para este processo.
# Usado pelo post-start para escrever a chave de assinatura — o valor nunca e' impresso.
cat > "$BIN/secrets-exec" <<'EXEC'
#!/usr/bin/env bash
set -euo pipefail
. /etc/endurance/secrets.conf
CACHE_FILE="$ENDURANCE_CACHE_DIR/dev.env.sops"
export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$ENDURANCE_CACHE_DIR/age.key}"
[ -f "$CACHE_FILE" ] || { echo "secrets-exec: cache ausente ($CACHE_FILE) — rode secrets-refresh" >&2; exit 1; }
[ "$1" = "--" ] && shift
exec env $(sops --decrypt "$CACHE_FILE" | grep -v '^#' | xargs -d '\n') "$@"
EXEC

# ------------------------------------------------------------- git-credential-op.sh
# Implementa o protocolo credential-helper do git. FIX OBRIGATORIO: le' o PAT do CACHE
# (via `secrets exec`, que decifra localmente), NAO do 1Password a cada `get`. O git chama
# o helper a CADA fetch/push — com `op read` aqui, cada operacao de rede custa uma ida ao
# cofre, e o limite de leitura do 1Password e' da CONTA inteira.
#
# `store`/`erase` sao no-op: o cofre e' a fonte, o cache e' a copia local.
cat > "$BIN/git-credential-op.sh" <<'GITCRED'
#!/usr/bin/env bash
set -euo pipefail
. /etc/endurance/secrets.conf

ACTION="${1:-}"
HOST=""
while IFS='=' read -r key value; do
  case "$key" in host) HOST="$value" ;; esac
done

case "$ACTION" in
  get)
    # So' github.com: outro host (ou URL ssh) resolve por fora.
    [ "$HOST" = "github.com" ] || exit 0
    PAT="$(secrets-exec -- sh -c 'printf "%s" "${GH_PAT:-}"' 2>/dev/null || true)"
    if [ -z "$PAT" ]; then
      echo "git-credential-op: NAO consegui o PAT do cache ($ENDURANCE_CACHE_DIR/dev.env.sops)." >&2
      echo "git-credential-op: rode 'secrets-refresh' para repor o cache a partir do 1Password." >&2
      exit 1
    fi
    # Resposta do protocolo: username + password, linha vazia termina.
    printf 'username=x-access-token\n'
    printf 'password=%s\n' "$PAT"
    printf '\n'
    ;;
  store|erase) exit 0 ;;
  *) exit 0 ;;
esac
GITCRED

# ------------------------------------------------------------------------- gh-op.sh
# Wrapper do `gh` com o PAT do CACHE (mesmo fix do credential helper: `GH_TOKEN` sai do
# cache, nao do 1Password por comando).
#
# Resolve o PROPRIO caminho seguindo symlinks: o gh-op e' alcancado pelo symlink
# /usr/local/bin/gh-op, e ai `$0` aponta para /usr/local/bin — qualquer caminho relativo
# a partir dali falha.
cat > "$BIN/gh-op.sh" <<'GHOP'
#!/usr/bin/env bash
# Uso: gh-op.sh <args do gh...>   Ex.: gh-op.sh auth status | gh-op.sh pr create ...
set -euo pipefail
_src="${BASH_SOURCE[0]}"
while [ -L "$_src" ]; do
  _dir="$(cd -P "$(dirname "$_src")" && pwd)"
  _src="$(readlink "$_src")"
  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
done
. /etc/endurance/secrets.conf

command -v gh >/dev/null 2>&1 || { echo "gh-op: CLI 'gh' ausente — instale a feature github-cli." >&2; exit 1; }

PAT="$(secrets-exec -- sh -c 'printf "%s" "${GH_PAT:-}"' 2>/dev/null || true)"
if [ -z "$PAT" ]; then
  echo "gh-op: NAO consegui o PAT do cache ($ENDURANCE_CACHE_DIR/dev.env.sops)." >&2
  echo "gh-op: rode 'secrets-refresh' para repor o cache a partir do 1Password." >&2
  exit 1
fi

# GH_TOKEN e' a variavel oficial do gh para auth nao-interativa. Passada pelo ENV do
# processo, nunca como argumento de linha de comando.
exec env GH_TOKEN="$PAT" gh "$@"
GHOP

chmod 0755 "$BIN/op-sops.sh" "$BIN/secrets-refresh" "$BIN/secrets-exec" \
           "$BIN/git-credential-op.sh" "$BIN/gh-op.sh"
ln -sf "$BIN/gh-op.sh" /usr/local/bin/gh-op

# ------------------------------------------------------------------ assinatura de commits
# A chave vem do CACHE de segredos; nunca e' impressa. O git config e' aplicado SEMPRE,
# fora do `if` do escritor: e' isso que transforma chave quebrada em commit que FALHA ALTO
# (commit.gpgsign=true + chave que nao carrega = commit que falha) em vez de commit SEM
# assinatura e SEM erro.
#
# $HOME do usuario do container, NUNCA /root: com uid 1000 /root e' 0700 de outro usuario
# e a chave nao existiria para quem commita.
cat > "$BIN/signing-write-key" <<'SIGNKEY'
#!/usr/bin/env sh
# Chamado pelo post-start do projeto: grava GIT_SIGNING_KEY (do cache) em $1 e $1.pub.
# Normaliza CR/CRLF e VALIDA antes de virar arquivo: chave que nao carrega no `ssh-keygen
# -y` nao vira $DEST, nao derruba a chave anterior e falha ALTO. Escrita por tmp+rename.
set -eu
[ -n "${GIT_SIGNING_KEY:-}" ] || exit 3
umask 077
DEST="$1"; TMP="$DEST.novo"
mkdir -p "$(dirname "$DEST")"
printf '%b' "$GIT_SIGNING_KEY" | tr -d '\r' > "$TMP"
[ "$(tail -c1 "$TMP" | wc -l)" -eq 1 ] || printf '\n' >> "$TMP"
if DERIVED="$(ssh-keygen -y -f "$TMP" 2>/dev/null)"; then :; else DERIVED=""; fi
if [ -z "$DERIVED" ]; then
  rm -f "$TMP"
  echo "[signing] FATAL: a chave NAO carrega (ssh-keygen -y rc!=0); nada foi escrito em $DEST." >&2
  exit 4
fi
printf '%s\n' "$DERIVED" > "$TMP.pub"
chmod 600 "$TMP"; chmod 644 "$TMP.pub"
mv -f "$TMP" "$DEST"; mv -f "$TMP.pub" "$DEST.pub"
SIGNKEY
chmod 0755 "$BIN/signing-write-key"

echo "secrets: pronto (projeto=$PROJECT, cache=~/.cache/$PROJECT, PAT lido do CACHE)"
