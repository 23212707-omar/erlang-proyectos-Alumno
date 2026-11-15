# #62 — Billetera virtual

**Dominio:** Comercio, finanzas y servicios

transferencias seguras, sin doble gasto.

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

- **Procesos:** un gen_server por cuenta (saldo); coordinador de transferencias (saga o dos fases); bitacora inmutable de movimientos
- **Supervision:** supervisor dinamico de cuentas; el coordinador con recuperacion de transferencias a medias
- **API / tiempo real:** POST /api/transferencias (con id de idempotencia), GET /api/cuentas/:id/movimientos
- **Metricas:** transferencias exitosas/fallidas, saldo total conservado, reintentos idempotentes
- **Prueba de caos:** matar el coordinador a mitad de una transferencia: dinero ni creado ni perdido

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
