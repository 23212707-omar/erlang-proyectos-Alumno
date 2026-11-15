# #11 — Chat o notificaciones

**Dominio:** Servicios web y datos

WebSockets de cowboy, un proceso por sala.

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

- **Procesos:** un gen_server por sala; un proceso por conexion WebSocket (cowboy_websocket); registro de salas con gproc o Registry en ETS
- **Supervision:** supervisor dinamico de salas; cada conexion es un proceso aislado
- **API / tiempo real:** WebSocket /ws/:sala, GET /api/salas, historial reciente por sala
- **Metricas:** usuarios conectados, mensajes por segundo, salas activas
- **Prueba de caos:** 100 clientes simulados en una sala, matar la sala y verificar que se reconectan y la sala se recrea

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
