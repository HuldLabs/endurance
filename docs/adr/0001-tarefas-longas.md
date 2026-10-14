# ADR-0001 — Tarefa longa no container: `setsid` (via `endurance-bg`)

**Estado:** aceito (13/10/2026). **Fonte do pedido:** seo-brain, ciclo de 13/10
(`seo-brain/.ai/memory/agent/seo-brain-ciclo-13-10.md`: "container mata background/`-d` → tarefa longa só por
`setsid` no HOST").

## Contexto

Servidores de desenvolvimento (ollama, API, MCP HTTP, runner) morriam quando o agente terminava o comando que os
subia. O remendo foi rodar `setsid` **no host**, fora do container.

## O que a prova mostrou (13/10, `endurance-base:local`)

1. **O container não mata nada.** `docker exec -d`, `cmd &`, `nohup cmd &` e `setsid cmd &` sobrevivem ao fim do
   `docker exec`, e até ao cliente morto por `timeout`.
2. **Quem mata é o harness do agente.** Ele dá TERM no grupo de processos do comando quando o comando acaba.
   Simulando isso (`kill -TERM -- -<pgid>`), `cmd &` e `nohup cmd &` morrem, porque herdam o grupo e o `nohup` só
   ignora HUP. Só o `setsid cmd &` sobrevive, porque abre sessão e grupo próprios.

Então o host não é necessário: `setsid` **dentro** do container basta.

## Decisão

O mecanismo canônico é **`endurance-bg`**, que vem na imagem base: um `setsid` com nome, log e pidfile.

```bash
endurance-bg start ollama -- ollama serve      # idempotente: não sobe duas vezes
endurance-bg status                            # todos os nomes
endurance-bg log ollama                        # tail -f do log
endurance-bg stop ollama                       # TERM no grupo inteiro
```

O estado fica em `~/.local/state/endurance-bg/` (`ENDURANCE_BG_DIR` muda o caminho).

## Alternativas rejeitadas

- **`nohup cmd &`:** morre com o grupo (prova 2). O `nohup` só protege de SIGHUP.
- **`setsid` no host:** funciona, mas tira o processo do ambiente declarado (versões, rede do compose,
  segredos do container) e não vale em runner nem em outra máquina.
- **`docker exec -d`:** sobrevive, mas exige o socket do Docker dentro do agente, e o socket fica desligado por
  padrão (segurança multiusuário, item 3).
- **systemd `--user`:** o container não roda systemd (o PID 1 é o `tini`). Pôr systemd na imagem contradiz a base
  enxuta.
- **Serviço no compose:** é o caminho certo para o que é **serviço de verdade**, como Postgres, ollama de
  produção ou MinIO (decisão D8). O `endurance-bg` é para processo de **desenvolvimento** que o agente sobe e
  derruba.

## Consequências

- O seo-brain troca as cerca de dez linhas `setsid … > /tmp/x.log 2>&1 < /dev/null &` do Taskfile por
  `endurance-bg start <nome> -- …`. O log deixa de ficar em `/tmp`.
- Um processo do `endurance-bg` morre com o container. Para durar mais que isso, o processo vira serviço do compose.
