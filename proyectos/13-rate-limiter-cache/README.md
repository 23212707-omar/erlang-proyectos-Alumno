# #13 — Rate limiter / cache

**Dominio:** Servicios web y datos

ETS con `read_concurrency` y expiracion de entradas.

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

- **Procesos:** tabla ETS publica con read_concurrency; gen_server limpiador de expiraciones; token bucket por cliente
- **Supervision:** el dueño de la ETS bajo supervisor propio y arranca antes que el limpiador
- **API / tiempo real:** GET /api/cache/:clave, PUT /api/cache/:clave?ttl=, middleware cowboy que responde 429
- **Metricas:** hits/misses, evictions, entradas, rechazos 429
- **Prueba de caos:** 10 000 lecturas concurrentes mientras el limpiador corre: sin errores ni bloqueos

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
