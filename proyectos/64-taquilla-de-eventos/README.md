# #64 — Taquilla de eventos

**Dominio:** Comercio, finanzas y servicios

venta de boletos con concurrencia alta.

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

- **Procesos:** gen_server de inventario de asientos por evento; gen_statem por compra (seleccion, bloqueada con timeout, pagada, expirada); sala de espera virtual
- **Supervision:** supervisor por evento; la sala de espera separada para absorber picos
- **API / tiempo real:** POST /api/eventos/:id/bloquear, POST /api/compras/:id/pagar, GET /api/eventos/:id/asientos, WebSocket de disponibilidad
- **Metricas:** asientos vendidos/bloqueados, conversion, longitud de la sala de espera
- **Prueba de caos:** 5000 compradores por 100 asientos: sin sobreventa y los bloqueos vencen y se liberan

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
