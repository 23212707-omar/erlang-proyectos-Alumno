# #14 — Acortador de URLs

**Dominio:** Servicios web y datos

caso basico para empezar con cowboy y ETS.

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

- **Procesos:** gen_server generador de codigos cortos; tabla ETS (y dets/DB) de codigo->URL; contador de visitas
- **Supervision:** one_for_one simple; ideal para el primer proyecto con cowboy
- **API / tiempo real:** POST /api/urls, GET /:codigo (redirect 302), GET /api/urls/:codigo/stats
- **Metricas:** redirecciones por segundo, codigos creados, 404
- **Prueba de caos:** reiniciar el nodo y verificar que los codigos persisten

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
