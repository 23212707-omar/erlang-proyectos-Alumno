# #61 — Cotizador de divisas

**Dominio:** Comercio, finanzas y servicios

peso/dolar con historico y alertas.

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

- **Procesos:** gen_server que consulta cotizaciones periodicamente; historico en ETS/DB; evaluador de alertas por umbral con suscripciones
- **Supervision:** supervisor con el cliente HTTP aislado: si la fuente cae, el resto sigue con el ultimo valor
- **API / tiempo real:** GET /api/cotizacion, GET /api/historico?dias=, POST /api/alertas, SSE de cambios
- **Metricas:** ultimo valor, variacion, fallos de la fuente, alertas disparadas
- **Prueba de caos:** cortar la fuente externa: se sirve el ultimo dato marcado como 'obsoleto'

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
