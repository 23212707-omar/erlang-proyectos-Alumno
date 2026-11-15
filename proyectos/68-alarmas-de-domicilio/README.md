# #68 — Alarmas de domicilio

**Dominio:** Seguridad y ciudad

eventos, falsos positivos y escalamiento.

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

- **Procesos:** un gen_server por domicilio/panel; clasificador de eventos (sensor, panico, falla de red); gen_statem de alarma con verificacion y escalamiento
- **Supervision:** supervisor dinamico de domicilios
- **API / tiempo real:** POST /api/domicilios/:id/evento, POST /api/alarmas/:id/verificar, WebSocket de operador
- **Metricas:** alarmas por tipo, falsos positivos, tiempo a verificacion
- **Prueba de caos:** un panel deja de latir: se genera alarma de falla de comunicacion

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
