# #43 — Citas medicas

**Dominio:** Salud

agenda sin traslapes y recordatorios.

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

- **Procesos:** gen_server por agenda de medico (huecos); gen_server de recordatorios con timers; gen_statem por cita (agendada, confirmada, atendida, cancelada)
- **Supervision:** supervisor dinamico por medico
- **API / tiempo real:** GET /api/medicos/:id/huecos, POST /api/citas, DELETE /api/citas/:id
- **Metricas:** ocupacion de agenda, cancelaciones, no-show
- **Prueba de caos:** dos pacientes toman el mismo hueco simultaneamente: sin traslape

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
