# #5 — Estacion meteorologica

**Dominio:** Agro e IoT

ingesta de datos, promedios en ETS y `/metrics` con prometheus.

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

- **Procesos:** gen_server de ingesta, tabla ETS con ventanas de promedios (1 min, 1 h), proceso agregador periodico
- **Supervision:** one_for_one; el dueño de la tabla ETS arranca primero (rest_for_one con ingesta)
- **API / tiempo real:** POST /api/lecturas, GET /api/promedios, GET /metrics en formato Prometheus
- **Metricas:** temperatura, humedad, presion, viento (gauges); lecturas ingeridas (counter)
- **Prueba de caos:** matar al dueño de la ETS y verificar que la tabla se recrea y el agregador se reengancha

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
