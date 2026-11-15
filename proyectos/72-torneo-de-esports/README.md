# #72 — Torneo de esports

**Dominio:** Entretenimiento y juegos

brackets, partidas y marcadores en vivo.

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

- **Procesos:** gen_server de torneo con bracket; gen_statem por partida (programada, en_juego, finalizada); proceso de marcador en vivo
- **Supervision:** supervisor dinamico por partida
- **API / tiempo real:** GET /api/torneos/:id/bracket, POST /api/partidas/:id/resultado, WebSocket de marcadores
- **Metricas:** partidas en curso, espectadores, avance del bracket
- **Prueba de caos:** resultado reportado dos veces con valores distintos: se marca en disputa

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
