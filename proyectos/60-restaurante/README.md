# #60 — Restaurante

**Dominio:** Comercio, finanzas y servicios

comandas, cocina, mesas y tiempos.

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

- **Procesos:** gen_server por mesa; gen_statem por comanda (tomada, en_cocina, lista, servida); gen_server de cocina por estacion
- **Supervision:** supervisor por turno; cocina y salon separados
- **API / tiempo real:** POST /api/mesas/:id/comandas, GET /api/cocina/cola, WebSocket de meseros y cocina
- **Metricas:** tiempo mesa->servido, comandas por estacion, mesas ocupadas
- **Prueba de caos:** caer la estacion de cocina: las comandas se redistribuyen a otra

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
