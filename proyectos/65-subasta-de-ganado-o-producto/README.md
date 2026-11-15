# #65 — Subasta de ganado o productos

**Dominio:** Comercio, finanzas y servicios

puja en tiempo real.

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

- **Procesos:** gen_statem por lote subastado (abierto, ultima_llamada, adjudicado); gen_server de pujas ordenadas; proceso de reloj de cierre
- **Supervision:** supervisor dinamico por lote
- **API / tiempo real:** WebSocket /ws/subasta con pujas en vivo, POST /api/lotes/:id/pujas, GET /api/lotes
- **Metricas:** pujas por lote, precio final vs base, participantes activos
- **Prueba de caos:** puja en el ultimo milisegundo: la regla de extension de tiempo se aplica de forma determinista

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
