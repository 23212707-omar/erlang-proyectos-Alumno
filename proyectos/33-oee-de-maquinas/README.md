# #33 — OEE de maquinas

**Dominio:** Industria y manufactura

disponibilidad, rendimiento y calidad en tiempo real.

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

- **Procesos:** un gen_server por maquina que acumula tiempos (operando/parada) y piezas buenas/malas; calculador OEE periodico
- **Supervision:** supervisor por area de planta
- **API / tiempo real:** POST /api/maquinas/:id/evento, GET /api/oee?turno=, WebSocket del tablero
- **Metricas:** disponibilidad, rendimiento, calidad y OEE por maquina y turno
- **Prueba de caos:** reiniciar una maquina a mitad de turno sin perder el acumulado

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
