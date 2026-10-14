#!/usr/bin/env bash
# Feature mysql-client: `mysql` e `mysqldump` da Oracle (repositorio apt oficial, assinado)
# para falar com o MySQL do compose do projeto (o SERVIDOR fica no compose, nunca na imagem).
#
# POR QUE NAO O apt DA DISTRO: o `default-mysql-client` da trixie e' o cliente MariaDB 11,
# que VERIFICA o certificado do servidor por padrao — e o MySQL 8 do compose sobe com
# certificado autoassinado. Resultado provado (13/10, mysql:8.0.46): "TLS/SSL error:
# self-signed certificate in certificate chain" no `mysql` e no `mysqldump`. O cliente da
# Oracle usa ssl-mode=PREFERRED (cifra sem exigir CA), o mesmo comportamento do servidor.
#
# Idempotente: se o `mysql` da Oracle ja existe, nao faz nada.
set -euo pipefail

TRACK="${VERSION:-8.4}"

if command -v mysql >/dev/null 2>&1 && mysql --version | grep -q "Ver ${TRACK}"; then
  echo "mysql-client: ja instalado ($(mysql --version))"
  exit 0
fi

apt-get update
apt-get install -y --no-install-recommends ca-certificates curl gnupg
# Chave de assinatura da Oracle, conferida pela impressao digital COMPLETA. O arquivo
# `-2023` traz a mesma chave com a validade VENCIDA (22/10/2025) e o apt recusa o repo;
# o `-2025` e' a mesma chave renovada.
MYSQL_KEY_FPR="BCA43417C3B485DD128EC6D4B7B3B788A8D3785C"
curl -fsSL https://repo.mysql.com/RPM-GPG-KEY-mysql-2025 -o /tmp/mysql.asc
gpg --show-keys --with-colons /tmp/mysql.asc | grep -q "^fpr:::::::::${MYSQL_KEY_FPR}:" || {
  echo "mysql-client: impressao digital da chave da Oracle NAO confere (esperada ${MYSQL_KEY_FPR})" >&2
  exit 1
}
gpg --dearmor -o /usr/share/keyrings/mysql.gpg < /tmp/mysql.asc
rm -f /tmp/mysql.asc
echo "deb [signed-by=/usr/share/keyrings/mysql.gpg] https://repo.mysql.com/apt/debian \
$(. /etc/os-release && echo "$VERSION_CODENAME") mysql-${TRACK}-lts" > /etc/apt/sources.list.d/mysql.list
apt-get update
apt-get install -y --no-install-recommends mysql-community-client
rm -rf /var/lib/apt/lists/*

mysql --version
mysqldump --version
echo "mysql-client: pronto (Oracle $TRACK)"
