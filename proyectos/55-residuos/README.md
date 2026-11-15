# #55 — Residuos

**Dominio:** Energia y medio ambiente

contenedores con nivel de llenado y ruta de recoleccion.

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

- **Procesos:** un gen_server por contenedor (nivel de llenado); planificador de rutas por umbral; gen_statem de camion (en_ruta, recolectando, descargando)
- **Supervision:** supervisor por zona; planificador aparte
- **API / tiempo real:** POST /api/contenedores/:id/nivel, GET /api/rutas, WebSocket del mapa
- **Metricas:** contenedores llenos, km recorridos, recolecciones por turno
- **Prueba de caos:** contenedor sin reportar mas de X horas: se marca sospechoso y entra a ruta de revision

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
