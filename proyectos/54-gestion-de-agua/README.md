# #54 — Gestion de agua

**Dominio:** Energia y medio ambiente

fugas, presion y consumo por colonia.

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

- **Procesos:** un gen_server por medidor/sensor de presion; detector de fugas (consumo nocturno anomalo, caida de presion); agregador por colonia
- **Supervision:** supervisor por colonia/sector
- **API / tiempo real:** POST /api/sensores/:id/lectura, GET /api/colonias/:id/consumo, WebSocket de alertas de fuga
- **Metricas:** litros por colonia, fugas sospechadas, presion media
- **Prueba de caos:** simular una fuga (consumo constante de madrugada) y verificar la alerta

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
