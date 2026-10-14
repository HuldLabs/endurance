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
| D11 | Chrome real entra como option `browser: chrome` da `playwright` (sem feature `chrome` separada) | dono, 13/10 |
| D12 | `agent-browser` vira feature própria: npm global pinado, usa o Chrome do sistema (nunca `agent-browser install`), sessão/cookies em volume por usuário e projeto | dono, 13/10 |
| D13 | Até a primeira tag: `0.0.1-dev.N` + `CHANGELOG.md` (doutrina `novo-repo`) | dono, 13/10 |
| D10 | Segurança multiusuário: os 11 itens (sem segredo na imagem, volumes por usuário/projeto, socket Docker off por padrão, sem agente SSH do dono em automação, menor escopo, digest fixo e assinado, portas em `127.0.0.1`…) | idem §Multi-user security |

## Fila

| # | item | depende de | aceite |
| --- | --- | --- | --- |
| F1 | Chrome real: option `browser: chrome` na feature `playwright` (instala `google-chrome-stable`), portando o remendo do segtools `22f4f5e6`; depois tirar o remendo do Dockerfile do segtools | — | `devcontainer features test` da `playwright` com `browser=chrome` passa e `google-chrome --version` responde; `channel="chrome"` abre no Playwright |
| F2 | Helper de credencial do git **global** na `secrets` (caminho fixo, não `$(git rev-parse --show-toplevel)`), via `tars secrets exec` | D4 | `git push` num repo que não é o segtools (ex.: `huldlabs`) não pede login dentro do container |
| F3 | Segredos injetáveis por ref `op://` (`SERP_DSN`, `DEEPSEEK_API_KEY` do seo-brain) pela `secrets` + `tars secrets exec` | D4, F2 | o seo-brain roda o coletor com `tars secrets exec -- …` sem colar valor à mão; nada em argv/log |
| F4 | Mecanismo canônico de tarefa longa (o container mata background; hoje `setsid` no host) | — | ADR escolhendo o mecanismo, provado com processo que sobrevive ao fim da sessão do agente |
| F5 | Devcontainer próprio do seo-brain consumindo as features | F1, F3, tag | o seo-brain sobe com `devcontainer up` sem o do segtools |
| F6 | Feature `agent-browser` ([vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser), npm; hoje o seo-brain usa o binário **do Windows** 0.26.0 via `/mnt/c`, o npm está em 0.39.1) | F1, D12 | dentro do container `agent-browser open <url>` + `get text body` usa o `google-chrome` da F1; sessão em volume do projeto, nunca na imagem |
| F7 | Features que faltam: `php` (php-cli, composer, wp-cli), `mysql-client`, `redis-client`, `pwsh`, pnpm/npm por corepack no `node-bun` | — | um `test/<feature>` por item passando no `devcontainer features test` |
| F8 | `secrets`/`signing` finas (D4) e options da `tars` (D5) | `tars identity` no Tars | `install.sh` das duas sem lógica de segredo própria |
| F9 | Tag `v0.1.0` | F8, ordem do dono | publicação no GHCR pela tag, imagem referenciada por digest |
| F10 | Migrar o segtools (D7) | F9 | segtools sobe pelas features; remendos do Dockerfile dele removidos |

## Armadilhas que não podem voltar

- Cookie logado (Ahrefs/Semrush) é credencial: `--session-name`/`--state` do agent-browser nunca em imagem nem volume compartilhado; `--profile` do Chrome do dono nunca em container de automação.

- Credential helper que lê o 1Password a cada `get` (corrigido: lê do cache sops — `MAPA.md`).
- Helper resolvido por `$(git rev-parse --show-toplevel)`: só funciona no repo dono (F2).
- Chrome instalado à mão com `sudo` no container: some no rebuild. Vai na imagem/feature (`segtools` `22f4f5e6`).
- Sem o Chrome real o Playwright cai no Chromium e o Google bloqueia (`blocked_by_google`).

## Em aberto (decisão do dono)

- **D3 × Tars:** o Tars `0.0.1-dev.17` (PR HuldLabs/tars#11) **não tem** `tars identity` (`tars identity` → "comando
  desconhecido", verificado em 13/10). Recomendo: manter a tag presa ao `identity`, e adiantar F1–F4/F7, que não
  dependem dele.
