# #70 — Alumbrado público

**Dominio:** Seguridad y ciudad · Erlang/OTP 27 · cowboy 2.20

Sistema que consolida reportes ciudadanos y señales de telemetría de luminarias en **una sola falla por luminaria**, lleva cada falla desde que se reporta hasta que se repara y la muestra en una interfaz web.

## Autor

| Rol | Integrante |
|---|---|
| Backend, interfaz y operación | González Cristóbal Omar (23212707) |

## Estado

**Entrega de la presentación DEMO (9 de noviembre de 2026).** Backend, API, interfaz con mapa y simulador de reportes integrados, con 34 pruebas eunit en verde. Probado en una Raspberry Pi 4 virtual (Corellium, Debian 11, OTP 27). Los datos son **simulados** (catálogo de 5,000 luminarias y contorno de la ciudad aproximado; no son datos reales del municipio).

| Qué | Dónde |
|---|---|
| Video de la demo (sin voz) | [Loom](https://www.loom.com/share/7e4e065c5a2d4c8fa7ebc59dfeba7b6c) |
| Manual de uso | [`docs/MANUAL.md`](docs/MANUAL.md) |
| Evidencias (capturas) | [`evidencias/`](evidencias/README.md) |
| Diseño de la interfaz | [`design/`](design/) |

## Arranque

```bash
rebar3 compile
rebar3 eunit          # 35 tests, 0 failures
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
- **Reporte tras reparar:** no reabre la falla; se abre una nueva, se cuenta como reincidencia y sube un nivel de prioridad (baja → media → alta), a partir de la mayor entre la de la falla anterior y la del reporte.
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

Diseñada en Google Stitch (`design/`) e integrada en `priv/www` (`index.html` y `app.js`, sin dependencias de compilación). Cuatro vistas: mapa y fallas, detalle, reportar y bitácora. En Mapa y Fallas hay un mapa real de Tijuana (Leaflet con teselas de OpenStreetMap; si no hay internet se usa un mapa SVG de respaldo) con las 5,000 luminarias y las fallas encima (rojo reportada, ámbar asignada, azul reparada), y una tarjeta del simulador. El detalle muestra la ubicación con un mini mapa. Carga Tailwind, las fuentes, Leaflet y las teselas del mapa desde internet.

## Estructura

| Ruta | Contenido |
|---|---|
| `src/` | Aplicación OTP, fallas, registro, bitácora, catálogo, simulador y API |
| `test/` | Pruebas eunit (fallas, registro, bitácora, catálogo, simulador y API con `httpc`) |
| `priv/www/` | Interfaz web |
| `design/` | Exportación de Google Stitch y su `DESIGN.md` |
| `problema/` | Enunciado del problema |
| `config/` | `sys.config` y `vm.args` |

## Limitaciones conocidas

- **Datos simulados.** Las 5,000 luminarias se generan con una función determinista alrededor de 7 sectores; no son datos reales y no siguen las calles. El contorno del mapa (frontera y costa) es aproximado, calibrado a mano.
- **Falla de circuito.** Hoy un circuito caído abre 40 fallas independientes (una por luminaria); juntarlas en una sola falla de circuito no está implementado.
- **Sin persistencia.** Si el nodo se reinicia se pierde el estado de las fallas y la bitácora (el catálogo se regenera igual). Los hijos de `p70_falla_sup` son `temporary` por esa razón.
- **Duplicados por dirección.** La llave de agrupación es el id de luminaria; no hay normalización de direcciones escritas distinto.
- **Cifras del problema** (consumo, capacidad de cuadrillas, metas de atención) sin verificar contra fuentes.
- El simulador usa números aleatorios: sus contadores cambian en cada corrida.

## Trabajo futuro

- Falla de circuito como una sola falla, frente a 40 fallas independientes.
- Prioridad por criticidad y antigüedad.
- Capacidad diaria de las cuadrillas (8 a 15 luminarias) y meta de atención.
- Normalización de direcciones para duplicados.
- Persistencia (ETS o PostgreSQL) y WebSocket o SSE en lugar del refresco cada 5 s.
- Métricas `/metrics` con prometheus.erl y diagnóstico con recon.
- Release con relx y servicio systemd.
- Prueba de caos documentada y verificación de las cifras del problema.

## Uso de IA

Un asistente de IA ayudó a planear y redactar los prompts y el código base de cada paso. Cada prompt se revisó antes de enviarlo a OpenCode (modelo GLM-5.3-Flash Free, flujo Plan y luego Build), cada comando se aprobó uno por uno y los resultados se verificaron con la salida real de `rebar3 eunit` y `curl` en la Pi.