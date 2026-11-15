# #22 — Torre de control TIJ

**Dominio:** Aviacion y transporte

dashboard de vuelos del Aeropuerto de Tijuana con estados (programado, abordando, despego, demorado); un proceso por vuelo y `gen_statem` por ciclo de vida.

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

- **Procesos:** un gen_statem por vuelo (programado, abordando, despegado, aterrizado, demorado, cancelado); gen_server de puertas; feed simulado de actualizaciones
- **Supervision:** supervisor dinamico de vuelos; el asignador de puertas aparte (rest_for_one con los vuelos)
- **API / tiempo real:** GET /api/vuelos, GET /api/vuelos/:id, WebSocket /ws con cambios de estado para el tablero de la torre
- **Metricas:** vuelos por estado, demora promedio, puertas ocupadas, eventos por minuto
- **Prueba de caos:** matar el proceso de un vuelo y verificar que se reconstruye con su ultimo estado y el tablero no parpadea

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
