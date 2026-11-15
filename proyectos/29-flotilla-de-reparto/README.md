# #29 — Flotilla de reparto

**Dominio:** Aviacion y transporte

rastreo GPS simulado y reasignacion de entregas.

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

- **Procesos:** un gen_server por vehiculo (posicion, carga); gen_server despachador que asigna entregas; gen_statem por entrega (pendiente, en_ruta, entregada, fallida)
- **Supervision:** supervisor dinamico de vehiculos; despachador separado
- **API / tiempo real:** POST /api/vehiculos/:id/posicion, POST /api/entregas, WebSocket del mapa de la flotilla
- **Metricas:** entregas por estado, vehiculos activos, retraso medio
- **Prueba de caos:** un vehiculo se queda sin reportar: sus entregas pendientes se reasignan

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
