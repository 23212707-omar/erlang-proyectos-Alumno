# #19 — Observabilidad

**Dominio:** Operacion y calidad

recon, metricas Prometheus y `logger` con metadata.

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

- **Procesos:** app de ejemplo con workers instrumentados; endpoint /metrics; scripts de recon
- **Supervision:** supervisor de metricas separado para no afectar al sistema observado
- **API / tiempo real:** GET /metrics (prometheus), GET /api/salud, dashboard de procesos/memoria/colas
- **Metricas:** memoria por allocator, colas de mensajes, procesos por tipo, schedulers utilization
- **Prueba de caos:** crear una fuga de memoria o cola creciente a proposito y diagnosticarla con recon:proc_count/2

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
