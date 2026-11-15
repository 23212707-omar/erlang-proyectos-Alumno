# #58 — Playa y oleaje

**Dominio:** Energia y medio ambiente

bandera de seguridad segun condiciones.

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

- **Procesos:** gen_server de condiciones (oleaje, viento, corrientes); gen_statem de bandera (verde, amarilla, roja); registro de cambios
- **Supervision:** one_for_one simple; buen proyecto inicial
- **API / tiempo real:** POST /api/condiciones, GET /api/bandera, SSE de cambios de bandera
- **Metricas:** altura de ola, viento, cambios de bandera por dia
- **Prueba de caos:** datos faltantes: la bandera sube a amarilla por precaucion, no se queda en verde

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
