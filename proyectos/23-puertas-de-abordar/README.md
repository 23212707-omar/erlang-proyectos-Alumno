# #23 — Puertas de abordar

**Dominio:** Aviacion y transporte

asignacion dinamica de puertas con conflictos y reasignacion.

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

- **Procesos:** gen_server asignador de puertas; un gen_statem por puerta (libre, asignada, abordando); cola de vuelos sin puerta
- **Supervision:** one_for_one por puerta, asignador separado
- **API / tiempo real:** GET /api/puertas, POST /api/asignaciones, SSE de reasignaciones
- **Metricas:** ocupacion de puertas, reasignaciones, conflictos resueltos
- **Prueba de caos:** liberar una puerta durante una asignacion concurrente: sin dos vuelos en la misma puerta

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
