# #70 — Alumbrado público

**Dominio:** Seguridad y ciudad · Erlang/OTP 27 · cowboy 2.20

Sistema que consolida reportes ciudadanos y señales de telemetría de luminarias en **una sola falla por luminaria**, lleva cada falla desde que se reporta hasta que se repara y la muestra en una interfaz web.

## Autor

| Rol | Integrante |
|---|---|
| Backend, interfaz y operación | González Cristóbal Omar (23212707) |

## Estado

Avance funcional: backend, API, interfaz con mapa y simulador de reportes integrados, con 34 pruebas eunit en verde. Probado en una Raspberry Pi 4 virtual (Corellium, Debian 11, OTP 27). Los datos son **simulados** (catálogo de 5,000 luminarias y contorno de la ciudad aproximado, no son datos reales del municipio). Lo pendiente está al final.

## Arranque

```bash
rebar3 compile
rebar3 eunit          # 34 tests, 0 failures
rebar3 shell          # API e interfaz en http://localhost:8080
```

Sin terminal interactiva (por ejemplo en un servidor):

```bash
setsid nohup rebar3 shell --name p70_alumbrado_publico@127.0.0.1 \
  > /tmp/p70.log 2>&1 < /dev/null &
ps aux | grep beam      # para localizar el PID real y detenerlo con kill
```

El puerto se configura con `http_port` en `config/sys.config` (por defecto 8080).

## Diseño OTP

```
p70_alumbrado_publico_sup        (rest_for_one)
├── p70_alumbrado_publico_server (gen_server)
├── p70_falla_sup                (simple_one_for_one)
│   └── p70_falla × N            (gen_statem: reportada → asignada → reparada)
├── p70_registro                 (gen_server: una falla abierta por luminaria)
├── p70_bitacora                 (gen_server: últimos 200 eventos)
├── p70_catalogo                 (gen_server dueño de una tabla ETS: 5,000 luminarias simuladas)
└── p70_simulador                (gen_server: reportes, cuadrillas y escenarios de la demo)

cowboy (p70_http) → p70_api_h    (un proceso por request)
```

- **Un proceso por falla:** cada una tiene su estado; si una muere, las demás siguen.
- **Hijos `temporary` en `p70_falla_sup`:** reiniciarlos los dejaría vacíos y perderían sus reportes; la recuperación del estado está pendiente.
- **`rest_for_one`:** `p70_registro` guarda los pids de `p70_falla_sup`, por eso va después y se reinicia con él.
- **Reporte tras reparar:** no reabre la falla; se abre una nueva y se cuenta como reincidencia.
- **Catálogo en ETS:** se genera de forma determinista (`erlang:phash2`), así que siempre salen las mismas 5,000 luminarias. Las lecturas van directo a la tabla, sin pasar por el proceso. Va al final del árbol, junto con la bitácora y el simulador, para que su caída no reinicie las fallas.
- **Contorno aproximado:** las coordenadas se mantienen al sur de la frontera y al este de la costa (valores aproximados, calibrados con un mapa de la ciudad).
- **Simulador:** 80 reportes por día simulado (un día = 1 minuto), 4 cuadrillas con hasta 3 fallas cada una, las más urgentes primero. Los escenarios (15 reportes en un poste, circuito de 40) se ejecutan bajo demanda.

## API

| Método y ruta | Descripción |
|---|---|
| `POST /api/lamparas/:id/falla` | Reporta una falla. Cuerpo opcional: `{"prioridad":"alta\|media\|baja","fuente":"ciudadano\|telemetria"}`. 201 si abre una nueva, 200 si se agrupa. |
| `GET /api/mapa/fallas` | Fallas vigentes (estado, prioridad, reportes, fuentes, cuadrilla, horas). |
| `GET /api/fallas/:id` | Detalle de la falla de una luminaria, con reincidencias. |
| `PATCH /api/fallas/:id` | `{"accion":"asignar","cuadrilla":"cuadrilla_1"}` o `{"accion":"reparar"}`. 409 si la transición no es válida. |
| `GET /api/bitacora?limite=N` | Últimos eventos, el más reciente primero (N de 1 a 200). |
| `GET /api/catalogo/resumen` | Totales del catálogo simulado por sector. |
| `GET /api/catalogo/puntos` | `[[id, lat, lon], ...]` de las 5,000 luminarias. |
| `GET /api/catalogo/lamparas/:id` | Una luminaria del catálogo (sector, dirección, coordenadas, circuito, lugar). 404 si no existe. |
| `GET /api/simulador` | Estado y contadores del simulador. |
| `POST /api/simulador/iniciar` · `/detener` | Inicia o detiene el modo continuo. |
| `POST /api/simulador/escenarios/poste` | 15 reportes sobre un mismo poste (cuerpo opcional `{"luminaria":"L-0777"}`). Resultado: 1 falla nueva y 14 agrupadas. |
| `POST /api/simulador/escenarios/circuito` | Falla de todas las luminarias de un circuito (cuerpo opcional `{"circuito":"C-CEN-01"}`): 40 fallas. |

`POST /api/lamparas/:id/falla` valida la luminaria contra el catálogo: los ids van de `L-0001` a `L-5000` y cualquier otro responde 404.

## Interfaz

Diseñada en Google Stitch (`design/`) e integrada en `priv/www` (`index.html` y `app.js`, sin dependencias de compilación). Cuatro vistas: mapa y fallas, detalle, reportar y bitácora. En Mapa y Fallas hay un mapa SVG con las 5,000 luminarias, el océano, la frontera y los sectores, con las fallas encima (rojo reportada, ámbar asignada, azul reparada), y una tarjeta del simulador. El detalle muestra la ubicación con un mini mapa. Carga Tailwind y las fuentes desde internet.

## Estructura

| Ruta | Contenido |
|---|---|
| `src/` | Aplicación OTP, fallas, registro, bitácora, catálogo, simulador y API |
| `test/` | Pruebas eunit (fallas, registro, bitácora, catálogo, simulador y API con `httpc`) |
| `priv/www/` | Interfaz web |
| `design/` | Exportación de Google Stitch y su `DESIGN.md` |
| `problema/` | Enunciado del problema |
| `config/` | `sys.config` y `vm.args` |

## Pendiente

- [x] Diseñar pantallas en Stitch (`design/`)
- [x] Modelar el dominio (proceso por falla, supervisores)
- [x] Endpoints `/api/...` con cowboy
- [x] Prueba de caos básica (matar una falla y verificar que el resto sobrevive)
- [x] Catálogo simulado de luminarias (dirección, sector y coordenadas) y mapa en la interfaz
- [x] Simulación del escenario: 5,000 luminarias, 80 reportes al día, 4 cuadrillas, 15 reportes sobre un poste y circuito de 40
- [ ] Falla de circuito frente a 40 fallas independientes (hoy se abren 40 fallas, una por luminaria)
- [ ] Prioridad por criticidad y antigüedad; reincidencia sube a prioridad alta
- [ ] Capacidad diaria de las cuadrillas (8 a 15 luminarias) y meta de atención
- [ ] Normalización de direcciones para duplicados
- [ ] Persistencia (ETS o PostgreSQL) y WebSocket o SSE
- [ ] Métricas `/metrics` con prometheus.erl y diagnóstico con recon
- [ ] Release con relx + systemd
- [ ] Prueba de caos documentada y verificación de cifras del problema