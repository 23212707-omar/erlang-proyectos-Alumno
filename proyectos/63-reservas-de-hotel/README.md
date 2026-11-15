# #63 — Reservas de hotel

**Dominio:** Comercio, finanzas y servicios

disponibilidad por fecha sin sobreventa.

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

- **Procesos:** gen_server por habitacion/tipo con calendario de disponibilidad; gen_statem por reserva (pendiente, confirmada, check_in, check_out, cancelada)
- **Supervision:** supervisor por hotel; calendario serializado en un proceso por tipo de habitacion
- **API / tiempo real:** GET /api/disponibilidad?desde=&hasta=, POST /api/reservas, DELETE /api/reservas/:id
- **Metricas:** ocupacion por fecha, reservas canceladas, ingresos estimados
- **Prueba de caos:** N reservas simultaneas sobre la ultima habitacion: exactamente una gana

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
