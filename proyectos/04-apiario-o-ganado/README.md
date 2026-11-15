# #4 — Apiario o ganado

**Dominio:** Agro e IoT

telemetria de colmenas o collares; muchos dispositivos y deteccion de "dejo de reportar".

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

- **Procesos:** un gen_server por dispositivo (colmena o collar); un detector de silencio con timers por dispositivo
- **Supervision:** supervisor dinamico (simple_one_for_one) que agrega dispositivos al registrarse
- **API / tiempo real:** POST /api/telemetria, GET /api/dispositivos, WebSocket de alertas de 'dejo de reportar'
- **Metricas:** dispositivos activos, mensajes por segundo, dispositivos silenciosos, bateria baja
- **Prueba de caos:** levantar 10 000 dispositivos simulados y medir memoria con recon:proc_count/2

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
