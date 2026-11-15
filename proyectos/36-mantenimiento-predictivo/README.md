# #36 — Mantenimiento predictivo

**Dominio:** Industria y manufactura

vibracion y temperatura simuladas con alertas de falla.

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

- **Procesos:** un gen_server por maquina con ventana de vibracion/temperatura; detector de anomalias (media movil + umbral); gen_statem de salud (normal, advertencia, falla_inminente)
- **Supervision:** supervisor por linea; el detector reiniciable sin perder la ventana (ETS)
- **API / tiempo real:** POST /api/maquinas/:id/lectura, GET /api/maquinas/:id/salud, WebSocket de alertas
- **Metricas:** anomalias detectadas, falsos positivos, tiempo a falla estimado
- **Prueba de caos:** inyectar una senal con deriva creciente y verificar que pasa a advertencia antes de falla

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
