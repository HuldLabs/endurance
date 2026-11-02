# HANDOFF — Endurance

Estado vivo para quem retoma. Decisões e fila: `BACKLOG.md`. Uma entrada por frente; incremento da mesma frente edita
a entrada no lugar.

## Endurance — 02/11/2026 (coord Endurance)

**Onde estamos:** `main` depois do PR #43. Publicada: dev.6 (base `sha256:d4790d09…`, tars dev.30, Release no formato do
Tars). Em maturação: dev.7, só como rc local; o vigente é o **dev.7-rc.4** (commit `5b3915d`, imagem
`endurance/base:dev.7-rc.4-local`, ID `sha256:293f4d0a…`, features em `~/projects/endurance-rc/dev7-rc4/`, tar
`8f7984ec…`). O rc.3 fica até todos trocarem. Depois do rc.4 só mudaram docs.

**Validação por consumidor:**
- seo-brain: passou no rc.4 com token real e commit assinado; falta commitar o devcontainer dele (gate OpenAPI, dívida
  dele).
- homelab: rc.3 (PR HuldLabs/homelab#37), segredos e assinatura ok.
- Kerr: validou o rc.1 em descartável e achou os 2 bugs do playwright; rc.4 e `diag` sem teste dele. `.devcontainer/`
  real na dev.6.

**Próximo passo:**
- H1 virou receita em `docs/adocao.md`, seção "Receita: SSH da Daneel". Com a dev.31 publicada, trocar o `exec` da
  receita por `tars secrets exec --only HOMELAB_SSH_KEY` (TARS-BUG-28, HuldLabs/tars#71).
- **Aberto, segurança:** o `converge` dentro do `exec` imprimiu base64 de chave OpenSSH no homelab. Falta o Homelab dizer
  onde a saída ficou gravada, se a chave saiu inteira e quem a imprime. Se foi para log ou transcript, a chave conta como
  exposta; a rotação é decisão do dono.
- E8 (gate stack × feature) está no BACKLOG do Tars, aguardando ordem do dono.
- Próximo rc: o `[signing] AVISO` citar a linha do `verify` que falhou.
- Tars dev.31 traz `block-host-commit` amplo, commit-msg sem crash e `verify` com `known_hosts`.
- Corte da dev.7 só com ordem do dono: seção no CHANGELOG, `VERSION`, base da árvore da tag, notas por
  `tars release-notes`.

**Limites conhecidos:**
- CI proibido pelo dono; corte à mão (README, "Release").
- Git do agente só no container `segtools-dev` (usuário node, `bash -l`, `/projects/endurance`), inclusive leitura. O
  docker de lá não tem BuildKit: a base se constrói no host.
- Token dos devcontainers: o da máquina (D23), com 11 cofres medidos; somente-leitura não medido.
- Base só amd64. Guia do consumidor: `docs/adocao.md`.
- O guard `block-secret-dump` barra comando com texto citando token ou `src/secrets/`; use Read/Edit/Write.
