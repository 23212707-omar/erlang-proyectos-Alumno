# #80 — Cerveceria artesanal

**Dominio:** Agro y alimentos

lotes, fermentadores y etapas de produccion.

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

- **Procesos:** un gen_statem por lote (molienda, coccion, fermentacion, maduracion, envasado); gen_server de fermentadores con temperatura objetivo
- **Supervision:** supervisor por cerveceria; fermentadores dinamicos
- **API / tiempo real:** POST /api/lotes, POST /api/lotes/:id/avanzar, GET /api/fermentadores, SSE de temperatura
- **Metricas:** lotes por etapa, desviacion de temperatura, litros producidos
- **Prueba de caos:** falla del control de temperatura: el lote queda marcado 'en riesgo' y se notifica

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
