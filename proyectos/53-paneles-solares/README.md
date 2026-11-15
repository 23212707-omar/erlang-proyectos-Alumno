# #53 — Paneles solares

**Dominio:** Energia y medio ambiente

produccion contra consumo y recomendaciones de uso.

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

- **Procesos:** gen_server de inversor (produccion); gen_server de consumo; calculador de balance y recomendaciones
- **Supervision:** one_for_one; el calculador depende de ambos (rest_for_one)
- **API / tiempo real:** POST /api/produccion, POST /api/consumo, GET /api/balance?dia=, SSE en vivo
- **Metricas:** kWh producidos/consumidos, autoconsumo, picos
- **Prueba de caos:** caida del inversor: el balance marca produccion 0 y alerta, sin inventar datos

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
