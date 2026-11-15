# #31 — Control de pista y rampa

**Dominio:** Aviacion y transporte

secuenciacion de despegues y aterrizajes con prioridades.

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

- **Procesos:** gen_statem por pista (libre, ocupada, cerrada); gen_server secuenciador con cola por prioridad y separacion minima entre operaciones
- **Supervision:** rest_for_one: pistas primero, secuenciador despues
- **API / tiempo real:** POST /api/solicitudes (despegue/aterrizaje), GET /api/pistas, WebSocket de secuencia
- **Metricas:** operaciones por hora, espera media, conflictos evitados
- **Prueba de caos:** cerrar una pista con operaciones en cola: se reprograman sin perder ninguna

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
