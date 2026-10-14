# BACKLOG — Endurance

## Decisões em vigor

| # | decisão | fonte |
| --- | --- | --- |
| D1 | Base enxuta (`images/base`) + um runtime por Dev Container Feature em `ghcr.io/huldlabs/endurance/<feature>`; nada exige runtime de quem não usa | `README.md` |
| D2 | Só tag `v*` publica; versão sai da tag | `6ae08cf` |
| D3 | ~~Tag espera `tars identity` no Tars~~ — cumprido: dev.18 do Tars (`f6e1b05`, 14/10). O gatilho da tag agora é a D18 | `docs/decisoes-20261008.md` §Sequence 1 |
| D4 | `secrets` e `signing` finas: chamam `tars secrets refresh/exec`, `tars secrets git-credential`, `tars identity sign-setup` e `tars identity verify` (postStart). O `identity provision` é só do dono (TTY, uma vez por máquina); automação nunca se auto-provisiona | idem §Sequence 2, corrigido em 14/10 (dono + coord segtools) |
| D5 | ~~Feature `tars` central, options `version` (digest), `autoSync` (default true), `actor`, `profileMount`~~ — superada pela D17/D19: a versão (digest) é ARG da base; `autoSync`/`actor`/`profileMount` voltam como feature só quando houver comportamento a ligar | idem §Sequence 3 |
| D6 | `tars up` dispara onCreate/postCreate/postStart/updateContent | idem §Sequence 4 |
| D7 | Migração: segtools → demais projetos → mini PC e runners | idem §Sequence 5 |
| D8 | Serviços ficam no compose do projeto, nunca na imagem | idem §Coverage |
| D9 | Gate no `tars doctor`: marcadores de stack × features ligadas (ex.: `composer.json` sem `php` falha) | idem §Coverage |
| D10 | Segurança multiusuário: os 11 itens (sem segredo na imagem, volumes por usuário/projeto, socket Docker off por padrão, sem agente SSH do dono em automação, menor escopo, digest fixo e assinado, portas em `127.0.0.1`…) | idem §Multi-user security |
| D11 | Chrome real entra como option `browser: chrome` da `playwright` (sem feature `chrome` separada) | dono, 13/10 |
| D12 | `agent-browser` vira feature própria: npm global pinado, usa o Chrome do sistema (nunca `agent-browser install`), sessão/cookies em volume por usuário e projeto | dono, 13/10 |
| D13 | Até a primeira tag: `0.0.1-dev.N` + `CHANGELOG.md` (doutrina `novo-repo`) | dono, 13/10 |
| D14 | Tarefa longa = `endurance-bg` (`setsid` com nome/log/pidfile) **dentro** do container, nunca no host | `docs/adr/0001-tarefas-longas.md` |
| D15 | `mysql-client` = cliente da Oracle (repo apt oficial, trilha LTS), não o MariaDB da distro | prova de 13/10 contra `mysql:8.0.46` (`src/mysql-client/install.sh`) |
| D16 | ~~Feature `tars` = shim que roda o checkout montado em `TARS_HOME`, só como **ponte** até a D17~~ — ponte encerrada pela D19 | `gh release list -R HuldLabs/tars` vazio (13/10) |
| D18 | A primeira tag publicada é a **`v0.0.1-dev.3`** (numeração da D13; `v0.1.0` só quando o Endurance virar produto) e só sai depois que **todo o ecossistema** estiver mapeado e ajustado no Endurance, para evitar tags desnecessárias (substitui o gatilho da D3) | dono, 14/10 |
| D17 | O `tars` é peça **da base** (todo projeto usa). É o binário compilado (`bun build --compile`), copiado de uma imagem do Tars por digest: `COPY --from=ghcr.io/huldlabs/tars:<v>@sha256:… /tars /usr/local/bin/tars`. Sem Node e sem credencial no build. **Cumprida (F8):** `ARG TARS_IMAGE` + estágio `tars` no `images/base/Dockerfile`, dev.26 `sha256:51de0d47…` | dono, 14/10 |
| D20 | **Quem corta a tag é o coord**: o merge do dono no PR final da versão é o aval; o coord corta a tag anotada como Daneel, acompanha o CI e confere a Release. Tag com Release publicada nunca se move (substitui "tag é do dono"). Regra do Tars: `.ai/governance/versionamento-de-extracao.md` §"Quem corta a tag" (HuldLabs/tars#25, dev.24) | dono, 14/10 |
| D19 | Feature `tars` **removida** (não depreciada): com o binário na base o shim não tem o que fazer, e não há option de comportamento implementada (D5). Mínimo = apagar; quem a usava tira a linha do `devcontainer.json` e o mount do checkout | worker F8, 14/10 |

## Fila

| # | item | depende de | aceite |
| --- | --- | --- | --- |
| F3 | Segredos do seo-brain (`SERP_DSN`, `DEEPSEEK_API_KEY`) por ref `op://`: o **seo-brain** declara o template e o `[secrets] source=automation` no `.ai/tars.toml` e roda `tars secrets exec -- …`. Do lado do Endurance basta a feature `tars` + o volume do token | coord seo-brain; desenho do `[secrets]` com o coord do Tars | o coletor roda por `tars secrets exec` sem colar valor à mão; nada em argv/log |
| F5 | Devcontainer próprio do seo-brain consumindo as features (exemplo no `README.md`) | F9, F3 | o seo-brain sobe com `devcontainer up` sem o do segtools |
| F9 | Tag `v0.0.1-dev.3` (D18): o merge do dono no PR final é o aval; o coord corta a tag (D20) | F8, mapeamento do ecossistema | publicação no GHCR pela tag, imagem referenciada por digest |
| F10 | Migrar o segtools (D7), tirando o remendo do Chrome do Dockerfile dele (`22f4f5e6`) | F9 | segtools sobe pelas features; remendos do Dockerfile dele removidos |
| F16 | ~~Login duplo no `publish.yml`~~ — **feito:** o build da base roda só com o login de leitura (`load: true`), e o login de push (`GITHUB_TOKEN`) vem depois, só para o `docker push` | F9 | `publish.yml` builda a base com o `COPY --from` do tars |
| F13 | **(seo-brain)** Acesso ao Forgejo do homelab (host declarado pelo projeto): helper de credencial para esse host pelo `tars secrets` (a ref `op://` é do projeto, nunca deste repo) | F3, homelab | `git clone` do `HuldLabs/seo-expert` no Forgejo de dentro do container, sem senha em argv/URL |
| F14 | **(seo-brain, dono)** Egress/proxy (`EXTERNAL_PROXY_URL`, `ZYTE_API_KEYS`): é **configuração**, não feature — `containerEnv` do projeto + `tars secrets exec`. Só vira feature se precisar de binário (ex.: cliente VPN) | decisão do dono sobre egress | coleta passa pelo proxy sem chave em argv/log |
| F15 | **(seo-brain)** Safari REAL: impossível em container Linux (Apple só publica para macOS). O WebKit do Playwright é o motor, não o Safari; se a coerência UA↔`client` exigir Safari, é runner macOS, fora do Endurance | medição do UA do WebKit pelo seo-brain | decisão registrada no ADR-006 do seo-brain |
| F12 | Depois da primeira tag (`v0.0.1-dev.3`): tirar `ENDURANCE_UNPUBLISHED=1` do `test.yml` | F9 | CI testa os `devcontainer-feature.json` como o consumidor vê |
| F26 | ~~Trocar o `sed` do job `release` pelo `tars release-notes --kind image`~~ — **feito** no PR final da `v0.0.1-dev.3` (Tars dev.24) | dev.24 do Tars | notas da Release sem pós-processamento |

### Feito (14/10, branch `w/seobrain`; origem: pedido do coord seo-brain 14/10)

| # | item | prova |
| --- | --- | --- |
| F27 | `python-uv` 1.2.0 exporta `UV_PROJECT_ENVIRONMENT=<venvPath>`: `containerEnv` (fixo no default `/workspace/.venv`, a spec não interpola option) + profile com o valor da option; o `uv sync` do build também. Fecha o `.venv` do bind recriado pelo `uv` do host | cenário `uvsync`: `uv sync` como `dev` num projeto com `pyproject.toml` usa o venvPath e não cria `.venv` no projeto |
| F28 | `postgres-client` no CI: `test/postgres-client` (default 18, `pg17`) prova `psql`/`pg_dump` no major da option; sem conexão (serviço é do compose do projeto, R4); entra na matriz do `test.yml` | `ENDURANCE_UNPUBLISHED=1 tools/test-features.sh python-uv postgres-client` |
| F29 | README "Pesquisa com browser real" refeito: base por digest, só features do Endurance (`gh` no lugar do `github-cli`), `runArgs` host-gateway, venv em volume nomeado, `compose.yaml` do projeto com `ollama` (GPU NVIDIA) e `serp` (volume nomeado), backup/dump do projeto | — |

### Feito (14/10, branch `w/tarsgate`)

| # | item | prova |
| --- | --- | --- |
| F25 | Rotina do Tars na base: `tools/tars-atual.sh` (última versão de `ghcr.io/huldlabs/tars` pelo registry, digest fixado = digest da tag); `test.yml` avisa, `publish.yml` `--strict` falha; README "Rotina do Tars na base" | `tools/tars-atual.test.sh` (em dia, atrasado, `--strict`, digest divergente, sem digest); actionlint limpo |

### Feito (14/10, branch `w/base2`)

| # | item | prova |
| --- | --- | --- |
| F20 | `rg` 14.1.1 na base (apt trixie `14.1.1-1+b4`, versão exata, marcador `# catalogo:`) | `docker build` ok; `rg --version` na imagem |
| F21 | Locale `pt_BR.UTF-8` + fuso `America/Sao_Paulo` na base (`locales`/`locale-gen`, `LANG` (sem `LC_ALL`), `tzdata`/`TZ`), no catálogo | `locale` todo `pt_BR.UTF-8`; `date +%Z` = `-03` |
| F22 | `gen-catalogo.sh` reprova `ARG *_VERSION`/`*_IMAGE` sem `# catalogo:` imediatamente antes (`ENDURANCE_DOCKERFILE` para teste); `ARG DEBIAN_VERSION` órfão removido | teste negativo com Dockerfile temporário: rc=1 com a linha apontada |
| F23 | Job `release` prova `:<versão>` e `:<major>` de cada feature com o mesmo digest | actionlint limpo |
| F24 | README "Como o projeto sobe a base e as features" (digest/major, bump por PR do projeto, `GHCR_READ_TOKEN` pelo `tars adopt`, Renovate/Dependabot como opção) | — |

### Feito (14/10, branch `w/feat2`)

| # | item | prova |
| --- | --- | --- |
| F19 | Feature `opencode` 1.18.29 (seo-brain), sha256 embutido; L4 provado: a matriz roda todos os cenários de `node-bun` (npm, node20/24/26) e `python-uv` (py312, py315rc2), cada um checando a versão instalada | `ENDURANCE_UNPUBLISHED=1 tools/test-features.sh opencode node-bun python-uv` |
| — | Features `go` e `az` retiradas por falta de pedido real (decisão do coord segtools, 14/10) | — |

### Feito (14/10, branch `w/release`)

| # | item | prova |
| --- | --- | --- |
| F18 | Release completa igual à do Tars: job `release` no `publish.yml` (prova base por digest + features no GHCR, notas por `tars release-notes`, anexos `catalogo.md` + `sha256sums`, pré-release com `-`, por último) e `docs/catalogo.md` gerado por `tools/gen-catalogo.sh` (marcadores `# catalogo:` do Dockerfile + `devcontainer-feature.json`), cobrado no `test.yml`; CHANGELOG dev.3 no formato do `tars release-notes` | `tars release-notes --version 0.0.1-dev.3` local; `gen-catalogo.sh --check`; actionlint limpo |

### Feito (14/10, branch `w/lacunas`)

| # | item | prova |
| --- | --- | --- |
| F17 | Lacunas de `docs/ecossistema.md` (L1–L7): features `gh` 2.102.0, `lint` (shellcheck 0.11.0 + actionlint 1.7.12), `opentofu` 1.13.1 (não terraform: nenhum `.tf` versionado), `duckdb` 1.5.6, `kubectl-helm` (1.37.1 + 4.3.0), `restic-rclone` (0.19.1 + 1.75.2); `node-bun` aceita Node 20/24/26 (libatomic1); `python-uv` aceita 3.12 e `3.15.0rc2` e deixa de apontar o venv para o `/root` | `test/<feature>`; `test/node-bun` cenários `node20/24/26`; `test/python-uv` cenários `py312`/`py315rc2` |

### Feito (14/10, branch `w/f8`)

| # | item | prova |
| --- | --- | --- |
| F8 | `secrets` 2.0.0 e `signing` 2.0.0 finas (D4): só `tars secrets git-credential` (helper do sistema) e `tars identity sign-setup`/`verify` (postStart); `op-sops`, `git-credential-op`, `gh-op`, `secrets-refresh/exec`, `signing-write-key`, `ssh-agent-init`, `signing-git-config` apagados | `test/secrets`, `test/signing` |
| F11 | `tars` 0.0.1-dev.26 na base por digest (D17); login de leitura do GHCR no `test.yml`/`publish.yml` | `docker run --rm endurance-base:local tars --version` → `0.0.1-dev.26` |

### Feito (13/10, branch `w/features`)

| # | item | prova |
| --- | --- | --- |
| F1 | `playwright` com motores reais: `chrome` e `msedge` (sistema) + `firefox`/`webkit` (Playwright) — pedido seo-brain P1 | `test/playwright` cenários `chrome` e `seo-brain` |
| F2 | Helper do git ligado no git do **sistema** por caminho absoluto, vale em qualquer repo | `test/secrets` cenário `global-helper` |
| F4 | `endurance-bg` na base + ADR-0001 | simulação do kill de grupo do harness (ADR-0001 §prova) |
| F6 | Feature `agent-browser` 0.39.1 no Chrome do sistema | `test/agent-browser`: abre página e lê o título |
| F7 | `php` (8.3 + composer 2.10.3 + wp-cli 2.12.0), `mysql-client`, `redis-client`, `pwsh` 7.6.6, `node-bun` `packageManager: npm` | `test/<feature>`; `mysql`/`mysqldump` contra `mysql:8.0.46`, `redis-cli` contra `redis:7` e `valkey:8.1.10` |
| — | Base volta a buildar (`COPY <<` em vez de `RUN <<`), `claude` nativo de fato na base, `major` da tag corrigido no `publish.yml`, CI de teste (`test.yml`) | `docker build images/base`; `tools/test-features.sh` |

## Armadilhas que não podem voltar

- Cookie logado (Ahrefs/Semrush) é credencial: `--session-name`/`--state` do agent-browser nunca em imagem nem volume
  compartilhado; `--profile` do Chrome do dono nunca em container de automação.
- Credential helper que lê o 1Password a cada `get` (corrigido: lê do cache sops — `MAPA.md`).
- Helper resolvido por `$(git rev-parse --show-toplevel)`: só funciona no repo dono (F2).
- Chrome instalado à mão com `sudo` no container: some no rebuild. Vai na imagem/feature (`segtools` `22f4f5e6`).
- Sem o Chrome real o Playwright cai no Chromium e o Google bloqueia (`blocked_by_google`).
- `RUN <<'X' sh` **executa** o heredoc no build; para gravar arquivo é `COPY <<'X' /caminho`. A base não buildava.
- Instalar algo na base que dependa do Node de uma feature: a feature roda **depois** da base, então o passo cai
  calado no ramo "ausente" (foi o `claude` por `npm -g`).
- `installsAfter` com feature do próprio repo não resolve antes da primeira publicação: o teste usa
  `ENDURANCE_UNPUBLISHED=1`.
- `nohup cmd &` não sobrevive ao harness do agente, que mata o grupo com TERM. Só `setsid`/`endurance-bg`.
- Cliente MariaDB contra MySQL 8 do compose: recusa o TLS autoassinado. A chave `RPM-GPG-KEY-mysql-2023` da Oracle
  vem vencida; a renovada é a `-2025`, conferida por impressão digital.
- Browsers baixados no BUILD em `/workspace/.cache` somem sob o bind mount do projeto em `/workspace`: a feature garante
  as libs de sistema (root); `firefox`/`webkit`/`chromium` o usuário baixa com `npx playwright install` (sem sudo).
  Chrome/Edge vão para `/opt` e não somem.
- `hashes.sha256` do PowerShell é UTF-16 com CRLF: converter antes do `sha256sum -c`.
- `tars secrets git-credential` sem `git_hosts`/`git_credential` no `[secrets]` do projeto não entrega nada (dev.19):
  o helper do sistema está ligado, mas o projeto tem de declarar os hosts.

## Segurança (importante, para depois — dono, 14/10)

- Acesso do bot às máquinas do homelab: frente homelab, tratado na seção Segurança do BACKLOG do huldlabs (coord
  segtools, 14/10).
- Os 11 itens de segurança multiusuário (D10) entram antes de qualquer máquina compartilhada ou runner consumir o
  Endurance.

## Em aberto (decisão do dono)

- **Egress do seo-brain (F14):** proxy próprio, Zyte ou nada.
