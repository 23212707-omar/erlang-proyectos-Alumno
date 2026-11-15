# #10 — API REST con cowboy y PostgreSQL

**Dominio:** Servicios web y datos

CRUD con epgsql y poolboy, pruebas de carga.

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

- **Procesos:** handlers cowboy, pool de conexiones epgsql con poolboy, gen_server de migraciones al arranque
- **Supervision:** pool bajo supervisor propio; si la DB cae, la API responde 503 y no se cae el nodo
- **API / tiempo real:** CRUD /api/recursos (GET/POST/PUT/DELETE), paginacion, errores JSON consistentes
- **Metricas:** latencia por endpoint, conexiones del pool en uso, errores 5xx
- **Prueba de caos:** detener PostgreSQL con la API en carga y verificar degradacion limpia y reconexion

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
