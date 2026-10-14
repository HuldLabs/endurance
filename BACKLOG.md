# BACKLOG — Endurance

## Decisões em vigor

| # | decisão | fonte |
| --- | --- | --- |
| D1 | Base enxuta (`images/base`) + um runtime por Dev Container Feature em `ghcr.io/huldlabs/endurance/<feature>`; nada exige runtime de quem não usa | `README.md` |
| D2 | Só tag `v*` publica; versão sai da tag | `6ae08cf` |
| D3 | Tag `v0.1.0` espera `tars identity` no Tars | `docs/decisoes-20261008.md` §Sequence 1 |
| D4 | `secrets` e `signing` finas: instalam o `tars` e chamam `tars secrets refresh/exec` e `tars identity provision` | idem §Sequence 2 |
| D5 | Feature `tars` central, options `version` (digest), `autoSync` (default true), `actor`, `profileMount` | idem §Sequence 3 |
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
| D16 | Feature `tars` = shim que roda o checkout montado em `TARS_HOME`, só como **ponte** até a D17 | `gh release list -R HuldLabs/tars` vazio (13/10) |
| D18 | A tag `v0.1.0` só sai depois que **todo o ecossistema** estiver mapeado e ajustado no Endurance, para evitar tags desnecessárias (substitui o gatilho da D3) | dono, 14/10 |
| D17 | O `tars` é peça **da base** (todo projeto usa). É o binário compilado (`bun build --compile`), copiado de uma imagem do Tars por digest: `COPY --from=ghcr.io/huldlabs/tars:<v>@sha256:… /tars /usr/local/bin/tars`. Sem Node e sem credencial no build | dono, 14/10 |

## Fila

| # | item | depende de | aceite |
| --- | --- | --- | --- |
| F3 | Segredos do seo-brain (`SERP_DSN`, `DEEPSEEK_API_KEY`) por ref `op://`: o **seo-brain** declara o template e o `[secrets] source=automation` no `.ai/tars.toml` e roda `tars secrets exec -- …`. Do lado do Endurance basta a feature `tars` + o volume do token | coord seo-brain; desenho do `[secrets]` com o coord do Tars | o coletor roda por `tars secrets exec` sem colar valor à mão; nada em argv/log |
| F5 | Devcontainer próprio do seo-brain consumindo as features (exemplo no `README.md`) | F9, F3 | o seo-brain sobe com `devcontainer up` sem o do segtools |
| F8 | `secrets`/`signing` finas (D4) e options da `tars` (D5) | `tars identity` + artefato versionado do Tars (F11) | `install.sh` das duas sem lógica de segredo própria |
| F9 | Tag `v0.1.0` | F8, ordem do dono | publicação no GHCR pela tag, imagem referenciada por digest |
| F10 | Migrar o segtools (D7), tirando o remendo do Chrome do Dockerfile dele (`22f4f5e6`) | F9 | segtools sobe pelas features; remendos do Dockerfile dele removidos |
| F11 | **(frente Tars, pedido em 14/10)** O CI do Tars publica `ghcr.io/huldlabs/tars:<versão>` (multi-arch, `FROM scratch` com `/tars`) e dá leitura ao repo endurance; depois o Endurance põe o `COPY --from` na base (D17) e a feature `tars` fica só com options de comportamento | coord do Tars | `docker run --rm endurance-base tars --version` sem montar nada |
| F13 | **(seo-brain)** Acesso ao Forgejo do NUC (`nuc.czul.net:3300`): helper de credencial para esse host pelo `tars secrets` (a ref `op://` é do projeto, nunca deste repo) | F3, homelab | `git clone` do `HuldLabs/seo-expert` no Forgejo de dentro do container, sem senha em argv/URL |
| F14 | **(seo-brain, dono)** Egress/proxy (`EXTERNAL_PROXY_URL`, `ZYTE_API_KEYS`): é **configuração**, não feature — `containerEnv` do projeto + `tars secrets exec`. Só vira feature se precisar de binário (ex.: cliente VPN) | decisão do dono sobre egress | coleta passa pelo proxy sem chave em argv/log |
| F15 | **(seo-brain)** Safari REAL: impossível em container Linux (Apple só publica para macOS). O WebKit do Playwright é o motor, não o Safari; se a coerência UA↔`client` exigir Safari, é runner macOS, fora do Endurance | medição do UA do WebKit pelo seo-brain | decisão registrada no ADR-006 do seo-brain |
| F12 | Depois da `v0.1.0`: tirar `ENDURANCE_UNPUBLISHED=1` do `test.yml` | F9 | CI testa os `devcontainer-feature.json` como o consumidor vê |

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

## Segurança (importante, para depois — dono, 14/10)

- **Daneel com sudo NOPASSWD total no NUC, no hermes e no pve** (`docs/decisoes-20261008.md` §SSH). O pve vira a base
  de produção, então a chave do bot fica equivalente a root em produção. Proposta: sudo total só no NUC (dev) e lista
  de comandos no pve e em produção. É frente homelab: repassado ao coord segtools em 14/10 para a seção Segurança do
  BACKLOG do huldlabs.
- Os 11 itens de segurança multiusuário (D10) entram antes de qualquer máquina compartilhada ou runner consumir o
  Endurance.

## Em aberto (decisão do dono)

- **Egress do seo-brain (F14):** proxy próprio, Zyte ou nada.
