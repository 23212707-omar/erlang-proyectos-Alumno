# #48 — Biblioteca

**Dominio:** Educacion y campus

prestamos, multas y reservas.

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

- **Procesos:** gen_server de catalogo; gen_statem por prestamo (activo, vencido, devuelto); gen_server de reservas con cola por libro; calculador de multas
- **Supervision:** one_for_one; multas independientes
- **API / tiempo real:** GET /api/libros?q=, POST /api/prestamos, POST /api/reservas
- **Metricas:** prestamos activos, vencidos, multas generadas
- **Prueba de caos:** dos usuarios piden el ultimo ejemplar: uno presta, el otro entra a cola de reserva

## Extension

- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)
