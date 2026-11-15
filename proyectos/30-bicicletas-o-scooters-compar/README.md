# #30 — Bicicletas o scooters compartidos

**Dominio:** Aviacion y transporte

disponibilidad de estaciones y rebalanceo.

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

- **Procesos:** un gen_server por estacion (bicis disponibles, espacios); un gen_statem por unidad (disponible, en_uso, mantenimiento); calculador de rebalanceo
- **Supervision:** supervisor por zona; rebalanceo reiniciable
- **API / tiempo real:** GET /api/estaciones, POST /api/unidades/:id/desbloquear, SSE de disponibilidad
- **Metricas:** ocupacion por estacion, viajes por hora, estaciones vacias/llenas
- **Prueba de caos:** dos usuarios desbloquean la misma unidad: solo uno lo logra

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
