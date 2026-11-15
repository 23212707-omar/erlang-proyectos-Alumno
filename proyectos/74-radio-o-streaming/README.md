# #74 — Radio o streaming

**Dominio:** Entretenimiento y juegos

lista de reproduccion colaborativa con votos.

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

- **Procesos:** gen_server de cola de reproduccion; votos por pista; gen_statem de reproductor (sonando, pausa, siguiente); un proceso por oyente conectado
- **Supervision:** one_for_one; oyentes aislados
- **API / tiempo real:** POST /api/pistas, POST /api/pistas/:id/voto, WebSocket de estado de reproduccion
- **Metricas:** oyentes, votos, pistas en cola, saltos
- **Prueba de caos:** votos masivos simultaneos: el orden de la cola es consistente

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
