# #39 — Sala de urgencias

**Dominio:** Salud

triage, cola por prioridad y tiempos de atencion.

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

- **Procesos:** gen_server de triage con cola por prioridad (5 niveles); gen_statem por paciente (en_espera, en_atencion, alta); gen_server de consultorios
- **Supervision:** rest_for_one: consultorios, luego triage, luego pacientes
- **API / tiempo real:** POST /api/pacientes (ingreso), GET /api/cola, WebSocket del tablero de sala de espera
- **Metricas:** tiempo de espera por prioridad, pacientes en atencion, ocupacion de consultorios
- **Prueba de caos:** llega una emergencia nivel 1 con la cola llena: pasa al frente sin perder a nadie

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
