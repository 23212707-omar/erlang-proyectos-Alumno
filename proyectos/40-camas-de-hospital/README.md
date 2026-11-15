# #40 — Camas de hospital

**Dominio:** Salud

ocupacion, altas y limpieza.

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

- **Procesos:** un gen_statem por cama (libre, ocupada, por_limpiar, bloqueada); gen_server de admisiones que asigna camas por servicio
- **Supervision:** supervisor por piso/servicio
- **API / tiempo real:** GET /api/camas, POST /api/admisiones, POST /api/camas/:id/alta, SSE de ocupacion
- **Metricas:** ocupacion por servicio, rotacion de camas, tiempo de limpieza
- **Prueba de caos:** dos admisiones piden la ultima cama libre: solo una la obtiene

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
