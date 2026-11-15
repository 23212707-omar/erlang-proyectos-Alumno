# #44 — Banco de sangre

**Dominio:** Salud

tipos, caducidad y emergencias.

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

- **Procesos:** gen_server de inventario por tipo de sangre y lote; gen_statem por unidad (disponible, reservada, transfundida, caducada); gestor de solicitudes de emergencia
- **Supervision:** one_for_one; emergencias con prioridad
- **API / tiempo real:** POST /api/solicitudes, GET /api/inventario, SSE de niveles criticos
- **Metricas:** unidades por tipo, proximas a caducar, solicitudes urgentes atendidas
- **Prueba de caos:** solicitud urgente con inventario insuficiente del tipo exacto: sugiere compatibles, sin doble reserva

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
