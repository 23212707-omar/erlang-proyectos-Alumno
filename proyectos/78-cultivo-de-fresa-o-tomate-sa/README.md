# #78 — Cultivo de fresa o tomate (San Quintin)

**Dominio:** Agro y alimentos

cosecha, cuadrillas y trazabilidad.

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

- **Procesos:** gen_server por parcela/surco; cuadrillas como procesos con asignacion y captura de cajas cosechadas; trazabilidad por lote
- **Supervision:** supervisor por rancho; cuadrillas dinamicas
- **API / tiempo real:** POST /api/cosechas, GET /api/trazabilidad/:lote, WebSocket del avance por surco
- **Metricas:** cajas por cuadrilla/hora, avance por parcela, lotes trazables
- **Prueba de caos:** captura duplicada de la misma caja (QR): se rechaza y no duplica el conteo

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
