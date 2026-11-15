# #41 — Signos vitales

**Dominio:** Salud

monitor de pacientes con alarmas.

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

- **Procesos:** un gen_server por paciente con lecturas de FC, SpO2, presion; evaluador de reglas de alarma con niveles
- **Supervision:** supervisor por unidad (UCI, piso); evaluador separado
- **API / tiempo real:** POST /api/pacientes/:id/signos, WebSocket de monitor central, GET /api/alarmas
- **Metricas:** alarmas activas por nivel, lecturas por segundo, dispositivos sin senal
- **Prueba de caos:** perder la senal de un paciente: alarma tecnica inmediata, nunca silencio

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
