# #49 — Estacionamiento del campus

**Dominio:** Educacion y campus

variante del 6, con cajones por edificio.

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

- **Procesos:** gen_statem por cajon agrupado por edificio; gen_server de ocupacion por zona; sensores simulados
- **Supervision:** supervisor por edificio
- **API / tiempo real:** GET /api/zonas, GET /api/cajones?edificio=, WebSocket del mapa del campus
- **Metricas:** ocupacion por zona, hora pico, cajones fuera de servicio
- **Prueba de caos:** reinicio de una zona: reconstruye su ocupacion desde las lecturas siguientes

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
