# #2 — Invernadero

**Dominio:** Agro e IoT

ventilacion, humedad y CO2 con `gen_statem` y lazo de control; modo seguro si falla un sensor.

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

- **Procesos:** gen_statem de clima (enfriando, calentando, estable, modo_seguro); un gen_server por actuador (ventila, riego, CO2) y por sensor
- **Supervision:** rest_for_one: sensores primero, luego el controlador, luego los actuadores
- **API / tiempo real:** GET /api/estado, POST /api/actuadores/:id (manual/auto), SSE con el estado del clima
- **Metricas:** temperatura/humedad/CO2 actuales, cambios de modo, tiempo en modo_seguro
- **Prueba de caos:** matar un sensor de temperatura y comprobar que el controlador entra a modo_seguro

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
