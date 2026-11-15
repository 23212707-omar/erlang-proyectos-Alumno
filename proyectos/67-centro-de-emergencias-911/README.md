# #67 — Centro de emergencias 911

**Dominio:** Seguridad y ciudad

despacho de unidades por prioridad y cercania.

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

- **Procesos:** gen_server de incidentes con prioridad; gen_statem por incidente (recibido, despachado, en_sitio, cerrado); gen_server por unidad (posicion, estado); selector de unidad mas cercana
- **Supervision:** rest_for_one: unidades antes que el despachador
- **API / tiempo real:** POST /api/incidentes, GET /api/unidades, WebSocket de mapa y de despacho
- **Metricas:** tiempo de despacho, incidentes abiertos por prioridad, unidades disponibles
- **Prueba de caos:** la unidad asignada no acepta en N segundos: se reasigna a la siguiente mas cercana

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
