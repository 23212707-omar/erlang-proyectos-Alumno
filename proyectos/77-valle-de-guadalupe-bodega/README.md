# #77 — Valle de Guadalupe, bodega

**Dominio:** Agro y alimentos

fermentacion por tanque, temperatura y fases.

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

- **Procesos:** un gen_statem por tanque (llenado, fermentando, reposo, trasiego); gen_server de sensores de temperatura/densidad; alertas de desviacion
- **Supervision:** supervisor por bodega; tanques dinamicos
- **API / tiempo real:** POST /api/tanques/:id/lectura, POST /api/tanques/:id/fase, GET /api/bodega, SSE de alertas
- **Metricas:** temperatura y densidad por tanque, dias de fermentacion, desviaciones
- **Prueba de caos:** sensor de un tanque falla en pleno pico de fermentacion: alerta y modo manual

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
