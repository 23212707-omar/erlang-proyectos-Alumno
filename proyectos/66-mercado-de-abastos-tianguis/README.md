# #66 — Mercado de abastos / tianguis

**Dominio:** Comercio, finanzas y servicios

pedidos de comerciantes y repartidores.

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

- **Procesos:** gen_server por comerciante con su catalogo; gen_statem por pedido; asignador de repartidores por cercania
- **Supervision:** supervisor por mercado; repartidores dinamicos
- **API / tiempo real:** GET /api/comerciantes, POST /api/pedidos, WebSocket de seguimiento al cliente
- **Metricas:** pedidos por comerciante, tiempo de entrega, repartidores libres
- **Prueba de caos:** el repartidor deja de responder: el pedido se reasigna sin duplicar la entrega

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
