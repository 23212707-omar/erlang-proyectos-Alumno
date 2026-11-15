# #71 — Proteccion civil

**Dominio:** Seguridad y ciudad

seguimiento de albergues e inventario durante un evento.

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

- **Procesos:** gen_server por albergue (capacidad, ocupacion); inventario de suministros; gen_statem de evento (alerta, activo, cerrado); asignador de damnificados
- **Supervision:** supervisor por evento; albergues dinamicos
- **API / tiempo real:** GET /api/albergues, POST /api/registros, POST /api/suministros, SSE del tablero
- **Metricas:** ocupacion de albergues, suministros criticos, personas registradas
- **Prueba de caos:** albergue lleno durante registro concurrente: se redirige a otro con cupo

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
