# #37 — Cadena de frio

**Dominio:** Industria y manufactura

monitoreo de temperatura en transporte y bodega.

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

- **Procesos:** un gen_server por sensor de temperatura (camion/bodega); gen_statem de cadena (en_rango, fuera_de_rango, perdida_de_producto); bitacora de excursiones
- **Supervision:** supervisor por envio; bitacora independiente
- **API / tiempo real:** POST /api/envios/:id/lectura, GET /api/envios/:id/historial, SSE de alertas
- **Metricas:** minutos fuera de rango, envios en riesgo, lecturas faltantes
- **Prueba de caos:** dejar de recibir lecturas: el envio pasa a 'sin dato' y alerta tras un tiempo limite

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
