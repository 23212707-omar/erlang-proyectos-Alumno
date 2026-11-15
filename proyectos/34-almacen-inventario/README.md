# #34 — Almacen / inventario

**Dominio:** Industria y manufactura

entradas, salidas, alertas de minimos y trazabilidad.

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

- **Procesos:** gen_server por almacen o ubicacion; tabla de existencias en ETS/DB; verificador de minimos
- **Supervision:** one_for_one; el verificador de minimos es independiente de los movimientos
- **API / tiempo real:** POST /api/movimientos (entrada/salida), GET /api/existencias, GET /api/alertas
- **Metricas:** existencias por SKU, movimientos por hora, alertas de minimo
- **Prueba de caos:** 1000 salidas simultaneas del mismo SKU: nunca debe quedar negativo

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
