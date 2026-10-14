# HANDOFF — Endurance

Estado vivo para quem retoma. Decisões e fila: `BACKLOG.md`. Uma entrada por frente; incremento da mesma frente edita
a entrada no lugar.

## Endurance — 14/10/2026 (coord Endurance)

**Onde estamos:** `main` com os PRs #1–#5 mergeados. Nove features testadas e o CI de teste em todo PR. A branch
`w/versao` alinha a numeração: a primeira tag é a `v0.0.1-dev.3`, e quem cria a tag é o dono.

**Proximo passo:** quando a dev.19 do Tars sair (imagem no GHCR, `tars secrets git-credential` e
`tars identity sign-setup`), pôr o `tars` na base (D17) e enxugar `secrets`/`signing` (F8). Depois, mapear o
ecossistema inteiro (D18), e aí o dono cria a tag.

**Limites conhecidos:**
- A primeira tag é a `v0.0.1-dev.3` e só sai com o ecossistema mapeado (D18). O F8 espera a dev.19 do Tars.
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
