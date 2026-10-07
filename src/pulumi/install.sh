#!/usr/bin/env bash
# Feature pulumi: a CLI do Pulumi, versao pinada.
#
# Instalador OFICIAL (get.pulumi.com) com `--version` explicito: "latest" resolve
# diferente conforme o dia do build e um rebuild passaria a ter outra CLI sem ninguem
# pedir. E' a mesma disciplina de pin das outras features.
#
# O SDK (pulumi_oci, pulumi_github, ...) e' do PROJETO, nao daqui: ele vive no venv do
# programa (requirements.txt) e a versao acompanha o codigo. Aqui entra so' a CLI que o
# `pulumi` do PATH executa.
set -euo pipefail

PULUMI_VERSION="${VERSION:-3.263.0}"

if command -v pulumi >/dev/null 2>&1; then
  pulumi version
  exit 0
fi

# O instalador escreve em ~/.pulumi do usuario que o chamou (root, no build) e nao aceita
# --install-dir. Move para /usr/local/bin (no PATH de todo mundo) e limpa o HOME.
curl -fsSL https://get.pulumi.com | sh -s -- --version "${PULUMI_VERSION}"
mv /root/.pulumi/bin/* /usr/local/bin/
rm -rf /root/.pulumi
pulumi version

echo "pulumi: pronto (pulumi $PULUMI_VERSION)"
