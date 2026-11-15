# #52 — Calidad del aire

**Dominio:** Energia y medio ambiente

red de sensores con alerta por contaminacion (pm2.5).

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

- **Procesos:** un gen_server por estacion/sensor de pm2.5; calculador de AQI por ventana; gen_statem de alerta (buena, moderada, danina)
- **Supervision:** supervisor por zona; calculador reiniciable
- **API / tiempo real:** POST /api/estaciones/:id/lectura, GET /api/aqi, WebSocket de alertas
- **Metricas:** AQI por zona, lecturas invalidas, estaciones sin reportar
- **Prueba de caos:** lecturas absurdas (negativas): se descartan y se cuentan, sin romper el promedio

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
