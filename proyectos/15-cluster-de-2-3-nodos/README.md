# #15 — Cluster de 2-3 nodos

**Dominio:** Sistemas distribuidos

replicacion de estado, `net_kernel` y failover.

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

- **Procesos:** gen_server de estado replicado entre nodos; monitor de nodos con net_kernel:monitor_nodes/1; coordinador de failover
- **Supervision:** un arbol identico en cada nodo; el monitor se reengancha al volver un nodo
- **API / tiempo real:** GET /api/cluster (nodos y rol), POST /api/estado (replica a los demas), SSE de cambios de topologia
- **Metricas:** nodos conectados, latencia de replicacion, cambios de lider
- **Prueba de caos:** desconectar un nodo, escribir estado, reconectarlo y verificar que converge

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
