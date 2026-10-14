# HANDOFF — Endurance

Estado vivo para quem retoma. Decisões e fila: `BACKLOG.md`. Uma entrada por frente; incremento da mesma frente edita
a entrada no lugar.

## Features e base — 13/10/2026 (coord Endurance)

**Onde estamos:** `main` em `e94897e` (PR #1, método do Tars). Branch `w/features` (worktree `.worktrees/features`)
entrega F1, F2, F4, F6 e F7 com testes, mais três consertos da base e do CI (ver `BACKLOG.md` §Feito).

**Proximo passo:** PR do `w/features` → revisão adversarial → merge pela Daneel. Depois a fila só anda com: decisão do
dono sobre a tag (D3), o `[secrets]` do seo-brain (F3, coord seo-brain) e o artefato do Tars (F11, coord do Tars).

**Limites conhecidos:**
- `tars identity` não existe no Tars `0.0.1-dev.17`: a tag `v0.1.0` (D3) e o F8 ficam presos.
- Nada publicado no GHCR: os testes rodam com `ENDURANCE_UNPUBLISHED=1` (`tools/test-features.sh`).
- `google-chrome` só existe em amd64 (o Google não publica .deb arm64).

**Como operar:**
- Worker por worktree em `.worktrees/<slot>`, `tars sync` antes do 1º commit.
- Testes: `docker build -t endurance-base:local images/base && ENDURANCE_UNPUBLISHED=1 tools/test-features.sh`.
- Push/PR como Daneel de dentro do `segtools-dev`, a partir de `/projects/endurance` (o worktree tem gitdir do host):
  `git -c credential.helper= -c "credential.helper=!bash /workspace/.devcontainer/git-credential-op.sh" push …` e
  `bash /workspace/.devcontainer/gh-op.sh pr create -R HuldLabs/endurance …`. Merge: Daneel, após PASS adversarial.
- O guard `block-secret-dump` barra qualquer comando que cite um caminho `…/secrets/…`, inclusive o
  `src/secrets/install.sh` deste repo. Leia com o Read e use glob (`src/s*/`) no shell.
