# #35 — Control de calidad

**Dominio:** Industria y manufactura

lotes, defectos y semaforo de rechazo.

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

- **Procesos:** un gen_server por lote; evaluador de reglas de aceptacion; gen_statem de lote (en_inspeccion, aprobado, rechazado)
- **Supervision:** supervisor dinamico de lotes
- **API / tiempo real:** POST /api/lotes, POST /api/lotes/:id/defectos, GET /api/lotes/:id semaforo
- **Metricas:** tasa de defectos, lotes rechazados, tiempo de inspeccion
- **Prueba de caos:** registrar defectos concurrentes y verificar que el semaforo es consistente

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
