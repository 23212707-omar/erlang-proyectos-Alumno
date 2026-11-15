# #28 — Puerto de Ensenada

**Dominio:** Aviacion y transporte

gruas, contenedores y turnos de atraque.

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

- **Procesos:** gen_server por muelle y por grua; gen_statem por barco (en espera, atracado, descargando, zarpado); cola de turnos
- **Supervision:** supervisor por terminal; gruas one_for_one
- **API / tiempo real:** GET /api/muelles, GET /api/barcos, POST /api/turnos, WebSocket de operaciones
- **Metricas:** ocupacion de muelles, contenedores por hora, tiempo en espera de barcos
- **Prueba de caos:** falla de una grua en operacion: las tareas se reasignan a otra

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
