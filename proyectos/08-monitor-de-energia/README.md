# #8 — Monitor de energia

**Dominio:** Ciudad y edificios

medidores con consumo, alarmas por umbral y agregacion por piso.

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

- **Procesos:** un gen_server por medidor; agregador por piso con ETS; evaluador de umbrales que dispara alarmas
- **Supervision:** supervisor por edificio/piso (one_for_one); el agregador depende de la ETS (rest_for_one)
- **API / tiempo real:** POST /api/medidores/:id/lectura, GET /api/pisos/:id/consumo, WebSocket de alarmas
- **Metricas:** kW por piso, picos, alarmas activas, medidores sin reportar
- **Prueba de caos:** matar el agregador de un piso y verificar que los demas pisos siguen reportando

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
