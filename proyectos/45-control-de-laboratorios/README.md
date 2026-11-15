# #45 — Control de laboratorios

**Dominio:** Educacion y campus

reservas de salas y equipos del TecNM Tijuana.

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

- **Procesos:** gen_server por laboratorio con calendario; gen_statem por reserva (solicitada, aprobada, en_uso, finalizada); inventario de equipos
- **Supervision:** supervisor por edificio/laboratorio
- **API / tiempo real:** GET /api/laboratorios/:id/disponibilidad, POST /api/reservas, GET /api/reservas?grupo=
- **Metricas:** ocupacion por laboratorio, reservas canceladas, uso por carrera
- **Prueba de caos:** reservas traslapadas simultaneas: una se rechaza con mensaje claro

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
