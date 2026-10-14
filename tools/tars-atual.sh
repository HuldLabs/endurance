#!/usr/bin/env bash
# Gate do Tars na base: o `ARG TARS_IMAGE` (tag@digest) do Dockerfile tem de ser a ULTIMA versao publicada
# de ghcr.io/huldlabs/tars (pre-release incluida) e o digest fixado tem de ser o da tag declarada.
#
#   tools/tars-atual.sh            # atrasado = ::warning:: (rc 0)  -> test.yml (PR)
#   tools/tars-atual.sh --strict   # atrasado = erro (rc 1)         -> publish.yml (tag)
#   digest fixado != digest da tag declarada = erro SEMPRE (rc 1).
#
# Consulta o registry com o login que o docker ja' tem para ghcr.io (CI: docker/login-action de leitura;
# local: credsStore). O token nunca vai para argv nem log: curl le' a credencial por stdin (-K -).
# Sem rede (teste): TARS_LATEST=<versao> TARS_LATEST_DIGEST=<sha256:..> TARS_DECLARED_DIGEST=<sha256:..>.
set -euo pipefail
cd "$(dirname "$0")/.."
strict=0; [ "${1:-}" = --strict ] && strict=1
repo=huldlabs/tars
dockerfile="${ENDURANCE_DOCKERFILE:-images/base/Dockerfile}"

ref="$(sed -n 's/^ARG TARS_IMAGE=//p' "$dockerfile")"
case "$ref" in ghcr.io/$repo:*@sha256:*) ;; *) echo "::error::ARG TARS_IMAGE sem tag+digest de ghcr.io/$repo: '$ref'"; exit 1 ;; esac
tag="${ref#*:}"; tag="${tag%%@*}"; pinned="${ref#*@}"

# Ordem de versao: `-` vira `~` para o sort -V por pre-release ANTES da final (0.0.1-dev.22 < 0.0.1).
latest_of() { sed 's/-/~/' | sort -V | tail -n1 | sed 's/~/-/'; }

if [ -n "${TARS_LATEST:-}" ]; then
  latest="$TARS_LATEST"; latest_digest="${TARS_LATEST_DIGEST:-}"; declared_digest="${TARS_DECLARED_DIGEST:-}"
else
  cfg="${DOCKER_CONFIG:-$HOME/.docker}/config.json"
  creds() { # user:senha para ghcr.io, so' em stdout de pipe (nunca impresso)
    local h; h="$(jq -r '.credHelpers["ghcr.io"] // .credsStore // empty' "$cfg" 2>/dev/null || true)"
    if [ -n "$h" ]; then echo ghcr.io | "docker-credential-$h" get | jq -r '"\(.Username):\(.Secret)"'
    else jq -er '.auths["ghcr.io"].auth' "$cfg" | base64 -d; fi
  }
  token="$(creds | jq -Rr '"user = \"\(.)\""' | curl -fsS -K - "https://ghcr.io/token?service=ghcr.io&scope=repository:$repo:pull" | jq -er .token)" \
    || { echo "::error::sem login de leitura em ghcr.io para $repo"; exit 1; }
  tags="$(printf 'header = "Authorization: Bearer %s"\n' "$token" | curl -fsS -K - "https://ghcr.io/v2/$repo/tags/list?n=10000" | jq -r '.tags[]')"
  unset token
  latest="$(grep -E '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?$' <<<"$tags" | latest_of)"
  digest() { docker buildx imagetools inspect "ghcr.io/$repo:$1" --format '{{json .Manifest.Digest}}' | tr -d '"'; }
  declared_digest="$(digest "$tag")"; latest_digest="$(digest "$latest")"
fi

[ -n "$latest" ] || { echo "::error::nenhuma versao publicada de ghcr.io/$repo encontrada"; exit 1; }
if [ "$pinned" != "$declared_digest" ]; then
  echo "::error::ARG TARS_IMAGE fixa $tag@$pinned, mas a tag $tag aponta para ${declared_digest:-<ausente>}"; exit 1
fi
if [ "$tag" != "$latest" ] && [ "$(printf '%s\n%s\n' "$tag" "$latest" | latest_of)" = "$latest" ]; then
  msg="tars atrasado na base: $tag, ultima Release $latest (${latest_digest:-?}). Bump: README 'Rotina do Tars na base'."
  if [ "$strict" = 1 ]; then echo "::error::$msg"; exit 1; fi
  echo "::warning::$msg"; exit 0
fi
echo "tars em dia na base: $tag@$pinned (ultima: $latest)"
