<!-- tars:boot (gerado pelo tars sync; nao edite) -->
# Princípios de boot

Regra de boot de **todo** projeto que consome o Tars: o catálogo a leva ao consumidor
(`tars sync`) e o adaptador a põe no topo do arquivo de boot gerado. Vale para qualquer
sessão de agente, em qualquer projeto.

## Regra zero: todo problema passa pela skill `root-cause-debugging`

Todo problema, bug, bloqueio, erro, falha de teste ou condição inesperada é tratado
**pela skill `root-cause-debugging`**, antes de qualquer outra ação: reproduzir, medir,
levantar hipótese, testar a hipótese e só então corrigir ou pedir algo a alguém.

- **Nunca chutar:** sem afirmar causa, estado ou "como era antes" sem conferir.
  Hipótese não testada se apresenta como hipótese.
- **Conferir antes de pedir:** antes de pedir ao dono uma ação, uma credencial ou uma
  decisão, verifique o que você mesmo pode verificar (só leitura, sem efeito colateral).
- **Falha silenciosa é falha:** saída vazia, `cat` que não leu ou comando que "não fez
  nada" vira uma investigação, não uma suposição.
- **Regressão (funcionava, parou): a primeira pergunta é "o que mudou?".** Ache o
  caminho que funcionava, documentado no repo (docs, devcontainer, Taskfile, ADR,
  docstrings e comentários do código, scripts, CHANGELOG, histórico do git, transcripts
  de sessão, o sistema de memória, o handoff e o backlog, onde às vezes o conserto já
  está registrado como pendente), e
  **restaure-o**. Nunca invente um caminho paralelo para contornar a regressão.
- **A skill é lida e seguida, não citada:** abra o arquivo da skill e execute os passos.
  Dizer que usou sem ter lido é o mesmo erro que chutar.
- **Erro repetido é classe, não deslize:** na segunda vez que a mesma falha aparece,
  pare e crie a prevenção (guard, check ou memória com o padrão e a regra) **antes** de
  seguir. Corrigir de novo no lugar, sem prevenção, garante a terceira.
- **Quando o dono aponta um erro:** pare a linha atual, entenda o apontamento, pondere
  as opções e volte ao processo. Se o apontamento for ambíguo, pergunte antes de agir.
  Nunca insista na mesma abordagem que acabou de ser apontada.

Porquê (incidente de 08/10/2026): o agente afirmou de memória como o push funcionava antes
do crash e errou; acionou a biometria do dono antes de verificar os caminhos que não a
exigiam; e pediu ao dono ações que ele mesmo podia testar.

## Quando perguntar e quando decidir (matriz única)

Decisão do dono (14/10/2026). Substitui as versões conflitantes — "não agir em conversa sem
ordem" (`docs/WORKING-AGREEMENT.md` do segtools), "pergunta não segura trabalho" e "só 4
casos de pergunta" (mapas da curadoria 13/10, `seg-agentmem-1` #37/#38) e "perder por alvo"
(`.ai/governance/perdas-por-alvo.md`). A régua é **uma**:

| Situação | O que fazer |
|---|---|
| **Desconhecido** (não dá para medir o efeito sem executar) | **Pergunta** antes de agir |
| **Irreversível** (apagar dado/infra de terceiro, push em produção, mudança sem rollback) | **Pergunta** antes de agir |
| **Produção** (recurso do dono fora do write-set da tarefa) | **Pergunta** antes de agir |
| **Reversível dentro do write-set da tarefa** (dá para desfazer com git, ou está em `.cache/`) | **Decide e entrega**, com `claim`/`verify` na prova |

- **O write-set é o da tarefa**, não o repo inteiro: o que a tarefa mandou tocar é reversível
  por construção (git); o resto continua exigindo pergunta.
- **Decidir não é adivinhar:** vale para o reversível *ainda assim* medir antes de afirmar
  (Regra zero). Decidir e errar dentro do write-set é reversível; perguntar o que já podia
  medir custa um turno do dono.
- **Pergunta não segura o resto:** enquanto a resposta não chega, siga o que **não** depende
  dela e entregue o recorte; a pergunta fica nomeada com a fonte.

## Mantras (a régua de todo desenho)

Toda decisão de arquitetura — e todo ADR — é julgada por estas bases, e o desenho **diz
como atende cada uma**:

- **R1 · Já existe? Onde? Portar a ideia.** Antes de criar qualquer coisa, pergunte se
  já foi resolvido — no próprio repo, nos projetos vizinhos e benchmarks (só leitura) e no
  mercado. Porte a **lógica**, adaptada à nossa proporção; **nunca** credenciais, dados,
  bancos, hosts ou ambiente de outro projeto. Reinventar a roda é proibido.
- **R2 · KISS.** Menos código, mesma função, mais rápido. Estenda antes de criar; sem
  abstração antecipada; apagar é entrega; medir, não achar.
- **R3 · SSOT.** Toda regra, cálculo, validação, lista e componente existe em **um** lugar;
  o resto consome. Duplicação é defeito, não estilo — inclusive em docs.
- **R4 · Falha rápida e alta.** Comece pelo menor caso: 1 ou 2 testes, valide, só então o
  completo. Erro **grita** e nomeia o que faltou; nada de falhar calado.
- **Hooks em tudo.** Todo sistema e toda função de núcleo oferece hooks — antes, depois e
  ao falhar — para as ações e os filtros, em vez de acoplar quem estende a quem é estendido.
- **Idempotência.** Install, upgrade, migrate, seed, backfill: rodar de novo sem mudança
  não muda nada. Repetível e seguro por construção.
- **Modularidade.** Peça coesa, fronteira clara; um módulo se entende e se testa sozinho.
- **Plugabilidade.** Módulo ou plugin **acrescenta** capacidade em todas as superfícies
  (API, CLI, tela, evento), sem editar o núcleo.
- **Agnosticidade.** De runtime e de stack: o núcleo não conhece a ferramenta nem o banco
  de quem o consome.

## Idioma: identificador em inglês, texto em português

Regra do dono, sem exceção de projeto (curadoria 14/10; `seg-agentmem-1` #27,
`seg-agentmem-3` #3). A fronteira é **o que é símbolo** × **o que é lido por gente**:

| Superfície | Idioma |
|---|---|
| Arquivo, pasta, módulo, plugin, tabela, coluna, tipo, função, variável, branch | **inglês** |
| Texto de tela, docs, comentário de código, mensagem de commit, issue e comentário de issue, canal, **resposta ao dono** | **português** |

- **Por que o identificador é em inglês.** Ele é lido por ferramentas e por convenção de
  linguagem (import, rota, coluna de banco, `snake_case` de SQL): misturar idioma no símbolo
  quebra busca, ordenação e o próprio hábito de quem lê código.
- **Por que o texto é em português.** Quem lê é o dono e a equipe. Traduzir a saída para o
  inglês não melhora nada e piora a precisão do que foi dito.
- **A resposta ao dono entra na coluna do português.** Isso inclui resumo de entrega,
  relatório de incidente e o texto do canal — não só o código.

## Doutrinas de extracao

- **Conhecimento tem lugar por prazo, não por conveniência.** Fato/regra durável mora na
  memória (`.ai/memory/`), estado de sessão no cursor (`HANDOFF.md`), o que falta na fila
  (`BACKLOG.md`/tracker), incidente no ledger — e a mesma informação não mora em dois
  lugares (o resto aponta). Regra que só existe no cursor morre com a sessão, em silêncio.
  Fonte: `.ai/governance/onde-mora-o-conhecimento.md`.
- **Versionamento:** toda peça extraída (Tars, Tomo, Sofon, Pion, Kipp, Lazarus, Endurance)
  nasce em `0.0.1-dev.N` e sobe a versão a cada entrega, com as notas de upgrade —
  `.ai/governance/versionamento-de-extracao.md`.
- **Estado:** serviço com estado não sobe sobre volume vazio; o preflight exige o marcador do
  datadir, salvo init explícito — `.ai/governance/estado-exige-datadir.md`.
- **Nada em produção muda sem a ordem direta do dono.** Reapply, rollback, imagem, config,
  `docker compose up/down`, `systemctl restart`, `kubectl apply`, `helm upgrade`, `git push
  --force`: o agente **não** executa por conta própria — a ordem viaja na linha do comando
  (`TARS_PROD_ORDER=<data/motivo> <comando>`). Leitura (`ps`, `status`, `get`, `curl`) é
  livre; só a MUDANÇA é barrada — `.ai/gates/prod-guard/GATE.md` (doutrina
  `operacao/nada-em-prod-sem-ordem`).
- **Bug do Tars é reportado e corrigido na próxima release.** Todo consumidor que encontrar um
  bug no Tars (ou no `tars sync`/hook/gate) **reporta** no `BACKLOG` do tars com **repo, data e
  reprodução** — e o bug **entra na próxima release**; contorno local só é temporário e fica
  registrado como dívida nomeada. O `CHANGELOG` da release **lista os bugs reportados que
  fechou**. Bug sem reprodução vira "a confirmar" — não vira dívida infinita.

## Ao fechar trabalho

- **Origem antes do sintoma.** Toda falha tem uma origem (a causa da causa raiz), não só um
  sintoma; corrija lá e propague a classe na camada mais automática que a impeça em todos os
  consumidores. Campos da lição (`origem`, `propagacao`) e a régua em
  `.ai/governance/incidente-vira-prevencao.md`; a investigação em
  `.ai/skills/root-cause-debugging/`.
- **Limpeza (SOP).** Antes de fechar: apague morto, duplicata, flag sem uso e arquivo
  órfão; o que era temporário some junto. Entrega que reduz linhas ganha.
- **Segredos.** **Nunca** imprima segredo (nem em log, teste ou evidência). O cofre
  (1Password) só é aberto no refresh; em runtime leia o cache cifrado (sops+age), jamais a
  fonte.



# Ambiente: nunca cruzar sistemas de arquivos

Regra curta, universal e cara de ignorar: **a ferramenta roda do mesmo lado do repo.**
O que está no sistema de arquivos do Linux é lido, editado, buscado, instalado e testado
**de dentro do Linux** (container/WSL) — nunca pelo *mount* do Windows.

## Por que (a classe de bug que isso evita)

Atravessar a fronteira (`\\wsl.localhost\...` a partir do Windows, `/mnt/c|d/...` a partir
do WSL) passa por uma **camada de tradução** (9P/DrvFs). A tradução não é "um pouco mais
lenta": ela muda o **comportamento** que o build e o teste dependem.

- **Lentidão extrema** — a mesma instalação que leva segundos do lado certo leva minutos
  atravessando; e a lentidão aparece em CADA passo, não uma vez.
- **Eventos de arquivo que não chegam** — o watcher do dev server não vê a mudança (o evento
  morre na tradução): o build não reconstrói, o teste roda contra o código antigo, e o
  sintoma é "não mudou nada" com o arquivo mudado.
- **Symlink quebrado** — o link que vale dentro do Linux aponta para um caminho que não
  existe do outro lado; o `node_modules` vira um espelho quebrado.
- **IO alto e corrupção silenciosa** — permissões e `chmod +x` não sobrevivem de forma
  confiável entre os lados; um script que "é executável" de um lado falha do outro.

A consequência mais perigosa: o erro **não grita**. Ele degrada calado — o teste passa pelo
motivo errado, o build serve o artefato velho. É a mesma classe do `git add -A` esquecido:
não destrói nada na hora, mas põe a decisão sobre uma base falsa.

## A regra

1. **Rode tudo do lado onde o repo mora.** Editar, criar, apagar, buscar, instalar
   dependência, rodar teste/typecheck/lint/build/watcher — do lado do Linux. O lado do
   Windows existe para o que é dele: o app de desktop, o navegador, o link da memória.
2. **Nunca aponte um caminho de ferramenta para o outro sistema de arquivos.** Nada de
   `\\wsl.localhost\...` num comando Linux, nada de `/mnt/c` num processo que escreve no
   repo. A fronteira é a fronteira, não um atalho.
3. **A sandbox fica do mesmo lado do repo.** Um agente em sandbox não a atravessa: se o
   executor roda de um lado, o repo tem de estar do mesmo lado.
4. **Falhe alto em caminho não-Linux.** Um utilitário de núcleo que recebe um caminho do
   outro sistema (UNC `\\`, ou `/mnt/<letra>/`) **recusa** com mensagem nomeando a violação
   — não tenta, não degrada, não "funciona mesmo assim". Recusar é o contrato: quem chama
   aprende no primeiro erro, não no dia em que o build serve o artefato velho.
5. **Um processo, um lado.** Não misture: um watcher de um lado e um teste do outro produzem
   dois universos que não conversam, e o sintoma volta como "às vezes não pega a mudança".
6. **Serviço de apoio de teste roda na MESMA rede do agente, por nome de container —
   nunca por porta publicada.** Um banco, cache ou fila de apoio sobe na rede docker do
   agente e é alcançado pelo **nome do container**; publicar porta no host para o agente
   consumir é o antipadrão, por três motivos que se somam: a porta fica visível fora do
   agente (superfície a mais), colide com o que já estiver escutando, e amarra o teste a um
   `localhost` que só existe do lado do host. Rede nomeada + nome de container é o que faz o
   serviço de apoio ser descartável e paralelizável entre execuções.
7. **Precedência de config entre os lados do filesystem: o helper do Windows ganha do Linux
   no WSL.** Quando os dois lados oferecem o mesmo ajuste (proxy, credencial, `git config`,
   variável de ambiente), vale o do Windows — é ele que o usuário configura, e é ele que o
   processo do lado Linux herda ao subir. O caso clássico é um helper de credencial: o do
   Windows tem auth e o do Linux não, então a execução que "deveria funcionar" falha por
   estar lendo a metade errada. Ao diagnosticar divergência de config entre os lados, confira
   a do Windows **primeiro** — e ao documentar, diga de qual lado veio o valor efetivo.

## O que isto NÃO é

- Não é "Windows é ruim". É que a **fronteira** é cara — o custo é da travessia, nos dois
  sentidos.
- Não é "só a primeira vez é lenta". É pior: o watcher que não dispara e o `chmod` que não
  cola são **semânticos**, e não melhoram com o tempo.
- Não é opcional quando "é só um arquivinho". O arquivinho que você lê atravessando é o que
  ensina o hábito que, um dia, roda o build inteiro do lado errado.

## Aplicação

- Antes de rodar qualquer coisa: **onde está o repo, e onde eu estou?** Se são lados
  diferentes, mude de lado antes de rodar — não "só desta vez".
- Script de núcleo que aceita caminho: **valide a fronteira** na entrada (`\\` ou `/mnt/`)
  e recuse. É a única forma de a regra sobreviver a quem não a conhece.
- Ao escrever um procedimento (doc, runbook, prompt de worker): diga **de que lado** cada
  comando roda. "Rode o teste" sem o lado é uma instrução incompleta.

## `.cache/` é o único descartável — e ele nunca é versionado

- **Invariante de layout:** o **descartável mora só em `.cache/`**. `rm -rf .cache/` é seguro a
  qualquer momento, por construção; o que não pode ser apagado assim **não** é `.cache/` — é
  estado de verdade (banco, arquivo versionado), e esse tem outro lugar.
- **Nunca commitar `.cache/`** — nem com `git add -f`, nem porque "é pequeno". Um `.cache/`
  versionado deixa de ser descartável e passa a mentir sobre o que é estado.
- **Revisar o `git show --stat` do commit alheio** (e do próprio) procurando `.cache/`: o
  commit de terceiro é onde o arquivo descartável entra sem ninguém olhar.
- Cada worker escreve em **`--outdir` privado** (`.cache/<slot>/`) — dois runs no mesmo
  diretório sobrescrevem um ao outro.

## Comando longo vai para segundo plano

Comando que pode passar de **~10 s** (suíte, build, apply, push, varredura remota, recriar
container) roda **em segundo plano desde o início**; o resultado é lido na notificação e o
trabalho segue. Fica em primeiro plano apenas o **instantâneo** ou o comando cujo resultado é
o **próximo passo imediato** de uma resposta curta. Nunca um laço de `sleep` esperando: quem
espera o relógio cruzar perde o turno e não ganha informação.

## Python sempre por `uv`

Todo Python roda por **`uv`** (`uv run`, `uv sync --frozen`, `uv run --no-project`), nunca o
`python3`/`pip` do host: o `uv` traz o interpretador e o ambiente, e o mesmo comando vale em
qualquer máquina. Wrapper de hook Python: `command -v uv` e então
`uv run --no-project --quiet python <script>` — e a revisão do diff procura `python3 ` e
`pip install`.
<!-- /tars:boot -->

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
- Publicar = criar tag `v*` (D20; Tars `.ai/governance/versionamento-de-extracao.md`, "Quem corta a tag"): o coord
  prepara o PR final (código + seção no CHANGELOG); o corte só sai por **ordem explícita do dono** (o merge não basta); então o coord corta a tag
  anotada como Daneel, acompanha o CI e confere a Release. Tag sem Release pode ser movida; com Release, nunca.
- Achado de outra frente vai para o coord dela (Tars/homelab/telemetria: coord segtools; seo-brain: coord do
  seo-brain). Credencial exposta: seção Segurança do `BACKLOG.md` do `huldlabs`.
