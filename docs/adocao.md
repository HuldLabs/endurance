# Adotar e atualizar o Endurance

Guia prático do consumidor: preparar a **máquina**, ligar um projeto **novo**, migrar um projeto **que já existe** e
**atualizar** quando sai candidato (rc) ou versão nova. O que mudou em cada versão está no
[`CHANGELOG.md`](../CHANGELOG.md); o desenho de cada feature, no [`README.md`](../README.md).

Regra do dono (D22): **cada repo tem o seu próprio devcontainer, todos sobre o Endurance**. Nenhum projeto roda no
container de outro.

## 1. Preparar a máquina (uma vez)

| Peça | Mínimo | Por quê |
| --- | --- | --- |
| Docker Engine | 29 | é o que está provado |
| devcontainer CLI | **0.89.0** (use `@devcontainers/cli@0.90.0`) | o 0.80.1 trava no primeiro `up` com Docker 29: espera o campo `status` do `docker events`, que não vem mais |
| Arquitetura | amd64 | a base publicada ainda é só amd64 (E10); o Chrome real só existe em amd64 |

As imagens e features do Endurance no GHCR são **públicas**: o `devcontainer up` puxa sem login.

Nada do 1Password do dono entra no container. O container usa **só** o token da service account que o dono semeia uma
vez por projeto (seção 2, passo 5).

## 2. Projeto novo

1. **`.devcontainer/devcontainer.json`** sobre a base fixada **por digest** e as features que o projeto usa. Modelo
   (o do Kerr, que roda em produção de desenvolvimento):

   ```jsonc
   {
     "name": "meu-projeto",
     "image": "ghcr.io/huldlabs/endurance/base:0.0.1-dev.6@sha256:d4790d09906b609583829f3e768d5ee7d5a40fb6ed31e04de1ffe4ce59926fdb",
     "remoteUser": "dev",
     "workspaceFolder": "/workspace",
     "workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind",
     "features": {
       "ghcr.io/huldlabs/endurance/secrets:2": {},
       "ghcr.io/huldlabs/endurance/signing:2": { "userName": "Daneel", "userEmail": "daneel-bot@pabloaugusto.com" },
       "ghcr.io/huldlabs/endurance/gh:1": {}
       // + os runtimes do projeto: rust:1, python-uv:1, node-bun:1, playwright:1, sqlite-client:1, diag:1 …
     }
   }
   ```

   - **Versões ficam no projeto:** `rust-toolchain.toml`, `.python-version`, lockfiles. Na `playwright`, passe
     `"version"` igual à do Playwright do lock (o default é 1.63.0, e outro build procura outro browser).
   - **Serviço** (Postgres, Ollama, toxiproxy…) vai no `compose` do projeto, nunca na imagem (R4).
   - **Não monte** volume próprio em `/home/dev/.config/tars/<repo>`: a feature `secrets` já guarda
     `~/.config/tars` inteiro; uma pasta que não existe na imagem nasce `root` e quebra o `age-keygen`.
   - Socket do Docker só se o projeto precisa, por mount explícito e documentado (D10).

2. **`.ai/tars.toml`** do projeto (Tars **≥ dev.30**; a base já traz o binário):

   ```toml
   [secrets]
   source = "automation"
   key_scope = "machine"
   template = "config/secrets.tpl"     # refs op:// do PROJETO, por ID do item
   git_credential = "GITHUB_PAT_DANEEL" # NOME da chave no cache, nunca o valor
   git_hosts = "github.com"

   [identity]
   actor = "daneel"
   key_file = "/home/dev/.ssh/id_daneel"
   key_cache = "DANEEL_SIGNING_KEY"     # chave de assinatura vinda do cache
   git_name = "Daneel"
   git_email = "daneel-bot@pabloaugusto.com"
   ```

   Depois, `tars sync --upgrade` e as `tars upgrade-notes` até a versão da base.

3. **Subir:** `npx -y @devcontainers/cli@0.90.0 up --workspace-folder .`, **uma vez**. Sem o token ainda, o container
   sobe com `[secrets] AVISO` e `[signing] AVISO`: é o esperado.

4. **O que já roda sozinho a cada start (nada a fazer):**
   - `secrets`: `tars secrets refresh` renova o cache cifrado e liga o `credential.helper` do git do sistema;
   - `signing`: `tars identity sign-setup --from-cache --global` instala a chave em `key_file`, configura nome, e-mail
     e assinatura, e `tars identity verify` confere;
   - `rust`: `rustup toolchain install` pelo `rust-toolchain.toml`.

5. **O único passo manual — do DONO, uma vez por projeto:** semear o token da service account. Dentro do container
   (o comando pede o token com a digitação oculta):

   ```bash
   tars secrets token set
   ```

   O token é o **aval** do dono para aquele projeto: o agente nunca se autoriza nem copia o token de outro projeto. Ele
   mora no volume do projeto e sobrevive a toda recriação do container; só se refaz se o volume for apagado ou o
   token trocado.

6. **Parar e subir de novo** (o postStart só roda em start; um `up` com o container de pé não o repete):

   ```bash
   docker stop <container> && npx -y @devcontainers/cli@0.90.0 up --workspace-folder .
   ```

7. **Conferir:**

   ```bash
   tars secrets check                      # cache, token e chave, sem abrir valor
   tars identity verify
   git commit --allow-empty -m "🔧 chore: teste de assinatura" && git log --show-signature -1   # G / Good
   ```

## 3. Projeto que já existe

O caso típico: o projeto rodava no container de outro (o `segtools-dev`) ou tinha remendos no próprio post-start.

1. Faça as seções 2.1 e 2.2 no repo do projeto.
2. **Tire os remendos** que o Endurance já cobre. Cada um tem a sua troca:

   | Remendo antigo | O que substitui |
   | --- | --- |
   | `chown` de `~/.config` ou `~/.ssh` no post-start | a base cria as pastas com dono `dev` |
   | `git config` / `credential.helper` / `sign-setup` à mão no post-start | features `secrets` e `signing` |
   | `rustup` instalado à mão | feature `rust` + `rust-toolchain.toml` |
   | `.deb` de `libgomp` em `/tmp` + `LD_LIBRARY_PATH` | feature `python-uv` (traz a `libgomp1`) |
   | Chrome no Dockerfile do projeto | feature `playwright` com `"browser": "chrome"` ou `"chromium,chrome"` |
   | `PLAYWRIGHT_BROWSERS_PATH` no `.cache/` do workspace | a feature define `/opt/ms-playwright` (o bind escondia o cache) |
   | `op read` em script | `tars secrets exec -- <cmd>` |
   | `devcontainer up` duas vezes (`timeout 60 up` + `up`) | CLI ≥ 0.89, um `up` só |
   | volume próprio em `~/.config/tars/<repo>` | tire; e, se o container já subiu com ele, rode uma vez `sudo chown -R dev:dev ~/.config/tars` |

3. **Estado que já existia:** o diretório do `tars secrets` tem o nome do **repo** desde o Tars dev.30
   (`~/.config/tars/<repo>`); um diretório antigo com o nome da pasta (`~/.config/tars/workspace`) continua sendo
   achado. Se o token já foi semeado num volume que você mantém, não precisa semear de novo.
4. Siga 2.3 a 2.7.

## 4. Atualizar

Entre cortes, o Endurance só circula como **candidato local** (D21): `0.0.1-dev.N-rc.M`, com a imagem
`endurance/base:dev.N-rc.M-local` e as features em `~/projects/endurance-rc/devN-rcM/` (commit e sha256 no aviso). A
cada ajuste o coord do Endurance avisa todos os consumidores; **cada um decide quando recriar** o próprio container.

**Testar um rc sem mexer no devcontainer real:** num config descartável em `.cache/endurance-rc/` do projeto, com
volumes novos, a imagem local do rc e as features por caminho — a feature local tem de estar **dentro** da pasta
`.devcontainer` e é referenciada por `"./<feature>"`.

**Versão publicada (só com ordem do dono):** troque a base pelo digest novo das notas da Release, ajuste as majors das
features se mudaram, leia a seção "O que o consumidor faz" da versão no `CHANGELOG.md`, recrie o container e repita a
conferência da seção 2.7.

## 5. Como relatar um bug do Endurance

Mande ao coord do Endurance: projeto, data, rc ou versão (com o digest), o comando exato, a saída **sem segredo**, o
exit code, o esperado e o obtido. Bug do Tars (gate, guard, `tars secrets`/`identity`) vai ao coord do Tars.

## 6. Quando algo dá errado

| Sintoma | Causa provável | O que fazer |
| --- | --- | --- |
| `devcontainer up` trava no primeiro start; o segundo conclui | CLI 0.80.1 com Docker 29 | CLI ≥ 0.89 |
| `[secrets] AVISO token ... ausente` | token não semeado | seção 2.5, depois stop + up |
| `age-keygen: permission denied` em `~/.config/tars/<repo>` | pasta `root` de um volume montado por cima | tire o mount; `sudo chown -R dev:dev ~/.config/tars` |
| `[signing] AVISO: identidade nao verificada` | sem token, sem `[identity]` ou Tars < dev.30 | seções 2.2 e 2.5 |
| `either user.signingkey or gpg.ssh.defaultKeyCommand needs to be configured` | `sign-setup` ainda não rodou | token + stop + up |
| `Executable doesn't exist at /opt/ms-playwright/...` | `version` da feature diferente da do lock do projeto | passe a mesma `"version"` na feature `playwright` |
| `ls $PLAYWRIGHT_BROWSERS_PATH`: pasta vazia | `PLAYWRIGHT_BROWSERS_PATH` do projeto aponta para o `.cache/` do workspace | tire a variável do projeto |
| `perf` não mede | `perf_event_paranoid` do host | é do host, não do container |
