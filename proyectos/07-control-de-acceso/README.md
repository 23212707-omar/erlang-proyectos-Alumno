# #7 — Control de acceso

**Dominio:** Ciudad y edificios

gen_server por puerta, bitacora de eventos, revocacion de credenciales.

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

- **Procesos:** un gen_server por puerta (cerrada, abierta, forzada); gen_server de credenciales (ETS) con revocacion; gen_server bitacora
- **Supervision:** one_for_one; la bitacora nunca debe caer por una falla de puerta
- **API / tiempo real:** POST /api/accesos (intento), GET /api/bitacora?desde=&hasta=, POST /api/credenciales/:id/revocar
- **Metricas:** accesos permitidos/denegados, puertas forzadas, credenciales revocadas
- **Prueba de caos:** revocar una credencial durante un intento de acceso concurrente y verificar que se niega

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
