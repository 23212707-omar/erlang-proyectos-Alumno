# #6 — Estacionamiento inteligente

**Dominio:** Ciudad y edificios

cada cajon es un proceso; reservas y disponibilidad en tiempo real.

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

- **Procesos:** un gen_statem por cajon (libre, reservado, ocupado, fuera_de_servicio); gen_server de reservas con expiracion
- **Supervision:** supervisor por nivel/zona; reservas separado para no perder el estado de los cajones
- **API / tiempo real:** GET /api/cajones, POST /api/reservas, WebSocket con cambios de ocupacion
- **Metricas:** ocupacion por zona, reservas activas/expiradas, tiempo medio de estancia
- **Prueba de caos:** dos clientes reservan el mismo cajon a la vez: solo uno debe ganar

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
