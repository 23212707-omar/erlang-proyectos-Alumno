# #79 — Acuacultura (atun, ostion)

**Dominio:** Agro y alimentos

oxigeno, temperatura y alimentacion de jaulas.

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

- **Procesos:** un gen_server por jaula (oxigeno, temperatura, salinidad); controlador de alimentacion programado; gen_statem de alarma
- **Supervision:** supervisor por granja; controlador aparte de los sensores
- **API / tiempo real:** POST /api/jaulas/:id/lectura, POST /api/jaulas/:id/alimentar, WebSocket de alertas
- **Metricas:** oxigeno disuelto, mortalidad estimada, alimento suministrado
- **Prueba de caos:** caida de oxigeno: alarma critica y activacion de aireacion de respaldo

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
