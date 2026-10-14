# Ecossistema → Endurance (D18)

Levantamento de 2026-10-14, só leitura, a partir dos arquivos versionados (`git ls-files`) de cada repo em
`/home/pablo/projects`. As contagens de CLI vêm de um grep por `<cli> <subcomando>` nos arquivos versionados
(sem lockfiles nem `.md`), então são indício e não prova. Nenhum `.env` nem `*.sops*` foi lido.

**O que o Endurance já cobre.** A base (`images/base/Dockerfile`) traz git, python3 3.13 (do sistema), sops 3.9.4,
age 1.2.0, gitleaks, op (1Password CLI), docker-ce-cli e compose, task 3.49.1 e claude. As features em `src/*` são
agent-browser, lifecycle, mysql-client (8.4), node-bun (node 22, bun 1.4.2, pnpm 11.1.1), php (8.3, composer,
wp-cli), playwright (1.63.0), postgres-client (18), pulumi (3.263.0), pwsh (7.6.6), python-uv (3.13, uv 0.12.19),
redis-client, secrets e signing.

## 1. Tabela por repo

| Repo | Stack / versões (origem) | CLIs (origem: grep) | Serviços no compose (origem) | Tars? | Features que cobrem | LACUNAS |
|---|---|---|---|---|---|---|
| **segtools** | Bun 1.4.2 (`package.json` packageManager); Node 22 (`.node-version`, `.devcontainer/Dockerfile` FROM node:22-trixie-slim); Python >=3.13,<3.14 (`pyproject.toml`, `.python-version`) | task, uv, op, bun, go, az, gh, sops, age, playwright, mc, wp, gitleaks, composer, cargo, psql, deno, pwsh | ollama 0.35.0, segtools-pg 18 + pgvector (`infra/compose.yaml`) | sim (`.ai/tars.toml`) | node-bun, python-uv, postgres-client, playwright, pwsh, php, secrets, signing | **gh** (o devcontainer atual usa `ghcr.io/devcontainers/features/github-cli` 2.101.0, em `.devcontainer/devcontainer.json`); az, go, deno e mc são menores |
| **seo-brain** | Python 3.13 (`.python-version`; `pyproject.toml` pede >=3.11); web em bun (`apps/web/bun.lock`) | uv, task, sops, npx, playwright, op, ollama, age, gitleaks, bun, deno | serp-pg:18 (`infra/compose.yaml`) | sim | python-uv, node-bun, playwright, postgres-client, secrets | ollama é serviço do compose (R4), não lacuna; deno é menor |
| **kipp** | Bun 1.4.2 (`package.json`; `Dockerfile` FROM oven/bun) | bun, op, task, age | postgres 18.0 (`deploy/dev/compose.yml`) | sim | node-bun, postgres-client, secrets | nenhuma |
| **tars** | Bun 1.4.2 (`.github/workflows/release.yml` bun-version; `bun.lock`) | op, bun, sops, task, gh, age, gitleaks, kubectl, helm | — | sim | node-bun, secrets, signing | **gh**; kubectl/helm (pouco uso) |
| **nexus** | Python 3.12 (`.python-version`, `pyproject.toml` >=3.12); admin em Node (`apps/admin/package.json`); workflow `build-pg-duckdb.yml` | duckdb, uv, npx, task, psql, go, op | sem compose versionado | não | python-uv (com version=3.12), node-bun, postgres-client | **duckdb CLI** |
| **homelab-infra** | Python >=3.11, 3.12 no CI (`pyproject.toml`, `.github/workflows/ci.yml`); `requirements.txt` | pyinfra, restic, op, age, uv, rclone, psql | openobserve na POC (`poc/telemetria/compose.yaml`); `receitas/*/compose*.yaml` são produção, não dev | não | python-uv, postgres-client, secrets | **restic, rclone** (pyinfra vem pelo uv) |
| **dotfiles** | Python 3.12 (`.python-version`; `pyproject.toml` >=3.11); PowerShell (`Dockerfile` FROM mcr.microsoft.com/powershell) | task, pwsh, op, gh, sops, age, kubectl, shellcheck, uv, actionlint, gitleaks | — | não | pwsh, python-uv, secrets | **gh, shellcheck, actionlint**; kubectl |
| **fabber-ecommerce** / **fabber2-ecommerce** (cópias idênticas, 917 arquivos cada) | Python ==3.15.0rc2 (`.python-version`, `pyproject.toml`, `.devcontainer/Dockerfile` FROM python:3.15.0rc2-slim); Node 24.21.0 (`.devcontainer/Dockerfile` ARG) e 24.10.0 no CI (`deploy-*.yml`); PHP 8.3 (`security.yml`); WordPress (`infra/docker/wordpress/composer.json`); Pulumi 3.263.0 | wp, php, op, pyinfra, pulumi, uv, task, gh, mysql, composer, gitleaks, caddy, cloudflared, semgrep, shellcheck | caddy, next, id, wordpress, 1password connect 1.7.3, cloudflared 2026.9.1 (`infra/compose/compose.yaml`) | não | php, pulumi, mysql-client, node-bun (version=24), python-uv (version=3.15.0rc2, se o uv tiver a rc), secrets | **gh**; semgrep e shellcheck; caddy e cloudflared só se forem rodar fora do compose |
| **farmega** | Node 26.1.0 e pnpm 11.1.1 (`package.json` engines/packageManager); Python >=3.13 (`.python-version`, `pyproject.toml`); devcontainer `mcr.microsoft.com/devcontainers/base:ubuntu-24.04` (`.devcontainer/devcontainer.json`) | task, uv, gh, shellcheck, sops, age, op, terraform, pnpm, playwright | `app` (build local, `docker-compose.yml`) | não | node-bun (node=26, pm=pnpm), python-uv, playwright, secrets | **gh, shellcheck, terraform** |
| **farmega.v2** | Python >=3.12, monorepo uv (`pyproject.toml` e cerca de 18 `pyproject.toml` internos); web em Node (`apps/web/package.json`) | uv, task, gh, op, terraform, shellcheck, mc | postgres 18-alpine, redis 7-alpine, rabbitmq 3, minio e mc (`infra/docker/compose.yaml`) | não | python-uv, node-bun, postgres-client, redis-client | **gh, terraform**; minio-client (mc) é menor |
| **fabber** | Next.js e React, Node 20 no CI (`.github/workflows/ci.yml`); `@playwright/test` (`package.json`) | npx, vercel, task | — | não | node-bun (version=20), playwright | **vercel CLI** (vem por npx, então baixa prioridade) |
| **vpnai** | Scripts Python sem manifesto (`opencode-key-rotator.py`, `data/init_db.py`) + perfis OpenVPN (`profiles/*.ovpn`) + sqlite | openvpn (pelos arquivos de estado) | — | não | python-uv | openvpn não cabe em devcontainer; fora de escopo |
| **bulario** | Só docs e referências (TSX e JSON em `docs/references/`); sem manifesto | — | — | não | — | dado insuficiente |
| **lazarus** | Só ADR e README (9 arquivos): "motor de busca… sobre PostgreSQL", pg_search BM25 + pgvector (`README.md`, último commit) | — | — | sim | postgres-client (previsto) | ainda não há código |
| **seld** | IAM da org, README e BACKLOG (30 arquivos) | sops (3 menções) | — | sim | — | ainda não há código |
| **huldlabs** | Repo de coordenação (8 arquivos, BACKLOG) | — | — | não | — | não precisa de ambiente de dev |
| **seo-expert** | Skills com `scripts/package.json` (`skills/seo-research/*/scripts/package.json`); inativo desde 2026-04-04 | — | — | não | node-bun | inativo (seo-brain absorveu) |
| **pion** | Só `README.md` (framework Python, irmão do Sofon) | — | — | não | — | vazio |
| **sofon** | Só `README.md` | — | — | não | — | vazio |
| **tomo** | Só `README.md` | — | — | não | — | vazio |
| **sandbox** | Nenhum arquivo versionado | — | — | não | — | vazio |
| **tokenhood** | Nenhum arquivo versionado | — | — | não | — | vazio |

**Org HuldLabs sem clone local:** figma-kiwi, brand, morse, murph, bulq, zenproxy, thood, pg_duckdb e .github estão
todos sem clone local. Observação: `homelab-infra/receitas/thood/files/Dockerfile` existe, mas é a receita de deploy
do thood, não o código dele.

## 2. Lacunas consolidadas

| # | Feature ou ajuste | Repos que pedem | Prioridade |
|---|---|---|---|
| L1 | Feature **`gh`** (GitHub CLI) | segtools (hoje via feature externa 2.101.0), tars, dotfiles, fabber-ecommerce, farmega, farmega.v2 | **Alta** |
| L2 | Feature **`lint`**: shellcheck e actionlint (talvez semgrep) | dotfiles, farmega, farmega.v2, fabber-ecommerce | Média |
| L3 | Feature **`terraform`** (ou OpenTofu) | farmega, farmega.v2 | Média |
| L4 | node-bun tem que aceitar Node 20, 24 e 26 e python-uv tem que aceitar 3.12 e 3.15.0rc2. **Verificar** se as options suportam esses valores, inclusive a rc. | fabber (20), fabber-ecommerce (24), farmega (26), nexus/farmega.v2/dotfiles (3.12), fabber-ecommerce (3.15rc2) | Média |
| L5 | Feature **`duckdb`** (CLI) | nexus (e pg_duckdb, sem clone) | Média |
| L6 | Feature **`backup`**: restic e rclone | homelab-infra | Baixa |
| L7 | Feature **`kube`**: kubectl e helm | dotfiles, tars | Baixa |
| L8 | `deno`, `minio mc` (`go`, `az`: retirado: sem uso real) | segtools, seo-brain, farmega.v2 (uso esparso) | Baixa; esperar pedido |
| — | ollama, caddy, cloudflared, rabbitmq, minio, postgres, redis | — | Não são lacunas: são serviços do compose (R4) |

## 3. Repos sem dado suficiente

bulario, lazarus, seld, pion, sofon, tomo, sandbox e tokenhood (só docs ou vazios), vpnai (sem manifesto) e todos
os repos da org sem clone local.

## Achado para outra frente

`vpnai` versiona `data/bootstrap/state/openvpn-auth.txt` e `opencode-vpn-pairs.{csv,json}`. Os nomes sugerem
credencial. O conteúdo **não foi lido**. Vai para a seção Segurança do `BACKLOG.md` do huldlabs para verificar.
