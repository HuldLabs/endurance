# CHANGELOG — Endurance

Formato: o que mudou · por quê · arquivos impactados · o que o consumidor faz (doutrina `versionamento-de-extracao`).

## 0.0.1-dev.2 — 13/10/2026

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

## 0.0.1-dev.1 — 13/10/2026

- **O que mudou:** o repo passa a consumir o Tars (`.ai/`, `.githooks/`, `.claude/`) e ganha `AGENTS.md`,
  `BACKLOG.md`, `HANDOFF.md` e este CHANGELOG. Base e features de `f0e260e` entram como estão.
- **Por quê:** doutrina `novo-repo`; as decisões de 08/10 e a fila do seo-brain só viviam em conversa.
- **Arquivos impactados:** `AGENTS.md`, `BACKLOG.md`, `HANDOFF.md`, `CHANGELOG.md`, `.ai/`, `.githooks/`, `.claude/`,
  `.gitignore`.
- **O que o consumidor faz:** nada. Ainda não há tag nem consumidor.
