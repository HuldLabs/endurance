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

## O que é genérico (aqui) × o que fica no projeto

| Aqui (`endurance`) | No projeto |
| --- | --- |
| `images/base`: git, curl, sops, age, op, gitleaks, usuário `dev` | `docker-compose.yaml` e os serviços (Postgres, etc.) |
| Features de runtime: `node-bun`, `python-uv`, `postgres-client` | Versões exatas exigidas pelo projeto (`.node-version`, `.python-version`, lockfiles) |
| `secrets`: os scripts `op-sops`, `git-credential-op`, `gh-op`, parametrizados por projeto | Os mounts, os nomes de volume e as portas publicadas |
| `tars`: o binário do assistente | As referências `op://` do cofre e os campos de cada projeto |
| Workflow de publicação das features e da imagem base | `post-create`/`post-start` do projeto (hooks, stamps, subir o app) |

**Fronteira dura:** nada de credencial, host, dado de cliente ou referência de cofre
entra neste repositório. Cada projeto é apartado; o que se compartilha é a
ferramenta, nunca o conteúdo.

## Features

| Feature | O que traz |
| --- | --- |
| [`node-bun`](src/node-bun) | Node (versão por option) + bun + `bun install` idempotente |
| [`python-uv`](src/python-uv) | Python (versão por option) + `uv`, venv e `uv sync` |
| [`secrets`](src/secrets) | `op-sops.sh`, `git-credential-op.sh`, `gh-op.sh`, chave de assinatura SSH |
| [`tars`](src/tars) | Binário do [HuldLabs/tars](https://github.com/HuldLabs/tars), do Release |
| [`postgres-client`](src/postgres-client) | `psql`/`pg_dump` do major pedido (repo PGDG assinado) |

## Publicação

`.github/workflows/publish.yml` publica as features e a imagem base no GHCR usando
o `GITHUB_TOKEN` do próprio repositório (escopo `packages: write`). Nenhum segredo
extra é necessário.

## Estado

Rascunho. As versões fixadas estão em `images/base/Dockerfile` e no
`devcontainer-feature.json` de cada feature.
