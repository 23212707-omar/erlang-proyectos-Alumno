# #1 — Viñedos

**Dominio:** Agro e IoT

un proceso por sensor (humedad de suelo, temperatura, hoja mojada) por hilera; `gen_statem` para riego; alertas de helada y mildiu; supervisor por parcela.

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

- **Procesos:** un gen_server por sensor (humedad, temperatura, hoja mojada) agrupado por hilera; un gen_statem de riego por hilera (reposo, regando, bloqueado por helada)
- **Supervision:** supervisor por parcela (one_for_one) bajo un supervisor raiz; los sensores de una hilera no se reinician entre si
- **API / tiempo real:** GET /api/parcelas, GET /api/hileras/:id, WebSocket /ws con lecturas y alertas de helada/mildiu
- **Metricas:** lecturas por segundo, sensores sin reportar, hileras en riego, alertas activas
- **Prueba de caos:** matar un sensor y verificar que se reinicia y el dashboard marca 'sin dato' mientras tanto

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
