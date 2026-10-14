#!/usr/bin/env bash
# Feature tars: o comando `tars` no PATH, rodando o Tars de um checkout MONTADO.
#
# Por que nao baixa um binario: o HuldLabs/tars nao publica Release nem binario (13/10:
# `gh release list` vazio) — o Tars e' `node tools/framework/tars.mjs` de um checkout. A
# versao antiga desta feature baixava `releases/latest/download/tars-linux-<arch>`, que nao
# existe, e quebrava o install. Clonar no build exigiria credencial no build (o repo e'
# privado) — e nenhuma credencial entra na imagem.
#
# Entao: o projeto monta o checkout do Tars (somente leitura) e esta feature poe o shim. E' o
# mesmo modelo que o kipp ja' usa (`TARS_HOME` apontando para um checkout da main do tars).
# Quando o Tars publicar artefato versionado, `version` (digest, decisao D5) entra aqui.
set -euo pipefail

TARS_HOME_DEFAULT="${TARSHOME:-/opt/tars}"

command -v node >/dev/null 2>&1 || {
  echo "tars: 'node' ausente — ligue a feature node-bun ANTES desta (installsAfter)." >&2
  exit 1
}

cat > /usr/local/bin/tars <<EOF
#!/bin/sh
# Shim da feature tars do Endurance: roda o Tars do checkout em \$TARS_HOME.
TARS_HOME="\${TARS_HOME:-$TARS_HOME_DEFAULT}"
[ -f "\$TARS_HOME/tools/framework/tars.mjs" ] || {
  echo "tars: checkout do Tars ausente em \$TARS_HOME — monte-o (mounts do devcontainer.json) ou ajuste TARS_HOME." >&2
  exit 1
}
export TARS_HOME
exec node "\$TARS_HOME/tools/framework/tars.mjs" "\$@"
EOF
chmod 0755 /usr/local/bin/tars

echo "tars: pronto (shim em /usr/local/bin/tars, TARS_HOME padrao=$TARS_HOME_DEFAULT)"
