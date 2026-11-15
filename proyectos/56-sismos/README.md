# #56 — Sismos

**Dominio:** Energia y medio ambiente

ingesta de eventos y alertas por magnitud.

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

- **Procesos:** gen_server de ingesta de eventos sismicos; clasificador por magnitud; despachador de alertas con niveles y deduplicacion
- **Supervision:** one_for_one; despachador separado para no perder alertas
- **API / tiempo real:** POST /api/eventos, GET /api/sismos?min_mag=, WebSocket/SSE de alertas
- **Metricas:** eventos por hora, magnitud maxima, alertas enviadas, latencia de alerta
- **Prueba de caos:** rafaga de 500 eventos (replicas): se deduplican y la alerta sale una sola vez

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
