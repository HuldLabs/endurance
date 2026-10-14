# CHANGELOG — Endurance

Formato: o que mudou · por quê · arquivos impactados · o que o consumidor faz (doutrina `versionamento-de-extracao`).
Desde a 0.0.1-dev.3 cada seção é `## <versão>` (só a versão no cabeçalho) com as 4 subseções `###` do Tars, e
`- **Destaque.** …` em "O que mudou": é o que o `tars release-notes` lê para gerar as notas da Release.

## 0.0.1-dev.4

### O que mudou
- **`tars` 0.0.1-dev.26 na base.** Por digest (`sha256:51de0d47…`), pela rotina do Tars na base; `.ai` no lock da
  dev.26 (cada guard só no seu evento).
- **`python-uv` 1.2.0 exporta `UV_PROJECT_ENVIRONMENT`.** O `uv sync` passa a usar o `venvPath` em vez do `.venv`
  do diretório do projeto. Vale fora de shell de login pelo `containerEnv` (fixo no default `/workspace/.venv`: a
  spec não interpola option) e em shell de login pelo profile, com o valor da option.
- **`python-uv` 1.3.0 traz a `libgomp1`.** Runtime OpenMP que wheels como lightgbm, xgboost e scikit-learn carregam
  (`libgomp.so.1`); acaba o `.deb` extraído em `/tmp` com `LD_LIBRARY_PATH` no seo-brain.
- **`postgres-client` testado no CI.** Cenários `default` (18) e `pg17` provam `psql` e `pg_dump` no major da option;
  a feature entra na matriz do `test.yml`.
- **README: exemplo do seo-brain refeito.** `postCreateCommand` com `endurance-init` e `uv sync --extra all`, GPU
  opcional (`--gpus all` comentado) para o extra `rerank`. Base por digest, só features do Endurance (`gh` no lugar do
  `github-cli` externo), `runArgs` com `host.docker.internal`, venv em volume nomeado e trecho do `compose.yaml` do
  projeto com `ollama` (GPU NVIDIA) e Postgres `serp`; serviço e backup são do projeto.

### Por que
Pedido do coord seo-brain (14/10): um `uv` no host recriou o `.venv` do bind com o Python do host e o container
ficou sem Python; o `postgres-client` não tinha teste; o exemplo do README não batia com o projeto.

### Arquivos impactados
`src/python-uv/`, `test/python-uv/`, `test/postgres-client/` (novo), `.github/workflows/test.yml`, `README.md`,
`docs/catalogo.md`, `BACKLOG.md`, `CHANGELOG.md`, `VERSION`.

### O que o consumidor faz
Nada obrigatório: `python-uv:1` pega a 1.3.0. Quem usa `venvPath` fora do default declara
`"containerEnv": { "UV_PROJECT_ENVIRONMENT": "<venvPath>" }` no próprio devcontainer. Recomendado: volume nomeado
por usuário e projeto no `venvPath` (exemplo no README) e apagar o `.venv` antigo do repo no host.

## 0.0.1-dev.3

### O que mudou
- **Gate do Tars na base (`tools/tars-atual.sh`).** Compara o `ARG TARS_IMAGE` com a última versão publicada de
  `ghcr.io/huldlabs/tars` (pré-release incluída) e exige que o digest fixado seja o da tag declarada: no PR avisa
  (`::warning::`), na tag (`publish.yml`) falha antes de publicar; digest divergente falha sempre. Rotina do bump no
  README ("Rotina do Tars na base").
- **Primeira publicação, com Release completa.** A tag `v0.0.1-dev.3` publica a base e as features no GHCR e, por
  último, a Release do GitHub com notas do `tars release-notes`, a base por digest e o `docs/catalogo.md` anexo
  (com `sha256sums`). Versão com `-` sai como pré-release. A numeração ficou alinhada: é a `v0.0.1-dev.3`, não a `v0.1.0`.
- **Catálogo gerado (`docs/catalogo.md`).** Cada ferramenta da base (versão e para que serve) e cada feature (id,
  versão, ref de uso, todas as options, `installsAfter`), gerado por `tools/gen-catalogo.sh` dos
  `devcontainer-feature.json` e dos marcadores `# catalogo:` do `Dockerfile`; o `test.yml` falha se divergir.
- **`tars` 0.0.1-dev.25 na base.** Binário copiado da imagem do Tars por digest (D17); `.ai` no lock da dev.25, com
  a doutrina `release` declarada (o processo desta tag: PR final, merge do dono como aval, coord corta a tag, D20).
  As notas da Release saem do `tars release-notes --kind image`, sem pós-processamento.
- **`secrets` 2.0.0 e `signing` 2.0.x finas.** Só `tars secrets git-credential` (helper do git do sistema) e
  `tars identity sign-setup`/`verify` no postStart; os scripts próprios de segredo saem. `signing` 2.0.1 liga
  `commit.gpgsign` no sistema já no build e usa `timeout` no postStart. O `tars identity provision` é só do dono (TTY).
- **Feature `tars` removida (D19).** O shim de `TARS_HOME` não tem mais o que fazer.
- **Features novas (lacunas L1–L7 de `docs/ecossistema.md`).** `gh` 1.0.0 (GitHub CLI 2.102.0, apt oficial),
  `lint` 1.0.0 (shellcheck 0.11.0 + actionlint 1.7.12), `opentofu` 1.0.0 (1.13.1), `duckdb` 1.0.0 (1.5.6),
  `kubectl-helm` 1.0.0 (kubectl 1.37.1 + helm 4.3.0), `restic-rclone` 1.0.0 (restic 0.19.1 + rclone 1.75.2).
- **Feature `opencode`.** `opencode` 1.0.0 (opencode 1.18.29, binário oficial, sha256 por arch) para o seo-brain.
- **`node-bun` e `python-uv` mais largos.** Node 26 instala a `libatomic1`; `python-uv` aceita versão exata e rc
  (`3.15.0rc2`) e guarda os interpretadores em `/usr/local/share/uv/python` (antes iam para `/root` e o venv do
  `dev` dava "Permission denied").
- **CI.** `test.yml`/`publish.yml` fazem login de leitura no GHCR antes do build; o build da base roda só com esse
  login (F16); actions pinadas por SHA; dispatch só em tag.
- **`rg` (ripgrep) 14.1.1 na base.** Pacote apt da trixie com versão exata (`14.1.1-1+b4`), ARG com marcador.
- **Locale `pt_BR.UTF-8` e fuso `America/Sao_Paulo` na base.** `locales` + `locale-gen`, `LANG` (sem `LC_ALL`, para o projeto poder sobrescrever) e `tzdata` +
  `TZ`; o projeto sobrescreve por `containerEnv`. Aparece no catálogo como "locale e fuso".
- **Catálogo cobra o marcador.** `tools/gen-catalogo.sh` (e o `--check` do CI) reprova `ARG *_VERSION`/`*_IMAGE` sem
  `# catalogo:` imediatamente antes; o `ARG DEBIAN_VERSION` órfão saiu.
- **Release prova a tag curta.** O job `release` confere `:<versão cheia>` e `:<major>` de cada feature e exige o mesmo
  digest nas duas.
- **Documentação.** O README ganha a seção "Como o projeto sobe a base e as features" (base por digest, features
  pelo major, bump por PR do projeto), além de o volume do `tars secrets`, a regra do `[dependency-groups]` e o link do catálogo;
  os `.githooks/` voltam a ser executáveis.

### Por que
Decisões do dono de 14/10 (D18, numeração e "Release completa, igual ao Tars"); correção do desenho combinada com o
coord segtools (D4); pedidos do seo-brain; lacunas L1–L7 do mapeamento do ecossistema; F8: lógica de segredo própria
no consumidor é defeito (R5), e o Tars dev.19 publicou a imagem e os comandos.

Bugs reportados por consumidores que esta versão fecha: nenhum (é a primeira publicação). Bugs do Tars achados
aqui e fechados lá: sync que apagava a `lib-json.sh` e guards que aprovavam sem ela (14/10, dev.21/dev.22);
imagem com tag de versão antes da Release (gate deste repo, 14/10, dev.24).

### Arquivos impactados
`README.md`, `BACKLOG.md`, `HANDOFF.md`, `CHANGELOG.md`, `MAPA.md`, `docs/decisoes-20261008.md`,
`docs/ecossistema.md`, `docs/catalogo.md` (novo, gerado), `tools/gen-catalogo.sh` (novo),
`src/{gh,lint,opentofu,duckdb,kubectl-helm,restic-rclone,node-bun,python-uv,opencode}/`, `.githooks/`,
`images/base/Dockerfile`, `src/secrets/`, `src/signing/`, `src/tars/` (removida), `test/`,
`.github/workflows/{test,publish}.yml`, `tools/tars-atual.sh` (novo), `.ai/tars.toml`, `.ai/tars.lock`, `.ai/base/`, `VERSION` (novo: fonte da versão), `lifecycle/` (antes `src/lifecycle/`).

### O que o consumidor faz
- Fixe a base como `base:0.0.1-dev.3`, de preferência por digest (o digest está nas notas da Release); não use `:1`.
- Tire a feature `tars` e o mount do checkout em `/opt/tars` do `devcontainer.json`.
- `secrets:2` e `signing:2` sem options (`project`, `patRef`, `allowedSigners`… saíram); declare `git_hosts` e
  `git_credential` no `[secrets]` e o `[identity]` no `.ai/tars.toml`.
- Troque `secrets-refresh`/`secrets-exec`/`gh-op` por `tars secrets refresh`/`tars secrets exec -- …`.
- Quem tem o venv do `python-uv` num volume nomeado criado pela 1.0.0: apague esse volume uma vez.
- Os scripts de ciclo de vida ficam em `lifecycle/scripts/` (antes `src/lifecycle/scripts/`, que não é feature).
- Consulte `docs/catalogo.md` (também anexo à Release) para as options de cada feature.

## 0.0.1-dev.2

_13/10/2026_

- **O que mudou:**
  - features novas: `php`, `mysql-client`, `redis-client`, `pwsh`, `agent-browser`;
  - `playwright` aceita `browser: chrome` (Google Chrome real);
  - `node-bun` aceita `packageManager: npm`;
  - `secrets` liga o helper do git no nível do sistema;
  - `tars` passa a ser um shim sobre o checkout montado (`TARS_HOME`);
  - a base ganha `endurance-bg` e passa a buildar de novo; o `claude` entra pelo instalador nativo;
  - `publish.yml` gera o `major` da tag corretamente, e o novo `test.yml` testa as features.
- **Por quê:**
  - o pedido do seo-brain de 13/10 (Chrome real, agent-browser, push em qualquer repo, tarefa longa);
  - a cobertura de 08/10 (php, mysql, redis, pwsh, npm);
  - três defeitos da `main` que impediam qualquer publicação.
- **Arquivos impactados:** `images/base/Dockerfile`, `src/{php,mysql-client,redis-client,pwsh,agent-browser}/`,
  `src/{playwright,node-bun,tars}/`, `src/secrets/install.sh`, `test/`, `tools/test-features.sh`,
  `.github/workflows/{publish,test}.yml`, `docs/adr/0001-tarefas-longas.md`, `README.md`, `BACKLOG.md`, `HANDOFF.md`.
- **O que o consumidor faz:** nada ainda (sem tag). Depois dela:
  - a feature `tars` exige o checkout do Tars montado em `TARS_HOME` (padrão `/opt/tars`);
  - quem usava `setsid … &` no Taskfile troca por `endurance-bg start <nome> -- …`.

## 0.0.1-dev.1

_13/10/2026_

- **O que mudou:** o repo passa a consumir o Tars (`.ai/`, `.githooks/`, `.claude/`) e ganha `AGENTS.md`,
  `BACKLOG.md`, `HANDOFF.md` e este CHANGELOG. Base e features de `f0e260e` entram como estão.
- **Por quê:** doutrina `novo-repo`; as decisões de 08/10 e a fila do seo-brain só viviam em conversa.
- **Arquivos impactados:** `AGENTS.md`, `BACKLOG.md`, `HANDOFF.md`, `CHANGELOG.md`, `.ai/`, `.githooks/`, `.claude/`,
  `.gitignore`.
- **O que o consumidor faz:** nada. Ainda não há tag nem consumidor.
