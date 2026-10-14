# HANDOFF — Endurance

Estado vivo para quem retoma. Decisões e fila: `BACKLOG.md`. Uma entrada por frente; incremento da mesma frente edita
a entrada no lugar.

## Bootstrap do método — 13/10/2026 (coord Endurance)

**Onde estamos:** `main` em `f0e260e`, sem tag, nenhum consumidor. Branch `w/bootstrap` acrescenta `AGENTS.md`,
`BACKLOG.md`, `HANDOFF.md` e o consumo do Tars (`.ai/tars.toml`, `.ai/tars.lock`, `.githooks/`, `.claude/`).

**Próximo:** F1 do `BACKLOG.md` (option `browser: chrome` na `playwright`), depois F2 (helper git global).

**Limites conhecidos:**
- `tars identity` não existe no Tars `0.0.1-dev.17`: a tag `v0.1.0` (D3) e o F8 ficam presos.
- O `tars sync` só gera `.githooks/` se a pasta já existir; `core.hooksPath=.githooks` precisa estar no config local.

**Como operar:** worker por worktree em `.worktrees/<slot>`, `tars sync` antes do 1º commit.
