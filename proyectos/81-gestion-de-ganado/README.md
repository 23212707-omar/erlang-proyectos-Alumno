# #81 — Gestion de ganado

**Dominio:** Agro y alimentos

salud, pesaje y rutas de pastoreo.

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

- **Procesos:** un gen_server por animal (peso, salud, ubicacion); gen_server por potrero/ruta de pastoreo; alertas sanitarias por reglas
- **Supervision:** supervisor por rancho; animales dinamicos
- **API / tiempo real:** POST /api/animales/:id/pesaje, GET /api/animales?potrero=, WebSocket de alertas
- **Metricas:** ganancia diaria de peso, animales en tratamiento, ocupacion de potreros
- **Prueba de caos:** movimiento masivo de animales entre potreros: los conteos siguen consistentes

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
