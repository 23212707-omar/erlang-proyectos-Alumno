# #21 — Pruebas de caos

**Dominio:** Operacion y calidad

matar procesos a proposito y verificar que el arbol de supervision se recupera.

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

- **Procesos:** app con arbol de supervision de varios niveles y un 'caos monkey' que mata procesos al azar
- **Supervision:** mezcla one_for_one, rest_for_one y one_for_all para observar las diferencias
- **API / tiempo real:** GET /api/arbol (topologia viva), POST /api/caos/matar, SSE de reinicios
- **Metricas:** reinicios por supervisor, intensidad/periodo alcanzado, tiempo de recuperacion
- **Prueba de caos:** subir la tasa de muertes hasta agotar la intensidad del supervisor y observar la escalada

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
