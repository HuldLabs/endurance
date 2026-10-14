#!/usr/bin/env bash
# Gera docs/catalogo.md a partir das FONTES (R3): os marcadores `# catalogo:` do
# images/base/Dockerfile (a versao sai do ARG/FROM da linha seguinte) e cada
# src/*/devcontainer-feature.json. Nunca edite o catalogo a mao: rode este script.
#   bash tools/gen-catalogo.sh            # reescreve docs/catalogo.md
#   bash tools/gen-catalogo.sh --check    # falha se o commitado diverge do gerado
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=docs/catalogo.md
DF=images/base/Dockerfile
REG=ghcr.io/huldlabs/endurance

esc() { sed 's/|/\\|/g'; }

gerar() {
  cat <<'H'
# Catálogo do Endurance

> **Gerado** por `tools/gen-catalogo.sh` a partir de `images/base/Dockerfile` e `src/*/devcontainer-feature.json`.
> Não edite à mão: o CI (`test.yml`) falha se este arquivo divergir do gerado.

## Imagem base — `ghcr.io/huldlabs/endurance/base`

Fixe pela versão cheia e, de preferência, por digest (`base@sha256:…`). Usuário `dev` (uid 1000), `tini` como PID 1,
`/workspace` como diretório de trabalho. Runtime (Node, Python de projeto, PHP…) **não** vem na base: é feature.

| Ferramenta | Versão | Para que serve |
| --- | --- | --- |
H
  # Marcador -> proxima linha. ARG X=v: versao v (TARS_IMAGE: tag + digest curto); FROM img: a ref.
  awk '
    /^# catalogo: / { m = substr($0, 13); next }
    m != "" {
      n = split(m, f, / \| /); nome = f[1]; uso = f[2]; ver = (n >= 3 ? f[3] : "")
      if (ver == "") {
        if ($1 == "ARG") { sub(/^ARG [A-Z0-9_]+=/, ""); ver = $0 } else if ($1 == "FROM") ver = $2
        if (ver ~ /@sha256:/) { split(ver, d, "@sha256:"); ver = "`" d[1] "` @ `sha256:" substr(d[2], 1, 12) "…`" }
        else ver = "`" ver "`"
      }
      gsub(/\|/, "\\|", uso)
      printf "| `%s` | %s | %s |\n", nome, ver, uso
      m = ""
    }' "$DF"

  cat <<H

## Features — \`${REG}/<id>:<major>\`

Cada feature é uma pasta em \`src/<id>/\` (\`install.sh\` idempotente) e tem versão própria (spec containers.dev).
O projeto liga no \`devcontainer.json\`; as versões das ferramentas são as options abaixo (default = a fixada aqui).

| Feature | Versão | Ref de uso | O que instala |
| --- | --- | --- | --- |
H
  for f in src/*/devcontainer-feature.json; do
    jq -r --arg reg "$REG" '"| [`\(.id)`](#\(.id)) | \(.version) | `\($reg)/\(.id):\(.version|split(".")[0])` | \(.name) |"' "$f"
  done
  for f in src/*/devcontainer-feature.json; do
    jq -r --arg reg "$REG" '
      def e: tostring | gsub("\\|"; "\\|") | gsub("\n"; " ");
      def lista(a): if (a // []) == [] then "—" else (a | map("`\(.)`") | join(", ")) end;
      "",
      "### \(.id)",
      "",
      "**\(.name)** — versão \(.version). \(.description | e)",
      "",
      "```jsonc",
      "\"features\": { \"\($reg)/\(.id):\(.version|split(".")[0])\": {} }",
      "```",
      "",
      (if (.options // {}) == {} then "Sem options."
       else
         "| Option | Tipo | Default | Valores | Descrição |",
         "| --- | --- | --- | --- | --- |",
         (.options | to_entries[] |
           "| `\(.key)` | \(.value.type) | `\(.value.default | tostring)` | \(
              if .value.enum then "enum: " + lista(.value.enum)
              elif .value.proposals then "sugestões: " + lista(.value.proposals)
              elif .value.type == "boolean" then "`true`, `false`"
              else "livre" end) | \(.value.description // "" | e) |")
       end),
      "",
      "- **Instalar depois de (`installsAfter`):** \(lista(.installsAfter))",
      (if .containerEnv then "- **containerEnv:** " + (.containerEnv | to_entries | map("`\(.key)=\(.value)`") | join(", ")) else empty end),
      "- **Fonte:** [`src/\(.id)/`](../src/\(.id))",
      (if .postStartCommand then "- **postStartCommand:**", "", "  ```sh", "  \(.postStartCommand)", "  ```" else empty end)
    ' "$f"
  done
}

if [ "${1:-}" = "--check" ]; then
  diff -u "$OUT" <(gerar) || { echo "docs/catalogo.md desatualizado: rode bash tools/gen-catalogo.sh" >&2; exit 1; }
else
  gerar > "$OUT"
fi
