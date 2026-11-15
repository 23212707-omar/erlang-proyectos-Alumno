# #27 — Taxis o rides

**Dominio:** Aviacion y transporte

matchmaking de conductores y pasajeros.

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

- **Procesos:** un proceso por conductor y por pasajero; gen_server de matchmaking por zona; gen_statem por viaje
- **Supervision:** supervisor dinamico de viajes; zonas independientes
- **API / tiempo real:** POST /api/viajes (solicitud), WebSocket para conductor y pasajero, GET /api/viajes/:id
- **Metricas:** viajes activos, tiempo de asignacion, conductores disponibles por zona
- **Prueba de caos:** el conductor desaparece a mitad de asignacion: el viaje se reasigna automaticamente

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
