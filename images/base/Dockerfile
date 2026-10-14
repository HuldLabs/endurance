# syntax=docker/dockerfile:1
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

# tars (D17): binario compilado do HuldLabs/tars, copiado da imagem dele POR DIGEST. Fonte
# unica da versao e' este ARG (R3); bump = trocar versao e digest juntos. Sem Node e sem
# credencial no build da imagem (o pull do GHCR e' do runner, por docker login). O binario e'
# glibc (bookworm) e roda na trixie (glibc mais nova).
ARG TARS_IMAGE=ghcr.io/huldlabs/tars:0.0.1-dev.19@sha256:ac9dca584d914c9e9f917ca95067f18fe804d9f7124bc6b852a6a03f6c857d7d
FROM ${TARS_IMAGE} AS tars

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
# Repositorio apt PROPRIO de cada um (cadeia de assinatura verificavel), versao EXATA:
# sem o `=` o apt stable sobe a ferramenta sozinho num rebuild e a tabela do topo mente.
ARG DOCKER_CE_CLI_VERSION=5:29.8.1-1~debian.13~trixie
ARG DOCKER_COMPOSE_PLUGIN_VERSION=5.5.1-1~debian.13~trixie
# go-task (instalador oficial) e Claude Code (instalador nativo oficial, sem Node).
ARG TASK_VERSION=3.49.1
ARG CLAUDE_CODE_VERSION=2.1.278
ARG CLAUDE_CODE_SHA256_AMD64=5c4735937844e84f8a93306e841a5b0e12252909b07870f789b190468da147ab
ARG CLAUDE_CODE_SHA256_ARM64=7de6cab134e48321148e30182c98614118e8f4666819412bead45865190b34ed

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

# task: o runner de tarefas do ecossistema, instalador oficial com versao explicita.
# Nao ha "task" no apt da trixie, e o binario solto de um repositorio de terceiros
# trocaria de versao sem aviso.
RUN sh -c "$(curl -fsSL https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin "v${TASK_VERSION}" \
    && task --version

# Docker CLI + compose plugin (SEM daemon). O socket do host e' montado pelo PROJETO,
# entao `docker`/`docker compose` aqui agem no MESMO daemon do host. Daemon nunca entra:
# exigiria privileged e mataria a premissa de "um container, nao uma VM".
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg \
        | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        "docker-ce-cli=${DOCKER_CE_CLI_VERSION}" "docker-compose-plugin=${DOCKER_COMPOSE_PLUGIN_VERSION}" \
    && rm -rf /var/lib/apt/lists/* \
    && docker --version && docker compose version

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
# `tars secrets`.
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

# ------------------------------------------------------------------------------- git
# As quatro configuracoes que TODA arvore montada precisa, num script so'. Elas sao
# config de REPO (nao versionada), entao uma arvore/container novo nao as tem e o defeito
# que cada uma evita so' aparece depois:
#
#   safe.directory     o bind pertence ao uid do HOST; sem isto o git recusa a arvore
#                      ("dubious ownership") antes de qualquer comando. E' a UNICA em
#                      ~/.gitconfig (nao e' por repo).
#   core.hooksPath     RELATIVO (.githooks), nunca /workspace/.githooks: o path absoluto
#                      desliga os hooks em SILENCIO para o git rodando no HOST, onde
#                      esse caminho nao existe.
#   core.filemode      o host (Windows) e o container discordam do exec bit em todo
#                      arquivo compartilhado; sem isso dezenas de arquivos vao ao stage
#                      como 755->644 com conteudo identico (churn puro), que e' o
#                      caminho para um diff so-de-modo esconder uma mudanca real.
#   bit executavel     com filemode desligado o git deixa de versionar/restaurar o bit;
#                      o pre-commit e' a UNICA protecao, e ele cobra o bit. Um clone ou
#                      checkout pode perde-lo em silencio — este passo o repoe.
#
# Nada de credencial, host ou nome de projeto aqui: o script e' do AMBIENTE e roda contra
# a arvore que o projeto montar (por default /workspace).
# O script entra por `COPY <<EOF` (heredoc do BuildKit), que GRAVA o arquivo. `RUN <<EOF sh`
# EXECUTA o conteudo no build — o arquivo nunca existia e o build quebrava no chmod.
COPY --chmod=0755 <<'INIT' /usr/local/bin/endurance-init
#!/usr/bin/env bash
# Chamado no post-create do projeto (ou na mao). Idempotente.
set -euo pipefail

TREE="${1:-/workspace}"

if ! git -C "$TREE" rev-parse --git-dir >/dev/null 2>&1; then
  echo "endurance-init: $TREE nao e' uma arvore git — nada a configurar." >&2
  exit 0
fi

# Global: o projeto pode estar em /workspace ou em qualquer caminho montado.
git config --global --add safe.directory "$TREE"

# Por repo. `-C` em vez de cd: nao muda o diretorio de quem chamou.
git -C "$TREE" config core.hooksPath .githooks
git -C "$TREE" config core.filemode false

# Repoe o bit executavel dos hooks (ver comentario no Dockerfile).
if [ -d "$TREE/.githooks" ]; then
  find "$TREE/.githooks" -maxdepth 1 -type f -exec chmod +x {} +
fi

echo "endurance-init: pronto ($TREE: hooksPath=.githooks, filemode=false, hooks +x)"
INIT

# endurance-bg: o mecanismo CANONICO de tarefa longa (ADR-0001). O harness do agente mata o
# GRUPO de processos do comando quando ele termina: `cmd &` e `nohup cmd &` morrem juntos
# (nohup so' ignora HUP; o harness manda TERM). `setsid` abre sessao/grupo proprio e
# sobrevive — DENTRO do container, sem ir ao host. Este script e' o `setsid` com nome,
# log e pidfile, para ninguem reescrever a mesma linha em cada Taskfile.
COPY --chmod=0755 <<'BG' /usr/local/bin/endurance-bg
#!/usr/bin/env bash
# Uso: endurance-bg start <nome> -- <cmd...> | stop <nome> | status [<nome>] | log <nome>
set -euo pipefail
DIR="${ENDURANCE_BG_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/endurance-bg}"
mkdir -p "$DIR"
vivo() { [ -f "$DIR/$1.pid" ] && kill -0 "$(cat "$DIR/$1.pid")" 2>/dev/null; }
acao="${1:-}"; nome="${2:-}"
case "$acao" in
  start)
    [ -n "$nome" ] && [ "${3:-}" = "--" ] && [ $# -ge 4 ] || { echo "uso: endurance-bg start <nome> -- <cmd...>" >&2; exit 2; }
    shift 3
    if vivo "$nome"; then echo "endurance-bg: $nome ja' roda (pid $(cat "$DIR/$nome.pid"))"; exit 0; fi
    setsid "$@" >"$DIR/$nome.log" 2>&1 </dev/null &
    echo $! >"$DIR/$nome.pid"
    echo "endurance-bg: $nome iniciado (pid $!, log $DIR/$nome.log)" ;;
  stop)
    if ! vivo "$nome"; then echo "endurance-bg: $nome nao roda"; rm -f "$DIR/$nome.pid"; exit 0; fi
    # O pid gravado e' o LIDER do grupo: sem job control o `setsid` roda sem fork, entao
    # `$!` = pid = pgid. TERM no grupo inteiro; falha do kill mantem o pidfile e sai != 0.
    kill -TERM -- "-$(cat "$DIR/$nome.pid")" || { echo "endurance-bg: falha ao parar $nome" >&2; exit 1; }
    rm -f "$DIR/$nome.pid"; echo "endurance-bg: $nome parado" ;;
  status)
    for f in "$DIR"/${nome:-*}.pid; do
      [ -e "$f" ] || continue; n="$(basename "$f" .pid)"
      vivo "$n" && echo "$n: rodando (pid $(cat "$f"))" || echo "$n: parado"
    done ;;
  log) exec tail -n 100 -f "$DIR/$nome.log" ;;
  *) echo "uso: endurance-bg start <nome> -- <cmd...> | stop <nome> | status [<nome>] | log <nome>" >&2; exit 2 ;;
esac
BG

# Claude Code CLI para o WORKER de despacho; e' ferramenta de desenvolvimento deste
# ecossistema, como o git. Nao carrega ANTHROPIC_*: credencial e base URL sao por execucao,
# lidas do cofre pelo launcher — a imagem nunca guarda segredo.
#
# Binario NATIVO da versao fixa (sem Node), conferido contra o sha256 FIXADO aqui (o mesmo
# do manifest.json da versao). Nao por `curl install.sh | bash`: o script remoto muda sem
# aviso. Nem por `npm -g`: o Node vem de FEATURE, que roda DEPOIS da base, e o passo caia
# calado no ramo "npm ausente". Bump: trocar a versao e os dois sha256 do manifest dela.
RUN set -eu; \
    case "$(dpkg --print-architecture)" in \
      amd64) plat=linux-x64;   sum="$CLAUDE_CODE_SHA256_AMD64" ;; \
      arm64) plat=linux-arm64; sum="$CLAUDE_CODE_SHA256_ARM64" ;; \
      *) echo "claude: arquitetura nao suportada" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://downloads.claude.ai/claude-code-releases/${CLAUDE_CODE_VERSION}/${plat}/claude" -o /tmp/claude; \
    echo "${sum}  /tmp/claude" | sha256sum -c -; \
    install -m 0755 /tmp/claude /usr/local/bin/claude; rm -f /tmp/claude; \
    claude --version
# Versao e' a da imagem: o binario e' do root em /usr/local/bin e o auto-update (como `dev`)
# so' falharia com aviso. Bump = trocar a versao e os sha256 acima.
ENV DISABLE_AUTOUPDATER=1

# tars na base: TODO projeto usa (D17). `secrets`/`signing` sao features finas sobre ele (D4).
COPY --from=tars /tars /usr/local/bin/tars
RUN tars --version

USER dev

WORKDIR /workspace

# tini como PID 1: o container recebe sinais (docker stop, restart) e sem um init eles
# ficam presos no `sleep infinity` do devcontainer, deixando processos orfaos para tras.
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["sleep", "infinity"]
