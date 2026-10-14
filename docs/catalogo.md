# Catálogo do Endurance

> **Gerado** por `tools/gen-catalogo.sh` a partir de `images/base/Dockerfile` e `src/*/devcontainer-feature.json`.
> Não edite à mão: o CI (`test.yml`) falha se este arquivo divergir do gerado.

## Imagem base — `ghcr.io/huldlabs/endurance/base`

Fixe pela versão cheia e, de preferência, por digest (`base@sha256:…`). Usuário `dev` (uid 1000), `tini` como PID 1,
`/workspace` como diretório de trabalho. Runtime (Node, Python de projeto, PHP…) **não** vem na base: é feature.

| Ferramenta | Versão | Para que serve |
| --- | --- | --- |
| `tars` | `ghcr.io/huldlabs/tars:0.0.1-dev.22` @ `sha256:76d91cf23b73…` | CLI do metodo (segredos, identidade, sync, release-notes); binario copiado da imagem do Tars por digest |
| `debian` | `debian:trixie-slim` @ `sha256:a29215f6a35e…` | sistema base (trixie-slim, por digest) |
| `git` | `1:2.47.3-0+deb13u1` | controle de versao (apt, versao exata) |
| `python3` | `3.13.5-1` | interpretador do SISTEMA (scripts de feature e `op`); runtime de projeto e' a feature python-uv |
| `sudo` | `1.9.16p2-3+deb13u2` | NOPASSWD restrito a groupadd/usermod/chown (gid do socket Docker em runtime) |
| `rg` | `14.1.1-1+b4` | ripgrep, busca de texto que todo agente usa (apt da trixie, versao exata) |
| `sops` | `3.9.4` | decifra o cache local de segredo com a chave age |
| `age` | `1.2.0` | cripto do cache de segredo (age e age-keygen) |
| `gitleaks` | `8.30.1` | varredura de segredo, mesma versao do pre-commit dos projetos |
| `op` | `latest` | 1Password CLI (repo apt proprio); a versao e' a ultima do repo, por excecao deliberada |
| `docker` | `5:29.8.1-1~debian.13~trixie` | Docker CLI sem daemon; age no daemon do host pelo socket montado |
| `docker compose` | `5.5.1-1~debian.13~trixie` | plugin compose da Docker CLI |
| `task` | `3.49.1` | runner de tarefas do ecossistema (go-task) |
| `claude` | `2.1.278` | Claude Code CLI nativo (sem Node), sha256 fixado por arquitetura |
| `ca-certificates curl gnupg jq xz-utils unzip openssh-client less procps tini locales tzdata` | apt da trixie, sem pin | utilitarios de trabalho e transporte; tini e' o PID 1 |
| `locale e fuso` | `pt_BR.UTF-8`, `America/Sao_Paulo` | configuracao da base: LANG/LC_ALL e TZ (projeto sobrescreve por containerEnv) |
| `endurance-init` | script da imagem | configura a arvore montada (safe.directory, hooksPath, filemode, hooks +x) |
| `endurance-bg` | script da imagem | tarefa longa dentro do container (setsid com nome, log e pidfile; ADR-0001) |

## Features — `ghcr.io/huldlabs/endurance/<id>:<major>`

Cada feature é uma pasta em `src/<id>/` (`install.sh` idempotente) e tem versão própria (spec containers.dev).
O projeto liga no `devcontainer.json`; as versões das ferramentas são as options abaixo (default = a fixada aqui).

| Feature | Versão | Ref de uso | O que instala |
| --- | --- | --- | --- |
| [`agent-browser`](#agent-browser) | 1.0.0 | `ghcr.io/huldlabs/endurance/agent-browser:1` | agent-browser |
| [`duckdb`](#duckdb) | 1.0.0 | `ghcr.io/huldlabs/endurance/duckdb:1` | DuckDB CLI |
| [`gh`](#gh) | 1.0.0 | `ghcr.io/huldlabs/endurance/gh:1` | GitHub CLI |
| [`kubectl-helm`](#kubectl-helm) | 1.0.0 | `ghcr.io/huldlabs/endurance/kubectl-helm:1` | kubectl + helm |
| [`lint`](#lint) | 1.0.0 | `ghcr.io/huldlabs/endurance/lint:1` | Lint de shell e workflows |
| [`mysql-client`](#mysql-client) | 1.0.0 | `ghcr.io/huldlabs/endurance/mysql-client:1` | MySQL client |
| [`node-bun`](#node-bun) | 1.2.0 | `ghcr.io/huldlabs/endurance/node-bun:1` | Node + bun |
| [`opentofu`](#opentofu) | 1.0.0 | `ghcr.io/huldlabs/endurance/opentofu:1` | OpenTofu |
| [`php`](#php) | 1.0.0 | `ghcr.io/huldlabs/endurance/php:1` | PHP + composer + wp-cli |
| [`playwright`](#playwright) | 1.2.0 | `ghcr.io/huldlabs/endurance/playwright:1` | Playwright |
| [`postgres-client`](#postgres-client) | 1.0.0 | `ghcr.io/huldlabs/endurance/postgres-client:1` | PostgreSQL client |
| [`pulumi`](#pulumi) | 1.0.0 | `ghcr.io/huldlabs/endurance/pulumi:1` | Pulumi CLI |
| [`pwsh`](#pwsh) | 1.0.0 | `ghcr.io/huldlabs/endurance/pwsh:1` | PowerShell |
| [`python-uv`](#python-uv) | 1.1.1 | `ghcr.io/huldlabs/endurance/python-uv:1` | Python + uv |
| [`redis-client`](#redis-client) | 1.0.0 | `ghcr.io/huldlabs/endurance/redis-client:1` | Redis/Valkey client |
| [`restic-rclone`](#restic-rclone) | 1.0.0 | `ghcr.io/huldlabs/endurance/restic-rclone:1` | restic + rclone |
| [`secrets`](#secrets) | 2.0.0 | `ghcr.io/huldlabs/endurance/secrets:2` | Segredos (tars secrets) |
| [`signing`](#signing) | 2.0.1 | `ghcr.io/huldlabs/endurance/signing:2` | Assinatura de commit (tars identity) |

### agent-browser

**agent-browser** — versão 1.0.0. CLI agent-browser (vercel-labs, npm) dirigindo o Google Chrome do sistema por CDP, para subagentes abrirem paginas atras de Cloudflare. Exige node-bun e playwright com browser=chrome.

```jsonc
"features": { "ghcr.io/huldlabs/endurance/agent-browser:1": {} }
```

| Option | Tipo | Default | Valores | Descrição |
| --- | --- | --- | --- | --- |
| `version` | string | `0.39.1` | livre | Versao do pacote npm agent-browser. |

- **Instalar depois de (`installsAfter`):** `ghcr.io/huldlabs/endurance/node-bun`, `ghcr.io/huldlabs/endurance/playwright`
- **containerEnv:** `AGENT_BROWSER_EXECUTABLE_PATH=/usr/bin/google-chrome`, `AGENT_BROWSER_ARGS=--no-sandbox`
- **Fonte:** [`src/agent-browser/`](../src/agent-browser)

### duckdb

**DuckDB CLI** — versão 1.0.0. CLI do duckdb, binario oficial do GitHub Releases, sha256 conferido.

```jsonc
"features": { "ghcr.io/huldlabs/endurance/duckdb:1": {} }
```

| Option | Tipo | Default | Valores | Descrição |
| --- | --- | --- | --- | --- |
| `version` | string | `1.5.6` | livre | Versao do duckdb (sem o v). |

- **Instalar depois de (`installsAfter`):** `ghcr.io/devcontainers/features/common-utils`
- **Fonte:** [`src/duckdb/`](../src/duckdb)

### gh

**GitHub CLI** — versão 1.0.0. gh do repositorio apt oficial (cli.github.com), chave GPG conferida, versao fixa.

```jsonc
"features": { "ghcr.io/huldlabs/endurance/gh:1": {} }
```

| Option | Tipo | Default | Valores | Descrição |
| --- | --- | --- | --- | --- |
| `version` | string | `2.102.0` | livre | Versao do gh (sem o v), fixada no apt. |

- **Instalar depois de (`installsAfter`):** `ghcr.io/devcontainers/features/common-utils`
- **Fonte:** [`src/gh/`](../src/gh)

### kubectl-helm

**kubectl + helm** — versão 1.0.0. kubectl (dl.k8s.io) e helm (get.helm.sh), binarios oficiais com sha256 conferido. O cluster nao vem junto.

```jsonc
"features": { "ghcr.io/huldlabs/endurance/kubectl-helm:1": {} }
```

| Option | Tipo | Default | Valores | Descrição |
| --- | --- | --- | --- | --- |
| `kubectlVersion` | string | `1.37.1` | livre | Versao do kubectl (sem o v). |
| `helmVersion` | string | `4.3.0` | livre | Versao do helm (sem o v). |

- **Instalar depois de (`installsAfter`):** `ghcr.io/devcontainers/features/common-utils`
- **Fonte:** [`src/kubectl-helm/`](../src/kubectl-helm)

### lint

**Lint de shell e workflows** — versão 1.0.0. shellcheck e actionlint, binarios oficiais do GitHub Releases, sha256 conferido.

```jsonc
"features": { "ghcr.io/huldlabs/endurance/lint:1": {} }
```

| Option | Tipo | Default | Valores | Descrição |
| --- | --- | --- | --- | --- |
| `shellcheckVersion` | string | `0.11.0` | livre | Versao do shellcheck (sem o v). |
| `actionlintVersion` | string | `1.7.12` | livre | Versao do actionlint (sem o v). |

- **Instalar depois de (`installsAfter`):** `ghcr.io/devcontainers/features/common-utils`
- **Fonte:** [`src/lint/`](../src/lint)

### mysql-client

**MySQL client** — versão 1.0.0. mysql e mysqldump da Oracle (repo apt oficial, assinado), compativeis com o MySQL 8 do compose (TLS autoassinado). O servidor fica no compose do projeto.

```jsonc
"features": { "ghcr.io/huldlabs/endurance/mysql-client:1": {} }
```

| Option | Tipo | Default | Valores | Descrição |
| --- | --- | --- | --- | --- |
| `version` | string | `8.4` | sugestões: `8.4`, `9.7` | Trilha LTS do cliente (componente mysql-<versao>-lts). O 8.4 fala com servidor 8.0 e 8.4. |

- **Instalar depois de (`installsAfter`):** `ghcr.io/devcontainers/features/common-utils`
- **Fonte:** [`src/mysql-client/`](../src/mysql-client)

### node-bun

**Node + bun** — versão 1.2.0. Node (versao por option) e o bun. O bun e' o gerenciador de pacotes do ecossistema; o npm vem junto com o Node.

```jsonc
"features": { "ghcr.io/huldlabs/endurance/node-bun:1": {} }
```

| Option | Tipo | Default | Valores | Descrição |
| --- | --- | --- | --- | --- |
| `nodeVersion` | string | `22` | livre | Major (ou versao exata) do Node. O projeto declara em .node-version; a feature obedece. |
| `packageManager` | string | `bun` | enum: `bun`, `pnpm`, `npm` | Gerenciador de pacotes do projeto. 'bun' usa bunVersion; 'pnpm' instala pnpmVersion por corepack; 'npm' usa o que vem com o Node (package-lock.json, install por `npm ci`). |
| `bunVersion` | string | `1.4.2` | livre | Versao do bun (instalador oficial). |
| `pnpmVersion` | string | `11.1.1` | livre | Versao do pnpm, usada quando packageManager=pnpm (via corepack, que vem com o Node). |
| `install` | boolean | `true` | `true`, `false` | Rodar o install congelado no fim, se houver lockfile do gerenciador escolhido. |

- **Instalar depois de (`installsAfter`):** `ghcr.io/devcontainers/features/common-utils`
- **Fonte:** [`src/node-bun/`](../src/node-bun)

### opentofu

**OpenTofu** — versão 1.0.0. tofu (OpenTofu), binario oficial do GitHub Releases, sha256 conferido. Substituto aberto do terraform.

```jsonc
"features": { "ghcr.io/huldlabs/endurance/opentofu:1": {} }
```

| Option | Tipo | Default | Valores | Descrição |
| --- | --- | --- | --- | --- |
| `version` | string | `1.13.1` | livre | Versao do OpenTofu (sem o v). |

- **Instalar depois de (`installsAfter`):** `ghcr.io/devcontainers/features/common-utils`
- **Fonte:** [`src/opentofu/`](../src/opentofu)

### php

**PHP + composer + wp-cli** — versão 1.0.0. php-cli do minor pedido (repositorio Sury, assinado), composer e wp-cli de versao fixa com checksum conferido. Para projetos WordPress/PHP (ex.: Fabber).

```jsonc
"features": { "ghcr.io/huldlabs/endurance/php:1": {} }
```

| Option | Tipo | Default | Valores | Descrição |
| --- | --- | --- | --- | --- |
| `version` | string | `8.3` | sugestões: `8.3`, `8.4`, `8.2` | Minor do PHP. O projeto declara o seu (ex.: config.platform.php do composer.json); a feature obedece. |
| `extensions` | string | `mysql,curl,mbstring,xml,zip,intl,gd` | livre | Extensoes (sufixo do pacote php<versao>-<ext>), separadas por virgula. |
| `composerVersion` | string | `2.10.3` | livre | Versao do composer ('none' para nao instalar). |
| `wpCliVersion` | string | `2.12.0` | livre | Versao do wp-cli ('none' para nao instalar). |

- **Instalar depois de (`installsAfter`):** `ghcr.io/devcontainers/features/common-utils`
- **Fonte:** [`src/php/`](../src/php)

### playwright

**Playwright** — versão 1.2.0. Bibliotecas de sistema do browser (por `install-deps` da versao pedida) e o browser instalado nas pastas de cache do container. Exige a feature node-bun para ter Node/npx.

```jsonc
"features": { "ghcr.io/huldlabs/endurance/playwright:1": {} }
```

| Option | Tipo | Default | Valores | Descrição |
| --- | --- | --- | --- | --- |
| `version` | string | `1.63.0` | livre | Versao do Playwright. A lista de bibliotecas e' resolvida POR ESTA versao (`install-deps`), nunca copiada a mao: sao ~40 nomes que mudam de forma por distro e a cada bump. |
| `browser` | string | `chromium` | sugestões: `chromium`, `chrome`, `chrome,msedge,firefox,webkit`, `firefox`, `webkit`, `chromium,firefox,webkit` | Browsers, separados por virgula. 'chromium'/'firefox'/'webkit' (motores do Playwright) vao para o cache do container; 'chrome' e 'msedge' instalam o Google Chrome / Microsoft Edge REAIS no sistema (so' amd64) — para quem usa channel="chrome"/"msedge" e precisa do UA do proprio motor (coletor de SERP do seo-brain). |

- **Instalar depois de (`installsAfter`):** `ghcr.io/huldlabs/endurance/node-bun`, `ghcr.io/devcontainers/features/common-utils`
- **Fonte:** [`src/playwright/`](../src/playwright)

### postgres-client

**PostgreSQL client** — versão 1.0.0. psql e pg_dump do major pedido, do repositorio PGDG assinado. O major TEM de casar com o servidor: pg_dump recusa um servidor mais novo que ele.

```jsonc
"features": { "ghcr.io/huldlabs/endurance/postgres-client:1": {} }
```

| Option | Tipo | Default | Valores | Descrição |
| --- | --- | --- | --- | --- |
| `version` | string | `18` | livre | Major do cliente (psql/pg_dump). Precisa ser >= o major do servidor. |

- **Instalar depois de (`installsAfter`):** `ghcr.io/devcontainers/features/common-utils`
- **Fonte:** [`src/postgres-client/`](../src/postgres-client)

### pulumi

**Pulumi CLI** — versão 1.0.0. CLI do Pulumi (instalador oficial, versao pinada). O SDK de cada linguagem fica com o projeto — aqui entra so a CLI.

```jsonc
"features": { "ghcr.io/huldlabs/endurance/pulumi:1": {} }
```

| Option | Tipo | Default | Valores | Descrição |
| --- | --- | --- | --- | --- |
| `version` | string | `3.263.0` | livre | Versao da CLI. Bump junto do requirements.txt do programa se o minimo suportado pelo SDK mudar. |

- **Instalar depois de (`installsAfter`):** `ghcr.io/devcontainers/features/common-utils`
- **Fonte:** [`src/pulumi/`](../src/pulumi)

### pwsh

**PowerShell** — versão 1.0.0. PowerShell 7 (tarball oficial do GitHub Releases, sha256 conferido). Para repos com scripts .ps1 (ex.: dotfiles).

```jsonc
"features": { "ghcr.io/huldlabs/endurance/pwsh:1": {} }
```

| Option | Tipo | Default | Valores | Descrição |
| --- | --- | --- | --- | --- |
| `version` | string | `7.6.6` | livre | Versao do PowerShell (tag do release, sem o v). |

- **Instalar depois de (`installsAfter`):** `ghcr.io/devcontainers/features/common-utils`
- **Fonte:** [`src/pwsh/`](../src/pwsh)

### python-uv

**Python + uv** — versão 1.1.1. Python (versao por option) e o uv, com venv em /workspace/.venv e uv sync idempotente quando ha uv.lock.

```jsonc
"features": { "ghcr.io/huldlabs/endurance/python-uv:1": {} }
```

| Option | Tipo | Default | Valores | Descrição |
| --- | --- | --- | --- | --- |
| `pythonVersion` | string | `3.13` | livre | Versao do Python: major.minor (3.12) ou exata, inclusive pre-release (3.15.0rc2). Aceita 3.12 a 3.15, que e' o intervalo declarado pelos projetos do ecossistema. Vira a base do venv. |
| `uvVersion` | string | `0.12.19` | livre | Versao do uv (instalador oficial astral.sh). |
| `venvPath` | string | `/workspace/.venv` | livre | Caminho do venv criado pelo uv. |

- **Instalar depois de (`installsAfter`):** `ghcr.io/devcontainers/features/common-utils`
- **Fonte:** [`src/python-uv/`](../src/python-uv)

### redis-client

**Redis/Valkey client** — versão 1.0.0. valkey-cli (com o nome redis-cli tambem), compativel com Redis e Valkey. O servidor fica no compose do projeto.

```jsonc
"features": { "ghcr.io/huldlabs/endurance/redis-client:1": {} }
```

Sem options.

- **Instalar depois de (`installsAfter`):** `ghcr.io/devcontainers/features/common-utils`
- **Fonte:** [`src/redis-client/`](../src/redis-client)

### restic-rclone

**restic + rclone** — versão 1.0.0. restic e rclone, binarios oficiais do GitHub Releases com sha256 conferido (SHA256SUMS do release).

```jsonc
"features": { "ghcr.io/huldlabs/endurance/restic-rclone:1": {} }
```

| Option | Tipo | Default | Valores | Descrição |
| --- | --- | --- | --- | --- |
| `resticVersion` | string | `0.19.1` | livre | Versao do restic (sem o v). |
| `rcloneVersion` | string | `1.75.2` | livre | Versao do rclone (sem o v). |

- **Instalar depois de (`installsAfter`):** `ghcr.io/devcontainers/features/common-utils`
- **Fonte:** [`src/restic-rclone/`](../src/restic-rclone)

### secrets

**Segredos (tars secrets)** — versão 2.0.0. Fina (D4/R5): liga `tars secrets git-credential` (o tars vem da base) como credential helper do git no nivel do SISTEMA. Nenhuma logica de segredo propria: cofre, cache e hosts sao do `[secrets]` do projeto.

```jsonc
"features": { "ghcr.io/huldlabs/endurance/secrets:2": {} }
```

Sem options.

- **Instalar depois de (`installsAfter`):** `ghcr.io/devcontainers/features/common-utils`
- **Fonte:** [`src/secrets/`](../src/secrets)

### signing

**Assinatura de commit (tars identity)** — versão 2.0.1. Fina (D4/R5): liga commit.gpgsign no sistema (build); no postStart roda `tars identity sign-setup` (gpg.format=ssh, signingkey, allowedSignersFile do `[identity]`/`[secrets]` do projeto), roda `tars identity verify`. O tars vem da base. `identity provision` e' do DONO, nunca daqui.

```jsonc
"features": { "ghcr.io/huldlabs/endurance/signing:2": {} }
```

Sem options.

- **Instalar depois de (`installsAfter`):** `ghcr.io/huldlabs/endurance/secrets`, `ghcr.io/devcontainers/features/common-utils`
- **Fonte:** [`src/signing/`](../src/signing)
- **postStartCommand:**

  ```sh
  timeout 30 tars identity sign-setup && timeout 30 tars identity verify || echo '[signing] AVISO: identidade nao verificada (ver acima); commit assinado vai falhar ate o DONO rodar `tars identity provision` (TTY)' >&2
  ```
