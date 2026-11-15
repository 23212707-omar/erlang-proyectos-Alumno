# #38 — Andon digital

**Dominio:** Industria y manufactura

boton de llamada de ayuda y escalamiento por tiempo.

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

- **Procesos:** gen_statem por estacion andon (normal, llamada, atendida, escalada); timers de escalamiento por nivel (supervisor, gerente)
- **Supervision:** supervisor por linea; el escalador es un proceso por llamada
- **API / tiempo real:** POST /api/estaciones/:id/llamada, POST /api/llamadas/:id/atender, WebSocket del tablero andon
- **Metricas:** llamadas por turno, tiempo de respuesta, escalamientos
- **Prueba de caos:** matar el proceso de una llamada abierta: debe reconstruirse y seguir escalando

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
