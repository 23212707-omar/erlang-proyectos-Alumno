# #70 — Alumbrado publico

**Dominio:** Seguridad y ciudad

lamparas con fallas reportadas y mapa de reparacion.

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

- **Procesos:** un gen_server por luminaria o circuito; gen_statem de reporte de falla (reportada, asignada, reparada); programador de cuadrillas
- **Supervision:** supervisor por sector
- **API / tiempo real:** POST /api/lamparas/:id/falla, GET /api/mapa/fallas, PATCH /api/fallas/:id
- **Metricas:** lamparas apagadas, tiempo de reparacion, fallas por sector
- **Prueba de caos:** reporte duplicado del mismo poste por varias personas: se agrupa en una sola falla

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
