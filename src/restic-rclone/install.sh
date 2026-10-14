#!/usr/bin/env bash
# Feature restic-rclone: restic + rclone (homelab-infra), binarios oficiais do GitHub
# Releases, versoes fixas, conferidos pelo SHA256SUMS de cada release (confianca na origem:
# TLS do GitHub).
#
# Idempotente: cada binario so' e' baixado se a versao pedida nao estiver instalada.
set -euo pipefail

RESTIC_VERSION="${RESTICVERSION:-0.19.1}"
RCLONE_VERSION="${RCLONEVERSION:-1.75.2}"

case "$(dpkg --print-architecture)" in
  amd64|arm64) ARCH="$(dpkg --print-architecture)" ;;
  *) echo "restic-rclone: arquitetura nao suportada: $(dpkg --print-architecture)" >&2; exit 1 ;;
esac
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

if ! { command -v restic >/dev/null 2>&1 && restic version | grep -q "^restic ${RESTIC_VERSION} "; }; then
  file="restic_${RESTIC_VERSION}_linux_${ARCH}.bz2"
  base="https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}"
  curl -fsSL "$base/$file" -o "$tmp/$file"
  curl -fsSL "$base/SHA256SUMS" | grep " ${file}$" | (cd "$tmp" && sha256sum -c -)
  # bzip2 nao vem na base; o python3 da base descomprime sem instalar nada.
  python3 -c 'import bz2,shutil,sys; shutil.copyfileobj(bz2.open(sys.argv[1]), open(sys.argv[2],"wb"))' \
    "$tmp/$file" "$tmp/restic"
  install -m 0755 "$tmp/restic" /usr/local/bin/restic
fi

if ! { command -v rclone >/dev/null 2>&1 && rclone version | head -n1 | grep -qx "rclone v${RCLONE_VERSION}"; }; then
  file="rclone-v${RCLONE_VERSION}-linux-${ARCH}.zip"
  base="https://github.com/rclone/rclone/releases/download/v${RCLONE_VERSION}"
  curl -fsSL "$base/$file" -o "$tmp/$file"
  curl -fsSL "$base/SHA256SUMS" | grep " ${file}$" | (cd "$tmp" && sha256sum -c -)
  unzip -q "$tmp/$file" -d "$tmp"
  install -m 0755 "$tmp/rclone-v${RCLONE_VERSION}-linux-${ARCH}/rclone" /usr/local/bin/rclone
fi

restic version
rclone version | head -n1
echo "restic-rclone: pronto (restic ${RESTIC_VERSION}, rclone ${RCLONE_VERSION})"
