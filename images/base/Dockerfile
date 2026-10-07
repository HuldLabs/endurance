# Imagem base do ecossistema HuldLabs: SO o que todo projeto usa.
#
# Regra do ecossistema: nada exige um runtime de quem nao o usa. Aqui nao ha Node,
# Python, Postgres nem Docker CLI — cada um desses vem por FEATURE, que o projeto liga
# no devcontainer.json. O que sobra e a base de trabalho: git, transporte (curl, ssh),
# verificacao de seguranca (gitleaks), cripto de segredo (sops + age) e a CLI do
# 1Password (op), que TODOS os projetos usam para ler credencial.
#
# Usuario `dev` (uid 1000), NAO `node`: este e o ambiente do ECOSSISTEMA, nao de um app
# Node. O nome `node` mentiria sobre o conteudo da imagem e convidaria a supor que ha um
# runtime Node aqui dentro — que e exatamente o que a regra acima proibe. `dev` tambem
# casa com o usuario que o devcontainer CLI remapeia (updateRemoteUserUID) para o dono
# da arvore montada, que no host e qualquer coisa menos `node`.
#
# Todas as versoes sao ARG de build fixadas. Versao que nao esta aqui nao existe: uma
# tag solta (ex.: `latest`) muda sozinha num rebuild e a tabela do topo passa a mentir.

FROM debian:trixie-slim@sha256:a29215f6a35e51e22adffa17f89e9d2ef06214e64a2bad10d765c46aea49f11f

ARG DEBIAN_VERSION=trixie
# Versoes fixas. O bloco abaixo e a fonte de verdade de cada uma.
ARG GIT_VERSION=1:2.47.3-0+deb13u1
ARG PYTHON_VERSION=3.13.5-1
ARG SUDO_VERSION=1.9.16p2-3+deb13u2
ARG SOPS_VERSION=3.9.4
ARG AGE_VERSION=1.2.0
ARG GITLEAKS_VERSION=8.30.1
# `op` em `latest` e' EXCECAO DELIBERADA: o repositorio apt da 1Password so' guarda a
# ULTIMA versao publicada. Fixar a versao faz o build quebrar sozinho quando ela sai do
# repo (aconteceu: o pin 2.39.0-1 sumiu e derrubou o rebuild). Nao ha o que fixar aqui.
ARG OP_CLI_VERSION=latest

ENV DEBIAN_FRONTEND=noninteractive

# Base minima da distro. git e python3 vem do apt COM VERSAO EXATA — sem o `=` o apt
# sobe o git sozinho num rebuild. python3 fica porque `op` e alguns scripts de feature o
# usam, mas NOTA: e o interpretador do sistema, nao um runtime de projeto (para isso ha
# a feature python-uv, que instala o proprio).
#
# `sudo` com NOPASSWD RESTRITO (nao e sudo livre): o gid do socket do Docker varia por
# maquina e o container roda como uid 1000, entao casar o grupo exige root em RUNTIME.
# Sem esta lista fechada, o sudoer vira root livre dentro de um container que ja monta o
# socket do host. `visudo -c` no build: regra de sudoers errada em SILENCIO e pior do que
# build quebrado.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg jq xz-utils unzip openssh-client less procps tini \
        "git=${GIT_VERSION}" "python3=${PYTHON_VERSION}" \
        "sudo=${SUDO_VERSION}" \
    && rm -rf /var/lib/apt/lists/* \
    && git --version

# Usuario `dev` (uid 1000, gid 1000). O uid 1000 e o que o host normalmente usa, e o
# devcontainer CLI remapeia este uid para o dono da arvore montada — criar o usuario JA
# com 1000 evita o container nascer root e o dono perder a escrita dentro do bind.
RUN groupadd --gid 1000 dev \
    && useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash dev \
    && printf '%s\n' \
      'dev ALL=(root) NOPASSWD: /usr/sbin/groupadd, /usr/sbin/usermod, /usr/bin/chown' \
      > /etc/sudoers.d/dev-docker \
    && chmod 0440 /etc/sudoers.d/dev-docker \
    && visudo -c

# sops (binario oficial). O sops decifra o cache de segredo com a chave age local.
RUN ARCH="$(dpkg --print-architecture)" \
    && curl -fsSL "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.${ARCH}" \
        -o /usr/local/bin/sops \
    && chmod +x /usr/local/bin/sops && sops --version

# age (tarball oficial): a chave de dev vive em ~/.cache/<projeto>/age.key, 0600, e
# NUNCA sai da maquina.
RUN ARCH="$(dpkg --print-architecture)" \
    && curl -fsSL "https://github.com/FiloSottile/age/releases/download/v${AGE_VERSION}/age-v${AGE_VERSION}-linux-${ARCH}.tar.gz" \
        -o /tmp/age.tgz \
    && tar -xzf /tmp/age.tgz -C /tmp \
    && mv /tmp/age/age /tmp/age/age-keygen /usr/local/bin/ \
    && rm -rf /tmp/age* && age --version

# gitleaks: a MESMA versao que o pre-commit dos projetos roda. Versao diferente aqui faz
# o commit passar local e falhar no gate de CI — o drift exato que uma imagem comum existe
# para eliminar.
RUN ARCH="$(dpkg --print-architecture)" \
    && case "$ARCH" in \
        amd64) GL_ARCH=x64 ;; \
        arm64) GL_ARCH=arm64 ;; \
        *) echo "Arquitetura nao suportada: $ARCH" >&2; exit 1 ;; \
       esac \
    && curl -fsSL "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_${GL_ARCH}.tar.gz" \
        -o /tmp/gitleaks.tar.gz \
    && tar -xzf /tmp/gitleaks.tar.gz -C /usr/local/bin gitleaks \
    && rm /tmp/gitleaks.tar.gz \
    && gitleaks version

# 1Password CLI, do repositorio apt PROPRIO (cadeia de assinatura verificavel), nao de um
# binario solto. Todo segredo do ecossistema passa por `op`; o TOKEN da service account
# NUNCA entra na imagem — ele chega por volume, em runtime, e quem o resolve e o
# op-sops.sh da feature `secrets`.
RUN curl -fsSL https://downloads.1password.com/linux/keys/1password.asc \
        | gpg --dearmor -o /usr/share/keyrings/1password-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] \
https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" \
        > /etc/apt/sources.list.d/1password.list \
    && mkdir -p /etc/debsig/policies/AC2D62742012EA22/ \
    && curl -fsSL https://downloads.1password.com/linux/debian/debsig/1password.pol \
        -o /etc/debsig/policies/AC2D62742012EA22/1password.pol \
    && mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22 \
    && curl -fsSL https://downloads.1password.com/linux/keys/1password.asc \
        | gpg --dearmor -o /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg \
    && apt-get update \
    && apt-get install -y --no-install-recommends 1password-cli \
    && rm -rf /var/lib/apt/lists/* \
    && op --version

# HOME do usuario `dev` como cwd de trabalho. O projeto monta a arvore DEPOIS; /workspace
# e' o alvo padrao e casa com o workspaceFolder dos projetos.
RUN mkdir -p /workspace && chown dev:dev /workspace

USER dev
WORKDIR /workspace

# tini como PID 1: o container recebe sinais (docker stop, restart) e sem um init eles
# ficam presos no `sleep infinity` do devcontainer, deixando processos orfaos para tras.
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["sleep", "infinity"]
