#!/usr/bin/env bash
# Feature php: php-cli do major.minor pedido + composer + wp-cli (opcional).
#
# POR QUE NAO O apt DA DISTRO: a trixie so' tem o PHP 8.4, e o projeto declara o seu
# (Fabber: `"php": "8.3"` no composer.json do WordPress). O repositorio do Ondrej Sury e'
# o do mantenedor do PHP no Debian, assinado, e tem cada minor lado a lado.
#
# composer e wp-cli sao .phar de versao FIXA, conferidos contra o checksum publicado pela
# propria fonte antes de entrar no PATH.
#
# Idempotente: se o php pedido ja existe, so' confere composer/wp-cli.
set -euo pipefail

PHP_VERSION="${VERSION:-8.3}"
EXTENSIONS="${EXTENSIONS:-mysql,curl,mbstring,xml,zip,intl,gd}"
COMPOSER_VERSION="${COMPOSERVERSION:-2.10.3}"
WPCLI_VERSION="${WPCLIVERSION:-2.12.0}"

if ! command -v "php${PHP_VERSION}" >/dev/null 2>&1; then
  apt-get update
  apt-get install -y --no-install-recommends ca-certificates curl gnupg
  curl -fsSL https://packages.sury.org/php/apt.gpg -o /usr/share/keyrings/sury-php.gpg
  echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ \
$(. /etc/os-release && echo "$VERSION_CODENAME") main" > /etc/apt/sources.list.d/sury-php.list
  apt-get update
  PKGS=("php${PHP_VERSION}-cli")
  IFS=',' read -r -a EXTS <<< "$EXTENSIONS"
  for e in "${EXTS[@]}"; do [ -n "$e" ] && PKGS+=("php${PHP_VERSION}-${e}"); done
  apt-get install -y --no-install-recommends "${PKGS[@]}"
  rm -rf /var/lib/apt/lists/*
fi
update-alternatives --set php "/usr/bin/php${PHP_VERSION}"
php --version | head -1

# composer: o .phar da versao pedida, conferido pelo sha256 do getcomposer.org.
if [ "$COMPOSER_VERSION" != "none" ] && ! composer --version 2>/dev/null | grep -q " ${COMPOSER_VERSION} "; then
  base="https://getcomposer.org/download/${COMPOSER_VERSION}"
  curl -fsSL "$base/composer.phar" -o /tmp/composer.phar
  echo "$(curl -fsSL "$base/composer.phar.sha256sum" | awk '{print $1}')  /tmp/composer.phar" | sha256sum -c -
  install -m 0755 /tmp/composer.phar /usr/local/bin/composer
  rm -f /tmp/composer.phar
fi
[ "$COMPOSER_VERSION" = "none" ] || composer --version

# wp-cli: o .phar do release, conferido pelo sha512 que o proprio release publica.
if [ "$WPCLI_VERSION" != "none" ] && ! wp --allow-root --version 2>/dev/null | grep -q " ${WPCLI_VERSION}$"; then
  base="https://github.com/wp-cli/wp-cli/releases/download/v${WPCLI_VERSION}/wp-cli-${WPCLI_VERSION}.phar"
  curl -fsSL "$base" -o /tmp/wp.phar
  echo "$(curl -fsSL "$base.sha512")  /tmp/wp.phar" | sha512sum -c -
  install -m 0755 /tmp/wp.phar /usr/local/bin/wp
  rm -f /tmp/wp.phar
fi
[ "$WPCLI_VERSION" = "none" ] || wp --allow-root --version

echo "php: pronto (php $PHP_VERSION, composer=$COMPOSER_VERSION, wp-cli=$WPCLI_VERSION)"
