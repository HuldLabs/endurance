# endurance

Devcontainer do ecossistema [HuldLabs](https://github.com/HuldLabs).

## O nome

Na trilogia do Christopher Nolan, a *Endurance* é a nave que leva o TARS e o KIPP —
os robôs que fazem o trabalho braçal enquanto a tripulação decide. Aqui é o mesmo
papel: este repositório é o **ambiente onde as peças rodam**, não uma peça.

## O que ele é (e o que não é)

Não é uma imagem gorda com tudo dentro. A regra é: **nada exige um runtime de quem
não o usa**. Node não paga pelo Python, o Python não paga pelo Docker, e um projeto
que só precisa de `git` e `sops` instala só isso.

Isso se resolve com **Dev Container Features** (a spec oficial do
[containers.dev](https://containers.dev/implementors/features/)): cada runtime é um
`install.sh` idempotente publicado em `ghcr.io/huldlabs/endurance/<feature>`, que o
projeto liga no `devcontainer.json` com uma linha.

**Catálogo completo** (cada ferramenta da base com versão e para que serve; cada feature com versão, ref de uso e
todas as options): [`docs/catalogo.md`](docs/catalogo.md), gerado por `tools/gen-catalogo.sh` — o CI falha se divergir.

## Como um projeto usa

```jsonc
{
  "name": "meu-projeto",
  "image": "ghcr.io/huldlabs/endurance/base:0.0.1-dev.3",
  "features": {
    "ghcr.io/huldlabs/endurance/node-bun:1": {},
    "ghcr.io/huldlabs/endurance/postgres-client:1": { "version": "18" },
    "ghcr.io/huldlabs/endurance/secrets:2": {}
  },
  "remoteUser": "dev",
  // Estado do `tars secrets` (chave age, token, cache cifrado): volume por usuario E projeto.
  "mounts": [ "source=${localEnv:USER}-meu-projeto-tars,target=/home/dev/.config/tars/meu-projeto,type=volume" ]
}
```

O `image` dá a base; cada `features` acrescenta um runtime; o resto (compose,
Postgres, portas, mounts, variáveis de ambiente) é do projeto.

### Qual projeto usa o quê

Cada projeto do ecossistema declara a própria versão (`nodeVersion`, `pythonVersion`,
`packageManager`); a feature obedece. Três recortes reais:

**Stack Python só** (farmega, seo-expert, nexus-x — Python 3.13, Postgres 18):

```jsonc
{
  "image": "ghcr.io/huldlabs/endurance/base:0.0.1-dev.3",
  "features": {
    "ghcr.io/huldlabs/endurance/python-uv:1": { "pythonVersion": "3.13" },
    "ghcr.io/huldlabs/endurance/postgres-client:1": { "version": "18" },
    "ghcr.io/huldlabs/endurance/secrets:2": {}
  }
}
```

**Next só** (segtools, bulario — Node 22 e bun 1.4.2):

```jsonc
{
  "image": "ghcr.io/huldlabs/endurance/base:0.0.1-dev.3",
  "features": {
    "ghcr.io/huldlabs/endurance/node-bun:1": {
      "nodeVersion": "22",
      "packageManager": "bun"
    },
    "ghcr.io/huldlabs/endurance/secrets:2": {}
  }
}
```

**Python + React** (fabber — Python 3.14 para a infra, Node 24 com pnpm 11.1.1, e o
Pulumi da infra; `playwright` porque há e2e de browser):

```jsonc
{
  "image": "ghcr.io/huldlabs/endurance/base:0.0.1-dev.3",
  "features": {
    "ghcr.io/huldlabs/endurance/python-uv:1": { "pythonVersion": "3.14" },
    "ghcr.io/huldlabs/endurance/node-bun:1": {
      "nodeVersion": "24.21.0",
      "packageManager": "pnpm",
      "pnpmVersion": "11.1.1"
    },
    "ghcr.io/huldlabs/endurance/playwright:1": { "version": "1.63.0", "browser": "chromium" },
    "ghcr.io/huldlabs/endurance/pulumi:1": { "version": "3.263.0" },
    "ghcr.io/huldlabs/endurance/secrets:2": {},
    "ghcr.io/huldlabs/endurance/signing:2": {}
  }
}
```

**WordPress/PHP** (fabber-ecommerce — PHP 8.3 com composer e wp-cli, MySQL 8 e Valkey no
compose, front em Node com `package-lock.json`):

```jsonc
{
  "image": "ghcr.io/huldlabs/endurance/base:0.0.1-dev.3",
  "features": {
    "ghcr.io/huldlabs/endurance/php:1": { "version": "8.3" },
    "ghcr.io/huldlabs/endurance/mysql-client:1": {},
    "ghcr.io/huldlabs/endurance/redis-client:1": {},
    "ghcr.io/huldlabs/endurance/node-bun:1": { "nodeVersion": "24", "packageManager": "npm" }
  }
}
```

**Pesquisa com browser real** (seo-brain — Python, Chrome REAL para o coletor de SERP e
`agent-browser` para os subagentes):

```jsonc
{
  "image": "ghcr.io/huldlabs/endurance/base:0.0.1-dev.3",
  "features": {
    "ghcr.io/huldlabs/endurance/python-uv:1": { "pythonVersion": "3.13" },
    "ghcr.io/huldlabs/endurance/node-bun:1": { "install": false },
    "ghcr.io/huldlabs/endurance/playwright:1": { "browser": "chrome,msedge,firefox,webkit" },
    "ghcr.io/devcontainers/features/github-cli:1": {},
    "ghcr.io/huldlabs/endurance/agent-browser:1": {}
  },
  "mounts": [
    // Sessão do agent-browser (cookies logados = CREDENCIAL): volume por usuário E projeto.
    "source=${localEnv:USER}-seo-brain-agent-browser,target=/home/dev/.agent-browser,type=volume",
    // Estado do `tars secrets` (chave age, op-token, cache cifrado) fica FORA do repo, em
    // ~/.config/tars/<projeto>/. Sem volume, todo rebuild apaga a chave e obriga a refazer o
    // refresh. Contem CREDENCIAL: volume por usuario E projeto, nunca compartilhado (D10).
    "source=${localEnv:USER}-seo-brain-tars,target=/home/dev/.config/tars/seo-brain,type=volume"
  ]
}
```

Ferramenta de desenvolvimento do Python (pytest, import-linter…) vai em
`[dependency-groups] dev` (PEP 735) no `pyproject.toml`, não em `optional-dependencies`: o
`uv sync` instala o grupo `dev` por padrão, e um extra `dev` fica de fora calado (o gate que
dependia dele "passa" sem rodar).

Segredo do projeto (`SERP_DSN`, `DEEPSEEK_API_KEY`) não passa à mão: o projeto declara as
refs `op://` no template do `tars secrets` (`[secrets]` do `.ai/tars.toml`) e roda
`tars secrets exec -- <cmd>`. O valor só existe no env do filho.

### Segredos e assinatura (`tars`, da base)

O `tars` (binário do [HuldLabs/tars](https://github.com/HuldLabs/tars), versão fixada por
digest no `images/base/Dockerfile`) vem na **base**; não há feature `tars` nem checkout
montado. As features `secrets` e `signing` são finas e só ligam o `tars`:

- **`secrets`** liga `tars secrets git-credential` como `credential.helper` do git do
  **sistema** (vale em qualquer repo). O tars só entrega credencial para host declarado
  em `git_hosts`, e lê o token do cache pela chave nomeada em `git_credential`. Os dois
  campos ficam no `[secrets]` do `.ai/tars.toml` do projeto:

  ```toml
  [secrets]
  source = "automation"
  git_hosts = "github.com"      # host fora da lista não recebe credencial nenhuma
  git_credential = "GITHUB_PAT" # NOME da chave no cache, nunca o valor
  ```

  O `gh` usa o mesmo cache: `tars secrets exec -- gh …`.
- **`signing`** roda no postStart `tars identity sign-setup` (gpg.format=ssh, signingkey e
  allowedSignersFile do `[identity]`/`[secrets].allowed_signers`), liga `commit.gpgsign` e
  roda `tars identity verify`. Sem identidade o container sobe com AVISO e o commit
  assinado falha alto. `tars identity provision` é do **dono**, com TTY, uma vez por
  máquina — nenhuma feature o chama.

**PowerShell** (dotfiles — scripts `.ps1`):

```jsonc
{
  "image": "ghcr.io/huldlabs/endurance/base:0.0.1-dev.3",
  "features": { "ghcr.io/huldlabs/endurance/pwsh:1": {} }
}
```

**GitHub CLI, lint e IaC** (farmega — Node 26 com pnpm, `gh`, `shellcheck`/`actionlint` e OpenTofu no lugar
do terraform):

```jsonc
{
  "image": "ghcr.io/huldlabs/endurance/base:0.0.1-dev.3",
  "features": {
    "ghcr.io/huldlabs/endurance/node-bun:1": { "nodeVersion": "26", "packageManager": "pnpm" },
    "ghcr.io/huldlabs/endurance/gh:1": {},
    "ghcr.io/huldlabs/endurance/lint:1": {},
    "ghcr.io/huldlabs/endurance/opentofu:1": {}
  }
}
```

Outros recortes: `duckdb:1` (nexus), `restic-rclone:1` (homelab-infra), `kubectl-helm:1` (tars, dotfiles).

### Tarefa longa (`endurance-bg`)

O harness do agente mata o **grupo de processos** do comando quando ele termina: `cmd &` e
`nohup cmd &` morrem juntos. A base traz `endurance-bg`, um `setsid` com nome, log e
pidfile ([ADR-0001](docs/adr/0001-tarefas-longas.md)):

```bash
endurance-bg start ollama -- ollama serve
endurance-bg status
endurance-bg log ollama
endurance-bg stop ollama
```

Serviço de verdade (banco, fila, storage) continua no compose do projeto.

### Caches em `.cache/` (recomendação, não padrão)

Caches de ferramenta (`uv`, `bun`, `pnpm`, `ms-playwright`, `pycache`) ficam **fora** da
árvore versionada, em `.cache/`, e o diretório **não** entra no git. É o que as features
já fazem por perfil de shell; declarar no projeto torna o ganho explícito e sobrevive a
quem roda o comando sem shell de login:

```jsonc
{
  "containerEnv": {
    "UV_CACHE_DIR": "${containerWorkspaceFolder}/.cache/uv",
    "UV_LINK_MODE": "hardlink",
    "UV_PYTHON_PREFERENCE": "only-managed",
    "PYTHONPYCACHEPREFIX": "${containerWorkspaceFolder}/.cache/pycache",
    "BUN_INSTALL_CACHE_DIR": "${containerWorkspaceFolder}/.cache/bun",
    "PLAYWRIGHT_BROWSERS_PATH": "${containerWorkspaceFolder}/.cache/ms-playwright"
  }
}
```

O `UV_LINK_MODE=hardlink` só rende se o cache estiver no **mesmo filesystem** do repo; num
mount de rede o uv cai para cópia e o ganho evapora.

### Ciclo de vida (opcional)

Dois scripts prontos em `src/lifecycle/scripts/`, ligados no `devcontainer.json` — o
segundo cobre o buraco do segtools, que só tinha `post-create`:

```jsonc
{
  "initializeCommand": "bash .devcontainer/scripts/initialize.sh",
  "updateContentCommand": "bash .devcontainer/scripts/update-content.sh"
}
```

- **`initialize.sh`** roda no HOST e remove container órfão deste devcontainer (parado,
  com bind apontando para caminho que sumiu).
- **`update-content.sh`** valida o `.venv` de volume antes do `uv sync` e recria quando o
  interpretador por dentro não executa mais.

## O que é genérico (aqui) × o que fica no projeto

| Aqui (`endurance`) | No projeto |
| --- | --- |
| `images/base`: git, curl, sops, age, op, gitleaks, task, docker CLI, claude-code (nativo), `tars` (por digest), `endurance-bg`, `endurance-init`, usuário `dev` | `docker-compose.yaml` e os serviços (Postgres, etc.) |
| Features de runtime: `node-bun`, `python-uv`, `php`, `pwsh`, clientes `postgres`/`mysql`/`redis`, `playwright`, `agent-browser` | Versões exatas exigidas pelo projeto (`.node-version`, `.python-version`, lockfiles) |
| `secrets`: `tars secrets git-credential` como helper do git do sistema | O `[secrets]` (refs `op://`, `git_hosts`, `git_credential`), os mounts, os volumes e as portas |
| `signing`: `tars identity sign-setup` + `verify` no postStart | O `[identity]` (ator, ref `op://` da chave) e o `allowed_signers` |
| `lifecycle/scripts`: limpeza de órfão e validação de `.venv` | Ligar os hooks, as portas e o `containerEnv` de cache |
| Workflow de publicação das features e da imagem base | `post-create`/`post-start` do projeto (hooks, stamps, subir o app) |

**Fronteira dura:** nada de credencial, host, dado de cliente ou referência de cofre
entra neste repositório. Cada projeto é apartado; o que se compartilha é a
ferramenta, nunca o conteúdo.

## Features

| Feature | O que traz |
| --- | --- |
| [`node-bun`](src/node-bun) | Node (`nodeVersion`) + bun 1.4.2, pnpm 11.1.1 (corepack) ou npm (`packageManager`), install congelado idempotente |
| [`python-uv`](src/python-uv) | Python 3.12–3.15 (`pythonVersion`, major.minor ou exata, inclusive rc como `3.15.0rc2`) + `uv`, venv e `uv sync` |
| [`secrets`](src/secrets) | `tars secrets git-credential` como helper do git do **sistema** (vale em qualquer repo; só hosts de `git_hosts`) |
| [`signing`](src/signing) | postStart: `tars identity sign-setup`, `commit.gpgsign=true`, `tars identity verify` |
| [`playwright`](src/playwright) | Bibliotecas de sistema (`install-deps`) + browser no cache do container; `browser: chrome`/`msedge` instalam o Chrome/Edge reais; `firefox`/`webkit` = motores do Playwright (o WebKit é o motor do Safari, não o Safari) |
| [`pulumi`](src/pulumi) | CLI do Pulumi (3.263.0), versão pinada |
| [`postgres-client`](src/postgres-client) | `psql`/`pg_dump` do major pedido (repo PGDG assinado) |
| [`lifecycle`](src/lifecycle) | Scripts de `initializeCommand`/`updateContentCommand` (órfãos) |
| [`php`](src/php) | php-cli do minor pedido (Sury) + composer 2.10.3 + wp-cli 2.12.0, checksums conferidos |
| [`mysql-client`](src/mysql-client) | `mysql`/`mysqldump` da Oracle (repo apt assinado, trilha 8.4 LTS; fala com MySQL 8.0 de TLS autoassinado) |
| [`redis-client`](src/redis-client) | `valkey-cli` (também como `redis-cli`) |
| [`pwsh`](src/pwsh) | PowerShell 7.6.6 (tarball oficial, sha256 conferido) |
| [`gh`](src/gh) | GitHub CLI 2.102.0 (repo apt oficial cli.github.com, chave GPG) |
| [`lint`](src/lint) | `shellcheck` 0.11.0 + `actionlint` 1.7.12 (binários oficiais, sha256 conferido) |
| [`opentofu`](src/opentofu) | `tofu` 1.13.1 (binário oficial, `SHA256SUMS` do release) |
| [`duckdb`](src/duckdb) | CLI do `duckdb` 1.5.6 (binário oficial, sha256 do asset) |
| [`kubectl-helm`](src/kubectl-helm) | `kubectl` 1.37.1 (dl.k8s.io) + `helm` 4.3.0 (get.helm.sh), sha256 conferido |
| [`restic-rclone`](src/restic-rclone) | `restic` 0.19.1 + `rclone` 1.75.2 (binários oficiais, `SHA256SUMS`) |
| [`agent-browser`](src/agent-browser) | CLI `agent-browser` dirigindo o Chrome do sistema; sessão em volume por usuário/projeto |

### Testar

```bash
ENDURANCE_UNPUBLISHED=1 tools/test-features.sh            # todas
ENDURANCE_UNPUBLISHED=1 tools/test-features.sh php pwsh   # algumas
```

Os cenários (`test/<feature>/`) rodam sobre `endurance-base:local`
(`docker build -t endurance-base:local images/base`). O CI (`test.yml`) faz o mesmo em PR.
`ENDURANCE_UNPUBLISHED=1` existe até a primeira tag: antes dela o `installsAfter` entre
features do próprio repo não resolve no GHCR.

## Publicação

`.github/workflows/publish.yml` publica as features e a imagem base no GHCR usando
o `GITHUB_TOKEN` do próprio repositório (escopo `packages: write`). Nenhum segredo
extra é necessário. **Só tag publica** — push na `main` não toca o registry.

### Publicar uma versão

Criar a tag é o ato de publicar, e **quem cria é o dono** (humano, metodologia do Tars). A versão da
imagem sai do nome da tag:

```bash
git tag v0.0.1-dev.3
git push origin v0.0.1-dev.3
```

**Numeração (D13, D18):** `0.0.1-dev.N` enquanto o Endurance não é produto, a versão do
`CHANGELOG.md`. A tag `v0.0.1-dev.3` publica `ghcr.io/huldlabs/endurance/base:0.0.1-dev.3`.
Por ser pré-release, ela **não** move nenhuma tag curta (`:0`, `:1`). O projeto fixa a
base pela versão cheia e, de preferência, por **digest** (`base@sha256:…`, segurança
multiusuário item 8). A tag curta `:N` só passa a existir a partir da primeira versão
sem sufixo (`v0.1.0`, quando o Endurance virar produto).

As features têm versão própria (spec containers.dev): ficam em
`ghcr.io/huldlabs/endurance/<feature>:1`, com o canal derivado do
`devcontainer-feature.json`, não da tag do repo.

Para republicar sem criar tag nova (retry de job que falhou), use
**Actions → publish → Run workflow**.

### Release (igual ao Tars)

Depois da base e das features publicadas, o job `release` do `publish.yml` cria a Release do GitHub **por último**:

1. prova no GHCR a base **por digest** (`tars`, `git`, `op` respondem) e cada feature na versão do seu `devcontainer-feature.json`;
2. regenera e confere o catálogo (`tools/gen-catalogo.sh --check`) e anexa `catalogo.md` + `sha256sums`;
3. gera as notas com `tars release-notes` (o `tars` da imagem do `ARG TARS_IMAGE`, por digest): destaques, a seção
   da versão no `CHANGELOG.md`, verificação, comparação com a tag anterior, mais a base por digest;
4. publica a Release; versão com `-` sai como **pré-release**.

Antes da tag, a seção `## <versão>` do `CHANGELOG.md` tem de existir no formato do Tars (só a versão no cabeçalho,
subseções `### O que mudou`/`Por que`/`Arquivos impactados`/`O que o consumidor faz`, destaques em `- **…**`).
Confira local: `tars release-notes --version <versão> --bin endurance`.

### Usar numa máquina

As imagens e features são **privadas** (GHCR privado é gratuito). Uma vez por
máquina, antes do primeiro `devcontainer up`:

```bash
# PAT do cache sops, com escopo `read:packages`
gh auth token                     # ou: sops -d ~/.cache/huld/dev.env.sops | ...
echo "$PAT" | docker login ghcr.io -u <seu-usuario> --password-stdin
```

O login fica em `~/.docker/config.json` e vale para a imagem base e para todas as
features. Depois disso o `devcontainer.json` funciona sem nada a mais — o `image`
e os `features` apontam para `ghcr.io/huldlabs/endurance/...` e o Docker usa a
credencial já guardada.

O PAT vem do cache sops (`~/.cache/segtools/dev.env.sops` / `~/.cache/huld/...`,
ver `secrets/dev.env.tpl`); nunca é versionado aqui.

## Estado

Rascunho. As versões fixadas estão em `images/base/Dockerfile` e no
`devcontainer-feature.json` de cada feature.

## Decisões

`BACKLOG.md` (decisões em vigor e fila) e `docs/adr/`. Histórico: `docs/decisoes-20261008.md` — sequência de uso (a tag esperava o `tars identity`; hoje a
primeira publicação é a `v0.0.1-dev.3`, quando o ecossistema estiver mapeado — D18), features `secrets`/`signing` enxutas delegando ao `tars`, e a cobertura
de tooling por projeto (o que falta: php, mysql-client, redis-client, pwsh).
