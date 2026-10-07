#!/usr/bin/env bash
# Feature python-uv: Python (versao por option) + uv, e o venv do projeto.
#
# Idempotente: rodar duas vezes nao quebra nada. Todo passo checa o que ja existe antes
# de instalar — o devcontainer CLI reconstroi a feature em todo rebuild, e um install
# nao-idempotente transforma rebuild em falha intermitente.
#
# Regra do ecossistema (nada exige um runtime de quem nao o usa): quem nao liga esta
# feature nao paga por um Python. Por isso ela existe, em vez de vir na imagem base.
set -euo pipefail

# As options chegam por env, com o nome em CAIXA ALTA do id (spec containers.dev).
PYTHON_VERSION="${VERSION:-3.13}"
UV_VERSION="${UVVERSION:-0.12.19}"
VENV_PATH="${VENVPATH:-/workspace/.venv}"

USERNAME="${_REMOTE_USER:-dev}"

# Grupo de ferramentas do apt (python3-venv) e o `python3` do sistema.
#
# NAO usamos o `python3` da distro como versao do projeto: a distro so' tem UM python3 e
# o major/minor segue a trixie. Quem quer o 3.12 pede 3.12 e ganha o deadsnakes/compilado
# abaixo. O que a distro entrega e' o basico (venv, pip) para o resto do sistema.
if ! command -v python3 >/dev/null 2>&1; then
  apt-get update
  apt-get install -y --no-install-recommends python3 python3-venv python3-dev
  rm -rf /var/lib/apt/lists/*
fi

PY="$PYTHON_VERSION"
# O uv ja sabe instalar e fixar o interpretador; nao ha razao para compilar Python a mao.
# O uv fica FORA do apt (binario oficial, versao fixa) porque o da distro e' antigo.
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf "https://astral.sh/uv/${UV_VERSION}/install.sh" \
    | env UV_INSTALL_DIR=/usr/local/bin UV_NO_MODIFY_PATH=1 sh
fi
uv --version

# Interpretador pedido, gerenciado pelo uv. Idempotente por natureza: se ja estiver na
# cache, o uv so responde. `--no-bin` evita symlink global que sombrearia o python3 do
# sistema para quem nao pediu.
uv python install "$PY"

# O venv e' criado com o interpretador pedido. Volume NOMEADO que aponte para este
# caminho e' inicializado pelo Docker copiando a POSSE que a imagem tem aqui — por isso
# o dono e' definido agora, e nao num post-create (o volume nasce ANTES de qualquer
# comando de ciclo de vida rodar, e um venv root-owned quebra o `uv sync` de um jeito
# opaco).
mkdir -p "$VENV_PATH"
chown "$USERNAME:$USERNAME" "$VENV_PATH" 2>/dev/null || true
if [ ! -x "$VENV_PATH/bin/python" ]; then
  uv venv --python "$PY" "$VENV_PATH"
fi

# Caches FORA da arvore do repo: build output grande e milhares de arquivos; num mount de
# rede (9p/DrvFs) isso pesa no IO de todo mundo.
PROFILE="/etc/profile.d/endurance-python.sh"
cat > "$PROFILE" <<EOF
export UV_CACHE_DIR="${UV_CACHE_DIR:-\$HOME/.cache/uv}"
export PYTHONPYCACHEPREFIX="${PYTHONPYCACHEPREFIX:-\$HOME/.cache/pycache}"
export PYTHONDONTWRITEBYTECODE=1
export VIRTUAL_ENV="$VENV_PATH"
EOF
chmod 0644 "$PROFILE"

# `uv sync` quando o projeto ja tem uv.lock — idempotente e barato quando esta em dia.
# Roda como o usuario do container para o venv nao nascer root.
if [ -f /workspace/uv.lock ] && [ -w "$VENV_PATH" ]; then
  su "$USERNAME" -c "cd /workspace && uv sync --frozen" || \
    echo "python-uv: AVISO: uv sync --frozen falhou (rode 'uv sync' na mao)" >&2
fi

echo "python-uv: pronto (python $PY, uv $UV_VERSION, venv $VENV_PATH)"
