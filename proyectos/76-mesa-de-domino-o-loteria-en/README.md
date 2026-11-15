# #76 — Mesa de domino o loteria en linea

**Dominio:** Entretenimiento y juegos

salas multijugador.

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

- **Procesos:** gen_statem por mesa (esperando_jugadores, jugando, terminada); un proceso por jugador; mazo/baraja como estado del proceso de mesa
- **Supervision:** supervisor dinamico de mesas
- **API / tiempo real:** WebSocket /ws/mesa/:id, POST /api/mesas, GET /api/mesas
- **Metricas:** mesas activas, jugadores, duracion de partida
- **Prueba de caos:** un jugador se desconecta: la mesa espera o lo reemplaza segun regla, sin colgarse

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
