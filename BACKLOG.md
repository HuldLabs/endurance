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
| D16 | Feature `tars` = shim que roda o checkout montado em `TARS_HOME` até o Tars publicar artefato versionado | `gh release list -R HuldLabs/tars` vazio (13/10) |

## Fila

| # | item | depende de | aceite |
| --- | --- | --- | --- |
| F3 | Segredos do seo-brain (`SERP_DSN`, `DEEPSEEK_API_KEY`) por ref `op://`: o **seo-brain** declara o template e o `[secrets] source=automation` no `.ai/tars.toml` e roda `tars secrets exec -- …`. Do lado do Endurance basta a feature `tars` + o volume do token | coord seo-brain; desenho do `[secrets]` com o coord do Tars | o coletor roda por `tars secrets exec` sem colar valor à mão; nada em argv/log |
| F5 | Devcontainer próprio do seo-brain consumindo as features (exemplo no `README.md`) | F9, F3 | o seo-brain sobe com `devcontainer up` sem o do segtools |
| F8 | `secrets`/`signing` finas (D4) e options da `tars` (D5) | `tars identity` + artefato versionado do Tars (F11) | `install.sh` das duas sem lógica de segredo própria |
| F9 | Tag `v0.1.0` | F8, ordem do dono | publicação no GHCR pela tag, imagem referenciada por digest |
| F10 | Migrar o segtools (D7), tirando o remendo do Chrome do Dockerfile dele (`22f4f5e6`) | F9 | segtools sobe pelas features; remendos do Dockerfile dele removidos |
| F11 | **(frente Tars)** Tars publicar artefato versionado (release/OCI) para a feature fixar por digest (D5) | coord do Tars | `tars` instalado por versão/digest, sem checkout montado |
[removido: dado do homelab, 14/10]
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

## Em aberto (decisão do dono)

- **D3 × Tars:** o Tars `0.0.1-dev.17` **não tem** `tars identity` (verificado em 13/10). Recomendo manter a tag presa
  ao `identity`.
- **Tag antes do Tars?** O seo-brain (F5) e o segtools (F10) só consomem depois de uma tag. Se o `identity` demorar,
  uma `v0.1.0` com `secrets`/`signing` como estão destrava o consumo; o enxugamento (F8) viraria `v0.2.0`.
  Recomendação: segurar até o dono decidir, porque a D3 é dele.
