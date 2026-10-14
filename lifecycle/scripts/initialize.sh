#!/usr/bin/env bash
# Limpeza de container ORFAO do devcontainer. Roda no HOST, antes do build.
#
# Portado de farmega/.devcontainer/scripts/initialize.sh:27-47 (ideia, nao codigo).
#
# O defeito que isto evita: um container PARADO cujo bind aponta para um caminho que
# deixou de existir (o projeto mudou de pasta, o benchmark foi desmontado) fica segurando
# o label do devcontainer. No proximo `devcontainer up` o CLI encontra o container zumbi,
# tenta reanexar e o resultado e' um erro que nao fala de mount nenhum — o operador
# procura no lugar errado.
#
# Seguro por construcao: so' remove container que (a) tem ESTE devcontainer como config,
# (b) NAO esta rodando e (c) tem ao menos um bind cujo source sumiu do host. Container
# parado com binds validos, container rodando e qualquer outro projeto ficam intactos.
#
# Uso (devcontainer.json do projeto):
#   "initializeCommand": "bash .devcontainer/scripts/initialize.sh"
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEVCONTAINER_CONFIG_FILE="${ROOT_DIR}/.devcontainer/devcontainer.json"

log() { echo "[initialize] $*"; }

if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  log "Docker CLI/daemon indisponivel — limpeza preventiva ignorada."
  exit 0
fi

mapfile -t containers < <(
  docker ps -aq --filter "label=devcontainer.config_file=${DEVCONTAINER_CONFIG_FILE}" 2>/dev/null || true
)

if [ "${#containers[@]}" -eq 0 ]; then
  log "nenhum container anterior deste devcontainer."
  exit 0
fi

removed=0
for id in "${containers[@]}"; do
  state="$(docker inspect --format '{{.State.Status}}' "$id" 2>/dev/null || true)"
  [ "$state" = "running" ] && continue

  # Bind cujo source nao existe mais: o container nao tem como subir de novo.
  missing=0
  while IFS=$'\t' read -r _source; do
    [ -n "$_source" ] || continue
    if [ ! -e "$_source" ]; then
      missing=1
      break
    fi
  done < <(
    docker inspect \
      --format '{{range .Mounts}}{{if eq .Type "bind"}}{{printf "%s\n" .Source}}{{end}}{{end}}' \
      "$id" 2>/dev/null || true
  )

  if [ "$missing" -eq 1 ]; then
    docker rm "$id" >/dev/null 2>&1 || true
    removed=$((removed + 1))
    log "container orfao removido: $id"
  fi
done

log "pronto (inspecionados=${#containers[@]}, removidos=$removed)."
