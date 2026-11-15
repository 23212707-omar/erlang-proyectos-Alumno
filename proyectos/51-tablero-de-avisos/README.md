# #51 — Tablero de avisos

**Dominio:** Educacion y campus

notificaciones por carrera y grupo.

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

- **Procesos:** gen_server de avisos con suscripciones por carrera/grupo; un proceso por conexion WebSocket; expirador de avisos
- **Supervision:** one_for_one; el distribuidor separado de las conexiones
- **API / tiempo real:** POST /api/avisos, GET /api/avisos?grupo=, WebSocket /ws con filtros
- **Metricas:** avisos activos, conexiones, entregas por segundo
- **Prueba de caos:** 1000 conexiones y un aviso masivo: todos lo reciben sin bloquear al publicador

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
