# #73 — Quiniela del Mundial

**Dominio:** Entretenimiento y juegos

predicciones, puntos y ranking en vivo.

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

- **Procesos:** gen_server de partidos; gen_server por participante con predicciones; calculador de puntos y ranking al cerrar cada partido
- **Supervision:** one_for_one; el calculador reiniciable y determinista
- **API / tiempo real:** POST /api/predicciones (antes del cierre), GET /api/ranking, SSE de puntos en vivo
- **Metricas:** predicciones por partido, usuarios activos, cambios de ranking
- **Prueba de caos:** enviar una prediccion despues del cierre: se rechaza aun con relojes desfasados

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
