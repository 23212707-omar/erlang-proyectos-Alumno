# #42 — Farmacia

**Dominio:** Salud

inventario, caducidades y recetas.

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

- **Procesos:** gen_server de inventario de medicamentos con lotes y caducidad; gen_statem de receta (emitida, surtida parcial, surtida, vencida); revisor de caducidades periodico
- **Supervision:** one_for_one; el revisor independiente
- **API / tiempo real:** POST /api/recetas, POST /api/recetas/:id/surtir, GET /api/caducidades?dias=
- **Metricas:** existencias criticas, lotes proximos a caducar, recetas surtidas/rechazadas
- **Prueba de caos:** surtir en paralelo la misma receta dos veces: la segunda debe rechazarse

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
