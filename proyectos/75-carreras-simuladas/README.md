# #75 — Carreras simuladas

**Dominio:** Entretenimiento y juegos

pilotos como procesos con eventos y apuestas ficticias.

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

- **Procesos:** un proceso por piloto (velocidad, posicion, desgaste); gen_statem de carrera (parrilla, en_curso, bandera, final); gen_server de eventos aleatorios
- **Supervision:** rest_for_one: pista primero, pilotos despues
- **API / tiempo real:** POST /api/carreras, WebSocket de posiciones en vivo, GET /api/resultados
- **Metricas:** vueltas, adelantamientos, abandonos, tiempo por vuelta
- **Prueba de caos:** un piloto crashea: la carrera sigue y se reordena la clasificacion

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
