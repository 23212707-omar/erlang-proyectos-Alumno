# #32 — Linea de produccion

**Dominio:** Industria y manufactura

estaciones como procesos, cuellos de botella y paros.

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

- **Procesos:** un gen_statem por estacion (esperando, procesando, bloqueada, falla); buffers entre estaciones como procesos con cola acotada
- **Supervision:** supervisor de linea rest_for_one en el orden de las estaciones
- **API / tiempo real:** GET /api/linea, POST /api/estaciones/:id/paro, SSE de piezas y cuellos de botella
- **Metricas:** piezas por hora, estacion cuello de botella, tiempo de paro
- **Prueba de caos:** matar una estacion y verificar que las anteriores se detienen por backpressure y no se llenan

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
