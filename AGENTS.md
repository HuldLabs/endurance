# AGENTS.md — Endurance

Método vem do Tars (`.ai/tars.toml`, base em `.ai/base/`); aqui só o que é do Endurance.
Decisões e fila: `BACKLOG.md`. Estado vivo: `HANDOFF.md`. Origem de cada peça: `MAPA.md`.

- **R1 — já existe? porte.** Leia a spec oficial (containers.dev/implementors/features) e o arquivo de origem
  (devcontainer do segtools) antes de escrever. Cite caminho e commit.
- **R2 — KISS.** Uma feature = um `install.sh` idempotente. Sem abstração antecipada. Apagar é entrega.
- **R3 — fonte única.** Versão vive no `devcontainer-feature.json` (option com default) ou no `Dockerfile` da base;
  o projeto consumidor declara a dele. Nada hardcoded fora disso.
- **R4 — nada exige runtime de quem não usa.** Runtime é feature, nunca base. Serviço (Postgres, MySQL, RabbitMQ,
  MinIO, ollama, Caddy…) é do compose do projeto, nunca da imagem.
- **R5 — features `secrets`/`signing` são finas.** Instalam o `tars` e chamam `tars secrets …`/`tars identity …`;
  lógica própria de segredo aqui é defeito.
- **Fronteira dura:** nenhum segredo, host, dado de cliente ou ref `op://` de projeto entra neste repo nem na imagem.
- Segredos: nunca imprimir (nem hash nem tamanho); credencial nunca em argv, URI ou log; nunca ler `.env`, `*.sops`,
  `~/.ssh`.
- Git: commit como Daneel, com emoji; nunca `--no-verify`, nunca `git add -A` (pathspec explícito); um worktree por
  worker em `.worktrees/<slot>` (`tars sync` antes do 1º commit).
- Publicar = criar tag `v*`, e só com ordem direta do dono.
- Achado de outra frente vai para o coord dela (Tars/homelab/telemetria: coord segtools; seo-brain: coord do
  seo-brain). Credencial exposta: seção Segurança do `BACKLOG.md` do `huldlabs`.
