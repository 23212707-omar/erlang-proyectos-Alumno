# #18 — Subasta o reservas

**Dominio:** Sistemas distribuidos

concurrencia sin condiciones de carrera.

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

- **Procesos:** gen_server por subasta/recurso reservable que serializa pujas/reservas; gen_statem con estados (abierta, cerrada, adjudicada)
- **Supervision:** supervisor dinamico por subasta; el reloj de cierre es un timer del propio proceso
- **API / tiempo real:** POST /api/subastas/:id/pujas, GET /api/subastas/:id, SSE con la mejor puja
- **Metricas:** pujas por segundo, subastas abiertas, pujas rechazadas por orden
- **Prueba de caos:** 1000 pujas simultaneas: debe ganar la mayor y sin duplicados de adjudicacion

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
