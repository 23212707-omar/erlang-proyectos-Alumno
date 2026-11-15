# #57 — Incendios forestales

**Dominio:** Energia y medio ambiente

sensores de temperatura y humo en canones.

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

- **Procesos:** un gen_server por sensor de temperatura/humo/humedad; evaluador de riesgo por zona; gen_statem de incendio (vigilancia, sospecha, confirmado)
- **Supervision:** supervisor por canon/sector
- **API / tiempo real:** POST /api/sensores/:id/lectura, GET /api/zonas/:id/riesgo, WebSocket de alertas
- **Metricas:** zonas en riesgo, sensores sin senal, alertas confirmadas
- **Prueba de caos:** un sensor reporta humo y los vecinos no: se marca 'sospecha' y no 'confirmado'

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
