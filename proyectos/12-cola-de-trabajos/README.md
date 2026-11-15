# #12 — Cola de trabajos

**Dominio:** Servicios web y datos

workers con reintentos y backoff, con supervision.

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

- **Procesos:** gen_server de cola, pool de workers, scheduler de reintentos con backoff exponencial
- **Supervision:** supervisor de workers one_for_one; la cola no se cae si un worker falla en un job
- **API / tiempo real:** POST /api/jobs, GET /api/jobs/:id, GET /api/jobs?estado=
- **Metricas:** jobs en cola, exitosos/fallidos, reintentos, latencia en cola
- **Prueba de caos:** un worker que siempre falla: el job debe agotar reintentos y pasar a 'muerto' sin tumbar el sistema

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
