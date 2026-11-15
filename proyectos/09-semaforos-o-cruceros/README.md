# #9 — Semaforos o cruceros

**Dominio:** Ciudad y edificios

maquinas de estado coordinadas con `rest_for_one`.

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

- **Procesos:** un gen_statem por semaforo (rojo, verde, amarillo, intermitente); coordinador por crucero que sincroniza fases
- **Supervision:** rest_for_one: coordinador primero, luego los semaforos que dependen de el
- **API / tiempo real:** GET /api/cruceros/:id, POST /api/cruceros/:id/modo (normal/intermitente/manual), SSE del estado
- **Metricas:** ciclos completados, fallas de fase, tiempo en modo intermitente
- **Prueba de caos:** matar un semaforo y verificar que el crucero pasa a intermitente por seguridad (nunca dos verdes cruzados)

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
