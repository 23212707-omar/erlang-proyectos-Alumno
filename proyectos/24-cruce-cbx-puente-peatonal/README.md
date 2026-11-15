# #24 — Cruce CBX / puente peatonal

**Dominio:** Aviacion y transporte

colas, tiempos de espera y capacidad por hora.

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

- **Procesos:** gen_server por carril/ventanilla; generador de llegadas simuladas; estimador de espera
- **Supervision:** supervisor por sentido (norte/sur); estimador aparte
- **API / tiempo real:** GET /api/colas, WebSocket con tiempos de espera, historial por hora
- **Metricas:** personas en cola, espera estimada, capacidad por hora
- **Prueba de caos:** cerrar un carril de golpe y verificar que el estimador reacomoda la espera

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
