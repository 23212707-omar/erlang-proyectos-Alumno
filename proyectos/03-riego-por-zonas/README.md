# #3 — Riego por zonas

**Dominio:** Agro e IoT

programador de valvulas con colas y prioridades; recupera estado tras un corte de luz.

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

- **Procesos:** gen_server programador con cola por prioridad; un gen_statem por valvula (cerrada, abriendo, abierta, fallo)
- **Supervision:** supervisor de valvulas one_for_one; programador aparte para que sobreviva a fallos de una valvula
- **API / tiempo real:** GET/POST /api/programas, GET /api/valvulas, WebSocket con el estado de cada zona
- **Metricas:** litros por zona, programas ejecutados, programas atrasados, valvulas en fallo
- **Prueba de caos:** matar el programador en pleno riego y verificar que recupera el estado persistido (disco/ETS+dets) tras el reinicio

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
