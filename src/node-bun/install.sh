#!/usr/bin/env bash
# Feature node-bun: Node (major por option) + bun.
#
# Idempotente: cada passo checa o que ja existe. O Node vem do tarball oficial e vive em
# /usr/local — NAO do apt da distro, que so' tem o major que a distro trouxe.
#
# Regra do ecossistema: quem nao liga esta feature nao paga por um Node. Por isso ela
# existe, em vez de vir na imagem base.
set -euo pipefail

NODE_VERSION="${VERSION:-22}"
BUN_VERSION="${BUNVERSION:-1.4.2}"
DO_INSTALL="${INSTALL:-true}"
USERNAME="${_REMOTE_USER:-dev}"

# Node do tarball oficial, na versao pedida. O major pode ser exato ("22.11.0") ou so' o
# major ("22"): com o major, o nodejs.org serve a ultima da linha via /dist/latest.
if ! command -v node >/dev/null 2>&1; then
  ARCH="$(dpkg --print-architecture)"
  case "$ARCH" in
    amd64) NODE_ARCH=x64 ;; \
    arm64) NODE_ARCH=arm64 ;; \
    *) echo "node-bun: arquitetura nao suportada: $ARCH" >&2; exit 1 ;; \
  esac
  case "$NODE_VERSION" in
    *.*.*) NODE_DIR="v${NODE_VERSION}" ;;
    *)     NODE_DIR="latest-v${NODE_VERSION}.x" ;;
  esac
  curl -fsSL "https://nodejs.org/dist/${NODE_DIR}/node-${NODE_DIR}-linux-${NODE_ARCH}.tar.xz" \
    -o /tmp/node.tar.xz
  tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
      --exclude='*/CHANGELOG.md' --exclude='*/LICENSE' --exclude='*/README.md'
  rm /tmp/node.tar.xz
fi
node --version

# bun: instalador oficial, versao fixa, em $BUN_INSTALL. O destino e' o HOME do usuario
# do container, NAO /root — com uid 1000 o usuario nao le /root (0700) e o bun deixaria de
# existir para todo mundo. Symlink em /usr/local/bin para nao depender de rc de shell.
BUN_HOME="/home/${USERNAME}/.bun"
if ! command -v bun >/dev/null 2>&1; then
  curl -fsSL https://bun.sh/install | BUN_INSTALL="$BUN_HOME" bash -s "bun-v${BUN_VERSION}"
  ln -sf "$BUN_HOME/bin/bun" /usr/local/bin/bun
  ln -sf "$BUN_HOME/bin/bunx" /usr/local/bin/bunx
  chown -R "$USERNAME:$USERNAME" "$BUN_HOME"
fi
bun --version

# Cache do bun no MESMO filesystem do repo: e' o que faz o install sair por HARDLINK.
# Cache noutro FS (ou num mount de rede) forca COPIA de cada arquivo, e o ganho do bun
# evapora. Fica fora da arvore versionada, em .cache/.
PROFILE="/etc/profile.d/endurance-node.sh"
cat > "$PROFILE" <<'EOF'
export BUN_INSTALL_CACHE_DIR="${BUN_INSTALL_CACHE_DIR:-/workspace/.cache/bun}"
EOF
# Fora de um projeto em /workspace (que nao tem a pasta .cache), o caminho acima nao
# existe. O bun aceita o diretorio faltando e o cria no primeiro uso.
chmod 0644 "$PROFILE"

# `bun install` quando ha lockfile. --frozen-lockfile: a feature NAO pode alterar o lock
# do projeto por conta propria — divergencia entre lock e package.json e' erro do projeto,
# nao da imagem. Roda como o usuario do container para node_modules nascer com o dono certo.
if [ "$DO_INSTALL" = "true" ] && [ -f /workspace/bun.lock ]; then
  su "$USERNAME" -c "cd /workspace && bun install --frozen-lockfile" || \
    echo "node-bun: AVISO: bun install --frozen-lockfile falhou (rode 'bun install' na mao)" >&2
fi

echo "node-bun: pronto (node $(node --version), bun $(bun --version))"
