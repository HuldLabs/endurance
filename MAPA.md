# MAPA — de `/workspace/.devcontainer/` para cá

Cada arquivo do devcontainer do segtools e onde ele foi parar. "Fica no segtools" = e'
conteudo DO projeto, nao do ambiente.

| Arquivo de origem | Destino | Por que |
| --- | --- | --- |
| `Dockerfile` (toolchain) | `images/base/Dockerfile` (base) + `src/{node-bun,python-uv,postgres-client}` (o `tars` é binário da base, D17) | A tabela de versoes citava `apps/hub`, `.node-version` e `infra/compose.yaml`: e' DERIVADA do projeto. Vira option de feature; o projeto continua declarando a versao. |
| `Dockerfile` (git, sops, age, op, gitleaks) | `images/base/Dockerfile` | Comum a todo projeto do ecossistema — fica na base. |
| `Dockerfile` (sudo restrito) | `images/base/Dockerfile` | O gid do socket do Docker varia por maquina; casar o grupo exige root em runtime. |
| `Dockerfile` (usuario `node`) | `images/base/Dockerfile` — agora `dev` | Nome neutro: a base do ecossistema nao e' um container de app Node. Uid continua 1000. |
| `devcontainer.json` (features, mounts, ports, remoteUser) | Fica no segtools | Compose, PG, volumes, portas e o PATH dos benchmarks sao do projeto. O `README.md` mostra o exemplo ~15 linhas. |
| `devcontainer.json` (`ghcr.io/devcontainers/features/github-cli` 2.101.0) | `src/gh` (2.102.0, repo apt oficial) | Lacuna L1 de `docs/ecossistema.md`: seis repos pedem `gh`; o segtools troca a feature externa pela daqui. |
| `op-sops.sh` | Removido (F8) → `tars secrets` | O tars resolve o token da service account; logica propria aqui era defeito (R5). |
| `git-credential-op.sh` | `src/secrets/install.sh` → `tars secrets git-credential` (helper do sistema) | Le do cache, so' para hosts de `[secrets].git_hosts` (tars dev.19). |
| `gh-op.sh` | Removido (F8) → `tars secrets exec -- gh …` | O cache do tars ja' entrega o token so' ao processo filho. |
| `write-signing-key.sh` | Removido (F8) → `tars identity provision` (dono) + `sign-setup` (`src/signing`) | A chave e' do `tars identity`. |
| `post-create.sh` | Fica no segtools | Hooks, `origin` a partir de `config/github.toml`, grupo do socket, posse do venv: tudo e' do repo. |
| `post-start.sh` (secrets/signing/gh) | `postStartCommand` da `src/signing` + `tars secrets refresh/exec` | O segtools troca `secrets-refresh`/`secrets-exec` por `tars secrets refresh`/`exec`. |
| `post-start.sh` (bun install, uv sync, Playwright, hub) | Fica no segtools | Stamp de lockfile e subir o app sao do projeto; `bun install`/`uv sync` ganharam versao idempotente nas features. |
| `devcontainer-lock.json` | Nao portado | Lock gerado pelo devcontainer CLI para ESTE `devcontainer.json`; cada projeto gera o seu. |
| `docs/WSL-MIGRATION.md`, `docs/devcontainer-lessons.md` | Fica no segtools | Historico e licoes de OUTRO repo. O que virou regra esta nos comentarios daqui. |

## Lacunas do ecossistema (fora do segtools)

Origem: `docs/ecossistema.md` (levantamento de 14/10). Não vêm do devcontainer do segtools; cada uma é binário
oficial do upstream, versão por option.

| Lacuna | Destino | Upstream |
| --- | --- | --- |
| L2 shellcheck + actionlint | `src/lint` | github.com/koalaman/shellcheck, github.com/rhysd/actionlint |
| L3 terraform → OpenTofu | `src/opentofu` | github.com/opentofu/opentofu (nenhum repo versiona `.tf` nem usa state/cloud da HashiCorp) |
| L4 Node 20/24/26, Python 3.12/3.15.0rc2 | `src/node-bun` (libatomic1 para o Node 26), `src/python-uv` (versão exata/rc; interpretadores em `/usr/local/share/uv/python`) | nodejs.org, astral.sh |
| L5 duckdb | `src/duckdb` | github.com/duckdb/duckdb |
| L6 restic + rclone | `src/restic-rclone` | github.com/restic/restic, github.com/rclone/rclone |
| L7 kubectl + helm | `src/kubectl-helm` | dl.k8s.io, get.helm.sh |
