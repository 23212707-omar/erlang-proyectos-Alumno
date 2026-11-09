# #70 — Alumbrado público

**Dominio:** Seguridad y ciudad · Erlang/OTP 27 · cowboy 2.20

Sistema que consolida reportes ciudadanos y señales de telemetría de luminarias en **una sola falla por luminaria**, lleva cada falla desde que se reporta hasta que se repara y la muestra en una interfaz web.

## Autor

| Rol | Integrante |
|---|---|
| Backend, interfaz y operación | González Cristóbal Omar (23212707) |

## Estado

Avance funcional: backend, API e interfaz integrados, con 20 pruebas eunit en verde. Probado en una Raspberry Pi 4 virtual (Corellium, Debian 11, OTP 27). Lo pendiente está al final.

## Arranque

```bash
rebar3 compile
rebar3 eunit          # 20 tests, 0 failures
rebar3 shell          # API e interfaz en http://localhost:8080
```

Sin terminal interactiva (por ejemplo en un servidor):

```bash
nohup erl -noshell -pa _build/default/lib/*/ebin \
  -eval 'application:ensure_all_started(p70_alumbrado_publico), timer:sleep(infinity).' \
  > /tmp/p70.log 2>&1 &
```

El puerto se configura con `http_port` en `config/sys.config` (por defecto 8080).

## Diseño OTP

```
p70_alumbrado_publico_sup        (rest_for_one)
├── p70_alumbrado_publico_server (gen_server)
├── p70_falla_sup                (simple_one_for_one)
│   └── p70_falla × N            (gen_statem: reportada → asignada → reparada)
├── p70_registro                 (gen_server: una falla abierta por luminaria)
└── p70_bitacora                 (gen_server: últimos 200 eventos)

cowboy (p70_http) → p70_api_h    (un proceso por request)
```

- **Un proceso por falla:** cada una tiene su estado; si una muere, las demás siguen.
- **Hijos `temporary` en `p70_falla_sup`:** reiniciarlos los dejaría vacíos y perderían sus reportes; la recuperación del estado está pendiente.
- **`rest_for_one`:** `p70_registro` guarda los pids de `p70_falla_sup`, por eso va después y se reinicia con él.
- **Reporte tras reparar:** no reabre la falla; se abre una nueva y se cuenta como reincidencia.

## API

| Método y ruta | Descripción |
|---|---|
| `POST /api/lamparas/:id/falla` | Reporta una falla. Cuerpo opcional: `{"prioridad":"alta\|media\|baja","fuente":"ciudadano\|telemetria"}`. 201 si abre una nueva, 200 si se agrupa. |
| `GET /api/mapa/fallas` | Fallas vigentes (estado, prioridad, reportes, fuentes, cuadrilla, horas). |
| `GET /api/fallas/:id` | Detalle de la falla de una luminaria, con reincidencias. |
| `PATCH /api/fallas/:id` | `{"accion":"asignar","cuadrilla":"cuadrilla_1"}` o `{"accion":"reparar"}`. 409 si la transición no es válida. |
| `GET /api/bitacora?limite=N` | Últimos eventos, el más reciente primero (N de 1 a 200). |

## Interfaz

Diseñada en Google Stitch (`design/`) e integrada en `priv/www` (`index.html` y `app.js`, sin dependencias de compilación). Cuatro vistas: mapa y fallas, detalle, reportar y bitácora. Carga Tailwind y las fuentes desde internet.

## Estructura

| Ruta | Contenido |
|---|---|
| `src/` | Aplicación OTP, fallas, registro, bitácora y API |
| `test/` | Pruebas eunit (fallas, registro, bitácora y API con `httpc`) |
| `priv/www/` | Interfaz web |
| `design/` | Exportación de Google Stitch y su `DESIGN.md` |
| `problema/` | Enunciado del problema |
| `config/` | `sys.config` y `vm.args` |

## Pendiente

- [x] Diseñar pantallas en Stitch (`design/`)
- [x] Modelar el dominio (proceso por falla, supervisores)
- [x] Endpoints `/api/...` con cowboy
- [x] Prueba de caos básica (matar una falla y verificar que el resto sobrevive)
- [ ] Catálogo de luminarias (dirección, sector y coordenadas) y mapa geográfico
- [ ] Simulación del escenario: 5,000 luminarias, 80 reportes al día, 4 cuadrillas, circuito de 40
- [ ] Prioridad por criticidad y antigüedad; reincidencia sube a prioridad alta
- [ ] Falla de circuito frente a 40 fallas independientes
- [ ] Normalización de direcciones para duplicados
- [ ] Persistencia (ETS o PostgreSQL) y WebSocket o SSE
- [ ] Métricas `/metrics` con prometheus.erl y diagnóstico con recon
- [ ] Release con relx + systemd
- [ ] Prueba de caos documentada y verificación de cifras del problema