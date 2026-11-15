# #16 — Broker MQTT simple

**Dominio:** Sistemas distribuidos

pub/sub con un proceso por conexion.

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

- **Procesos:** un proceso por conexion TCP (ranch); gen_server de topicos con suscripciones; manejo de QoS 0/1
- **Supervision:** ranch supervisa conexiones; el router de topicos aparte y reiniciable
- **API / tiempo real:** puerto 1883 (protocolo MQTT basico: CONNECT, PUBLISH, SUBSCRIBE), GET /api/topicos para el dashboard
- **Metricas:** clientes conectados, mensajes publicados/entregados, topicos activos
- **Prueba de caos:** 1000 suscriptores y un publicador; matar el router y verificar re-suscripcion

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
