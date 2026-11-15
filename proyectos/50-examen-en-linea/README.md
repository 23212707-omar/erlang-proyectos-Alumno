# #50 — Examen en linea

**Dominio:** Educacion y campus

temporizador por alumno, tolerante a reconexion.

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

- **Procesos:** un gen_statem por alumno-examen (no_iniciado, en_curso, pausado_por_desconexion, entregado) con temporizador propio; gen_server de banco de preguntas
- **Supervision:** supervisor dinamico de intentos
- **API / tiempo real:** POST /api/examenes/:id/iniciar, PUT /api/intentos/:id/respuesta, WebSocket de tiempo restante
- **Metricas:** examenes en curso, desconexiones, envios al limite de tiempo
- **Prueba de caos:** matar el proceso de un alumno a mitad de examen: reanuda con el tiempo correcto y sin perder respuestas

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
