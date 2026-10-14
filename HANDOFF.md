# HANDOFF — Endurance

Estado vivo para quem retoma. Decisões e fila: `BACKLOG.md`. Uma entrada por frente; incremento da mesma frente edita
a entrada no lugar.

## Endurance — 14/10/2026 (coord Endurance)

**Onde estamos:** `main` com os PRs #1–#7 mergeados. A base traz o `tars` dev.21 por digest, `secrets`/`signing`
2.0.0 são finas e a feature `tars` saiu (F8, D19). O `.ai` está no lock da dev.21 (o sync não apaga mais a `lib-json.sh`).
PRs #8 (F16) e #9 (revisão adversarial) mergeados.

**Proximo passo:** features das lacunas de `docs/ecossistema.md` (branch `w/lacunas`). Depois, mapear o ecossistema inteiro (D18), e aí o dono cria a tag.

**Limites conhecidos:**
- A primeira tag é a `v0.0.1-dev.3` e só sai com o ecossistema mapeado (D18).
- O pacote `ghcr.io/huldlabs/tars` é privado: build da base exige `docker login ghcr.io` com leitura
  (CI: `vars.GHCR_READ_USER` + `secrets.GHCR_READ_TOKEN`).
- Projeto que liga `secrets` declara `git_hosts` e `git_credential` no `[secrets]` do `.ai/tars.toml`.
- Nada publicado no GHCR: os testes rodam com `ENDURANCE_UNPUBLISHED=1` (`tools/test-features.sh`).
- `google-chrome` só existe em amd64 (o Google não publica .deb arm64).

**Como operar:**
- Worker por worktree em `.worktrees/<slot>`, `tars sync` antes do 1º commit.
- Testes: `docker build -t endurance-base:local images/base && ENDURANCE_UNPUBLISHED=1 tools/test-features.sh`
  (o build precisa do login de leitura no GHCR).
- Push/PR como Daneel de dentro do `segtools-dev`, a partir de `/projects/endurance` (o worktree tem gitdir do host):
  `git -c credential.helper= -c "credential.helper=!bash /workspace/.devcontainer/git-credential-op.sh" push …` e
  `bash /workspace/.devcontainer/gh-op.sh pr create -R HuldLabs/endurance …`. Merge: Daneel, após PASS adversarial.
- O guard `block-secret-dump` barra qualquer comando que cite um caminho `…/secrets/…`, inclusive o
  `src/secrets/install.sh` deste repo. Leia com o Read e use glob (`src/s*/`) no shell.
