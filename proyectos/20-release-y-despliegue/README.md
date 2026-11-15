# #20 — Release y despliegue

**Dominio:** Operacion y calidad

`rebar3 release`, servicio systemd y `remote_console`.

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

- **Procesos:** release de una app minima con cowboy; unidad systemd; script de despliegue
- **Supervision:** arbol normal; lo importante es el empaquetado y el ciclo de vida
- **API / tiempo real:** GET /api/version y /api/salud para verificar el despliegue
- **Metricas:** tiempo de arranque, reinicios por systemd, uptime
- **Prueba de caos:** kill -9 al nodo y verificar que systemd lo levanta (Restart=on-failure); probar actualizacion de version

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
