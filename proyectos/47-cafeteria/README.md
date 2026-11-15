# #47 — Cafeteria

**Dominio:** Educacion y campus

pedidos, cola y tiempo estimado.

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

- **Procesos:** gen_statem por pedido (recibido, preparando, listo, entregado); gen_server de cocina con cola; estimador de tiempo
- **Supervision:** one_for_one; cocina y pedidos separados
- **API / tiempo real:** POST /api/pedidos, GET /api/pedidos/:id, WebSocket de pantalla de cocina y de cliente
- **Metricas:** pedidos en cola, tiempo medio de preparacion, productos agotados
- **Prueba de caos:** caer la cocina con pedidos en proceso: se reconstruyen desde la persistencia

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
