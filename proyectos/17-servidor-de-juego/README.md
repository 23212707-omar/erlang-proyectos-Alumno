# #17 — Servidor de juego

**Dominio:** Sistemas distribuidos

(tres en raya, trivia, ajedrez): un proceso por partida y matchmaking.

## Equipo

| Rol | Integrante |
|---|---|
| Backend (OTP) | |
| Frontend (Stitch + cowboy) | |
| Ops/QA | |

## Arranque

```bash
rebar3 compile
rebar3 eunit
rebar3 shell
```

## Pendiente

- [ ] Disenar pantallas en Stitch (`design/PROMPT_STITCH.md`)
- [ ] Modelar el dominio: que es un proceso, que es un supervisor
- [ ] Endpoints `/api/...` y WebSocket con cowboy
- [ ] Metricas `/metrics` y diagnostico con recon
- [ ] Release + systemd
- [ ] Prueba de caos (matar procesos y verificar recuperacion)

## Diseno OTP sugerido

- **Procesos:** un gen_statem por partida; gen_server de matchmaking con cola de espera; un proceso por jugador
- **Supervision:** supervisor dinamico de partidas; si una partida cae solo se pierde esa
- **API / tiempo real:** WebSocket /ws/juego, POST /api/partidas, GET /api/partidas/:id
- **Metricas:** partidas activas, jugadores en cola, duracion media de partida
- **Prueba de caos:** matar una partida a la mitad: ambos jugadores reciben aviso y regresan al lobby

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
