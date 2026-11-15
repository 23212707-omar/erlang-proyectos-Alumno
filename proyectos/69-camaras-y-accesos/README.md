# #69 — Camaras y accesos

**Dominio:** Seguridad y ciudad

bitacora de eventos y busqueda por rango de tiempo.

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

- **Procesos:** un gen_server por camara/lector con estado; bitacora de eventos indexada por tiempo (ETS ordered_set); procesador de consultas por rango
- **Supervision:** supervisor por sitio; la bitacora aislada
- **API / tiempo real:** POST /api/eventos, GET /api/eventos?desde=&hasta=&camara=, WebSocket de eventos nuevos
- **Metricas:** eventos por camara, camaras offline, tiempo de respuesta de consultas
- **Prueba de caos:** millones de eventos y una consulta de rango: sin bloquear la ingesta

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
