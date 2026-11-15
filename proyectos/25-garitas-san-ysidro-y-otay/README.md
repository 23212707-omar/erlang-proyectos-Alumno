# #25 — Garitas San Ysidro y Otay

**Dominio:** Aviacion y transporte

tiempos de espera por carril y prediccion simple con promedios moviles.

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

- **Procesos:** un gen_server por garita y carril; ventana deslizante de tiempos; predictor simple (promedio movil)
- **Supervision:** supervisor por garita (San Ysidro, Otay); predictor reiniciable sin perder historia (ETS)
- **API / tiempo real:** POST /api/garitas/:id/lectura, GET /api/garitas, GET /api/prediccion?hora=
- **Metricas:** espera actual vs promedio, error de la prediccion, lecturas faltantes
- **Prueba de caos:** dejar de enviar lecturas de una garita y verificar que el dashboard marca dato obsoleto

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
