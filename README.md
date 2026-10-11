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

## Como um projeto usa

```jsonc
{
  "name": "meu-projeto",
  "image": "ghcr.io/huldlabs/endurance/base:1",
  "features": {
    "ghcr.io/huldlabs/endurance/node-bun:1": {},
    "ghcr.io/huldlabs/endurance/postgres-client:1": { "version": "18" },
    "ghcr.io/huldlabs/endurance/secrets:1": { "project": "meu-projeto" }
  },
  "remoteUser": "dev",
  "mounts": [ "source=meu-projeto-op,target=/run/op-token,type=volume,readonly" ],
  "remoteEnv": { "OP_TOKEN_FILE": "/run/op-token/token" }
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
  "image": "ghcr.io/huldlabs/endurance/base:1",
  "features": {
    "ghcr.io/huldlabs/endurance/python-uv:1": { "pythonVersion": "3.13" },
    "ghcr.io/huldlabs/endurance/postgres-client:1": { "version": "18" },
    "ghcr.io/huldlabs/endurance/secrets:1": { "project": "meu-projeto" }
  }
}
```

**Next só** (segtools, bulario — Node 22 e bun 1.4.2):

```jsonc
{
  "image": "ghcr.io/huldlabs/endurance/base:1",
  "features": {
    "ghcr.io/huldlabs/endurance/node-bun:1": {
      "nodeVersion": "22",
      "packageManager": "bun"
    },
    "ghcr.io/huldlabs/endurance/secrets:1": { "project": "meu-projeto" }
  }
}
```

**Python + React** (fabber — Python 3.14 para a infra, Node 24 com pnpm 11.1.1, e o
Pulumi da infra; `playwright` porque há e2e de browser):

```jsonc
{
  "image": "ghcr.io/huldlabs/endurance/base:1",
  "features": {
    "ghcr.io/huldlabs/endurance/python-uv:1": { "pythonVersion": "3.14" },
    "ghcr.io/huldlabs/endurance/node-bun:1": {
      "nodeVersion": "24.21.0",
      "packageManager": "pnpm",
      "pnpmVersion": "11.1.1"
    },
    "ghcr.io/huldlabs/endurance/playwright:1": { "version": "1.63.0", "browser": "chromium" },
    "ghcr.io/huldlabs/endurance/pulumi:1": { "version": "3.263.0" },
    "ghcr.io/huldlabs/endurance/signing:1": { "allowedSigners": "eu@exemplo ssh-ed25519 AAAA..." },
    "ghcr.io/huldlabs/endurance/secrets:1": { "project": "meu-projeto" }
  }
}
```

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
| `images/base`: git, curl, sops, age, op, gitleaks, task, docker CLI, claude-code, usuário `dev` | `docker-compose.yaml` e os serviços (Postgres, etc.) |
| Features de runtime: `node-bun`, `python-uv`, `postgres-client` | Versões exatas exigidas pelo projeto (`.node-version`, `.python-version`, lockfiles) |
| `secrets`: os scripts `op-sops`, `git-credential-op`, `gh-op`, parametrizados por projeto | Os mounts, os nomes de volume e as portas publicadas |
| `signing`: ssh-agent de caminho fixo, `allowed_signers`, `gpg.format=ssh` | A referência `op://` da chave de assinatura e o arquivo `allowed_signers` |
| `lifecycle/scripts`: limpeza de órfão e validação de `.venv` | Ligar os hooks, as portas e o `containerEnv` de cache |
| `tars`: o binário do assistente | As referências `op://` do cofre e os campos de cada projeto |
| Workflow de publicação das features e da imagem base | `post-create`/`post-start` do projeto (hooks, stamps, subir o app) |

**Fronteira dura:** nada de credencial, host, dado de cliente ou referência de cofre
entra neste repositório. Cada projeto é apartado; o que se compartilha é a
ferramenta, nunca o conteúdo.

## Features

| Feature | O que traz |
| --- | --- |
| [`node-bun`](src/node-bun) | Node (`nodeVersion`) + bun 1.4.2 ou pnpm 11.1.1 (`packageManager`), install congelado idempotente |
| [`python-uv`](src/python-uv) | Python 3.12–3.15 (`pythonVersion`) + `uv`, venv e `uv sync` |
| [`secrets`](src/secrets) | `op-sops.sh` (com fallback Connect → Service Account), `git-credential-op.sh`, `gh-op.sh` |
| [`signing`](src/signing) | `ssh-agent-init` (chave em agente, nunca em disco), `signing-git-config`, `allowed_signers` |
| [`playwright`](src/playwright) | Bibliotecas de sistema do Chromium (`install-deps`) + browser no cache do container |
| [`pulumi`](src/pulumi) | CLI do Pulumi (3.263.0), versão pinada |
| [`tars`](src/tars) | Binário do [HuldLabs/tars](https://github.com/HuldLabs/tars), do Release |
| [`postgres-client`](src/postgres-client) | `psql`/`pg_dump` do major pedido (repo PGDG assinado) |
| [`lifecycle`](src/lifecycle) | Scripts de `initializeCommand`/`updateContentCommand` (órfãos) |

## Publicação

`.github/workflows/publish.yml` publica as features e a imagem base no GHCR usando
o `GITHUB_TOKEN` do próprio repositório (escopo `packages: write`). Nenhum segredo
extra é necessário. **Só tag publica** — push na `main` não toca o registry.

### Publicar uma versão

Criar a tag é o ato de publicar; a versão da imagem sai do nome dela:

```bash
git tag v1.2.0
git push origin v1.2.0
```

A tag `v1.2.0` publica `ghcr.io/huldlabs/endurance/base:1.2.0` **e**
`ghcr.io/huldlabs/endurance/base:1` — o `:1` é o que os projetos consomem, o
`:1.2.0` fica para quem quer pinar exato. As features seguem o major: ficam em
`ghcr.io/huldlabs/endurance/<feature>:1` (o `devcontainers/action` deriva o canal
do `devcontainer-feature.json`, não da tag).

Para republicar sem criar tag nova (retry de job que falhou), use
**Actions → publish → Run workflow**.

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

`docs/decisoes-20261008.md` — sequência de uso (segurar a tag `v0.1.0` até o Tars
dev.10), features `secrets`/`signing` enxutas delegando ao `tars`, e a cobertura
de tooling por projeto (o que falta: php, mysql-client, redis-client, pwsh).
