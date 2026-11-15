# #46 — Asistencia por QR

**Dominio:** Educacion y campus

pase de lista en tiempo real.

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

- **Procesos:** gen_server por sesion de clase con codigo QR rotativo; registro de asistencia en ETS/DB; proceso que rota el QR cada N segundos
- **Supervision:** supervisor dinamico por sesion
- **API / tiempo real:** GET /api/sesiones/:id/qr, POST /api/asistencia (token), WebSocket del pase de lista en vivo
- **Metricas:** asistentes por sesion, QR invalidos, escaneos duplicados
- **Prueba de caos:** reusar un QR vencido o compartido por foto: debe rechazarse

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
