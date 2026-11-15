# #26 — Central camionera / rutas urbanas

**Dominio:** Aviacion y transporte

seguimiento de unidades y llegada estimada.

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

- **Procesos:** un gen_server por unidad (posicion, ruta, ocupacion); gen_server por ruta con paradas; calculador de llegada estimada
- **Supervision:** supervisor por ruta; unidades dinamicas
- **API / tiempo real:** POST /api/unidades/:id/posicion, GET /api/rutas/:id/llegadas, WebSocket del mapa
- **Metricas:** unidades activas, retraso medio por ruta, posiciones por segundo
- **Prueba de caos:** una unidad deja de reportar: se marca fuera de servicio y la ETA excluye esa unidad

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
