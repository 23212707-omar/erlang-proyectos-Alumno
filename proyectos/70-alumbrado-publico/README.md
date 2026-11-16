# #70 — Alumbrado público

**Dominio:** Seguridad y ciudad · Erlang/OTP 27 · cowboy 2.20

Sistema que consolida reportes ciudadanos y señales de telemetría de luminarias en **una sola falla por luminaria**, lleva cada falla desde que se reporta hasta que se repara y la muestra en una interfaz web.

## Autor

| Rol | Integrante |
|---|---|
| Backend, interfaz y operación | González Cristóbal Omar (23212707) |

## Estado

**Entrega de la presentación DEMO (9 de noviembre de 2026).** Backend, API, interfaz con mapa y simulador de reportes integrados, con 34 pruebas eunit en verde. **Actualización del 15 de noviembre:** se agregaron prioridad por antigüedad, rutas de cuadrilla por cercanía, falla de circuito única, reincidencia que sube la prioridad, mapa real y reconocimiento de direcciones escritas distinto para agrupar duplicados; ahora son 49 pruebas en verde, con métricas `/metrics` y diagnóstico con recon. Probado en una Raspberry Pi 4 virtual (Corellium, Debian 11, OTP 27). Los datos son **simulados** (catálogo de 5,000 luminarias y contorno de la ciudad aproximado; no son datos reales del municipio).

| Qué | Dónde |
|---|---|
| Video de la demo (sin voz) | [Loom](https://www.loom.com/share/7e4e065c5a2d4c8fa7ebc59dfeba7b6c) |
| Manual de uso | [`docs/MANUAL.md`](docs/MANUAL.md) |
| Evidencias (capturas) | [`evidencias/`](evidencias/README.md) |
| Diseño de la interfaz | [`design/`](design/) |

## Arranque

```bash
rebar3 compile
rebar3 eunit          # 49 tests, 0 failures
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
p70_rutas                        (módulo sin procesos: distancias y rutas de cuadrilla)
p70_direccion                    (módulo sin procesos: normaliza direcciones escritas a mano)
p70_metricas                     (módulo sin procesos: métricas Prometheus y diagnóstico con recon)
```

- **Un proceso por falla:** cada una tiene su estado; si una muere, las demás siguen.
- **Hijos `temporary` en `p70_falla_sup`:** reiniciarlos los dejaría vacíos y perderían sus reportes; la recuperación del estado está pendiente.
- **`rest_for_one`:** `p70_registro` guarda los pids de `p70_falla_sup`, por eso va después y se reinicia con él.
- **Reporte tras reparar:** no reabre la falla; se abre una nueva, se cuenta como reincidencia y sube un nivel de prioridad (baja → media → alta), a partir de la mayor entre la de la falla anterior y la del reporte.
- **Catálogo en ETS:** se genera de forma determinista (`erlang:phash2`), así que siempre salen las mismas 5,000 luminarias. Las lecturas van directo a la tabla, sin pasar por el proceso. Va al final del árbol, junto con la bitácora y el simulador, para que su caída no reinicie las fallas.
- **Prioridad por criticidad y antigüedad:** la base depende del tipo de lugar (avenida, cruce escolar y hospital: alta; calle: media; andador: baja) y la reincidencia la sube un nivel. Además, una falla abierta sube un nivel por cada 120 s (2 días simulados, 48 h, antes de la meta de 72 h) hasta alta; al repararse deja de envejecer. El despacho y la interfaz usan la prioridad efectiva, y la API devuelve también `prioridad_base`. Así se equilibra la criticidad del lugar con la antigüedad: un andador olvidado acaba rebasando a una calle reciente.
- **Rutas de cuadrilla:** `p70_rutas` es un módulo puro (sin proceso, porque no tiene estado). El simulador asigna cada falla a la cuadrilla con lugar que ya tiene trabajo más cercano (una cuadrilla vacía cuenta como distancia 0, así las cuatro empiezan antes de agrupar), y cada ruta empieza por su falla más urgente y sigue por la más cercana (vecino más cercano, distancia haversine). Es una heurística: no resuelve el problema del agente viajero.
- **Duplicados por dirección:** `p70_direccion` (módulo puro) reduce un texto como `AVENIDA REVOLUCIÓN No. 1234, Col. Centro` a una clave `{calle, número}` más las palabras del sector: quita acentos, mayúsculas, puntuación, el tipo de vía (av, blvd, calle, paseo) y palabras de relleno. La clave se busca en un índice del catálogo (se arma una vez y se guarda en `persistent_term`). Con la luminaria resuelta, el reporte sigue el flujo normal y se agrupa con la falla abierta. Si dos postes comparten la dirección, la API responde 409 con las candidatas en vez de adivinar.
- **Métricas y diagnóstico:** `p70_metricas` (módulo puro) arma `GET /metrics` en el formato de texto de Prometheus, sin dependencias nuevas: lámparas apagadas (una falla de circuito cuenta sus 40 luminarias), fallas por estado, por sector y por prioridad efectiva, la falla abierta más antigua, el resumen del tiempo de reparación y datos de la VM (procesos, memoria, cola de mensajes más larga). `GET /api/diagnostico` usa recon para listar los procesos con más memoria y con más cola. Se calculan al consultar, leyendo el registro de fallas.
- **Contorno aproximado:** las coordenadas se mantienen al sur de la frontera y al este de la costa (valores aproximados, calibrados con un mapa de la ciudad).
- **Simulador:** 80 reportes por día simulado (un día = 1 minuto), 4 cuadrillas con hasta 3 fallas cada una, las más urgentes primero. Los escenarios (15 reportes en un poste, circuito caído de 40 luminarias) se ejecutan bajo demanda.

## API

| Método y ruta | Descripción |
|---|---|
| `POST /api/lamparas/:id/falla` | Reporta una falla. Cuerpo opcional: `{"prioridad":"alta\|media\|baja","fuente":"ciudadano\|telemetria"}`. 201 si abre una nueva, 200 si se agrupa. |
| `GET /metrics` | Métricas en formato de texto de Prometheus (lámparas apagadas, fallas por estado, sector y prioridad, tiempo de reparación, VM). |
| `GET /api/diagnostico` | Estado de la VM visto con recon: procesos, schedulers, memoria y los 5 procesos con más memoria y con más cola de mensajes. |
| `POST /api/reportes` | Reporta por dirección escrita a mano: `{"direccion":"Av. Revolución 1234","prioridad":...,"fuente":...}`. La normaliza y busca la luminaria; 201 o 200 como el reporte por id, 400 si faltan calle y número, 404 si no existe, 409 con `candidatas` si varias luminarias comparten la dirección. |
| `GET /api/mapa/fallas` | Fallas vigentes (estado, prioridad, reportes, fuentes, cuadrilla, horas). |
| `GET /api/cuadrillas/rutas` | Ruta de cada cuadrilla con fallas asignadas: paradas en orden de visita (luminaria, lat, lon, prioridad) y `distancia_km`. |
| `GET /api/fallas/:id` | Detalle de la falla de una luminaria, con reincidencias. |
| `PATCH /api/fallas/:id` | `{"accion":"asignar","cuadrilla":"cuadrilla_1"}` o `{"accion":"reparar"}`. 409 si la transición no es válida. |
| `GET /api/bitacora?limite=N` | Últimos eventos, el más reciente primero (N de 1 a 200). |
| `GET /api/catalogo/resumen` | Totales del catálogo simulado por sector. |
| `GET /api/catalogo/puntos` | `[[id, lat, lon], ...]` de las 5,000 luminarias. |
| `GET /api/catalogo/lamparas/:id` | Una luminaria del catálogo (sector, dirección, coordenadas, circuito, lugar). 404 si no existe. |
| `GET /api/simulador` | Estado y contadores del simulador. |
| `POST /api/simulador/iniciar` · `/detener` | Inicia o detiene el modo continuo. |
| `POST /api/simulador/escenarios/poste` | 15 reportes sobre un mismo poste (cuerpo opcional `{"luminaria":"L-0777"}`). Resultado: 1 falla nueva y 14 agrupadas. |
| `POST /api/simulador/escenarios/circuito` | Falla de un circuito completo (cuerpo opcional `{"circuito":"C-CEN-01"}`): **una sola falla** con el id del circuito y `afectadas` = 40, ubicada en el centro de sus luminarias. Si el circuito ya tiene una falla abierta, el reporte se agrupa. 404 si no existe. |

`POST /api/lamparas/:id/falla` valida la luminaria contra el catálogo: los ids van de `L-0001` a `L-5000` y cualquier otro responde 404.

## Interfaz

Diseñada en Google Stitch (`design/`) e integrada en `priv/www` (`index.html` y `app.js`, sin dependencias de compilación). Cuatro vistas: mapa y fallas, detalle, reportar y bitácora. En Mapa y Fallas hay un mapa real de Tijuana (Leaflet con teselas de OpenStreetMap; si no hay internet se usa un mapa SVG de respaldo) con las 5,000 luminarias y las fallas encima (rojo reportada, ámbar asignada, azul reparada), una tarjeta del simulador y una tarjeta de rutas de cuadrilla (en el mapa, líneas punteadas de un color por cuadrilla). El detalle muestra la ubicación con un mini mapa. Carga Tailwind, las fuentes, Leaflet y las teselas del mapa desde internet.

## Estructura

| Ruta | Contenido |
|---|---|
| `src/` | Aplicación OTP, fallas, registro, bitácora, catálogo, simulador, rutas y API |
| `test/` | Pruebas eunit (fallas, registro, bitácora, catálogo, simulador y API con `httpc`) |
| `priv/www/` | Interfaz web |
| `deploy/` | Unidad de systemd del servicio |
| `design/` | Exportación de Google Stitch y su `DESIGN.md` |
| `problema/` | Enunciado del problema |
| `config/` | `sys.config` y `vm.args` |

## Cifras del problema: qué se verificó

Verificación hecha el 14 de noviembre de 2026. Las cifras del documento del problema son órdenes de magnitud; esto es lo que sí se pudo contrastar con fuentes y lo que no.

| Cifra del documento | Resultado | Fuente |
|---|---|---|
| Sodio de 100 a 250 W | **Confirmada** como potencia de lámpara de vapor de sodio de alta presión (con balasto el consumo real es algo mayor) | [movilidadelectrica.com](https://movilidadelectrica.com/vapores-y-halogenuros-frente-a-led-en-alumbrado-publico), [ULPGC](https://accedacris.ulpgc.es/bitstream/10553/116773/1/Ahorro%20energ%c3%a9tico%20en%20instalaciones%20de%20iluminaci%c3%b3n.pdf) |
| LED consume 50 a 60 % menos | **Parcial**: un fabricante declara 52 % menos frente al sodio de alta presión; otro autor señala que la ventaja depende del caso | [eseficiencia.es](https://www.eseficiencia.es/2021/09/20/ledvance-lanza-nueva-familia-lamparas-osram-nav-led-alumbrado-publico), [energias-renovables.com](https://www.energias-renovables.com/eficiencia/el-uso-de-luminarias-led-reduciria-en) |
| LED dura 50,000 h o más (≈ 12 años a 12 h diarias) | **Confirmada**: las fichas comerciales declaran 50,000 h a L70; 50,000 h ÷ (12 h × 365) ≈ 11.4 años | [Philips](https://images.philips.com/is/content/PhilipsConsumer/PDFDownloads/Chile/ODLI20180109_001_UPD_es_CL_OUTDOOR_CHILE_2017_DIGITAL_FINAL_4.pdf), [Construex](https://construex.com.mx/exhibidores/alumbrado_publico/producto/campana_flat_industrial) |
| Decenas de miles de luminarias en Tijuana | **Confirmada**: unas 77 mil, con más de dos terceras partes ya en LED en 2024 | [El Imparcial](https://www.elimparcial.com/tij/tijuana/2024/08/26/moderniza-tijuana-68-del-sistema-de-alumbrado/), [Zeta](https://zetatijuana.com/2023/02/calles-y-colonias-de-tijuana-a-oscuras-mas-de-50-mil-luminarias-requieren-modernizarse/) |
| Meta de atención de 72 h | **Es razonable, pero varía**: Cali y Chihuahua usan 72 h como plazo máximo; Guadalajara reporta 48 h de promedio; León da 5 días hábiles a un circuito apagado | [Cali](https://www.cali.gov.co/serviciospublicos/publicaciones/166647/conozca-la-nueva-pagina-para-reportar-danos-en-el-alumbrado-publico/), [Chihuahua](https://www.tiempo.com.mx/local/chihuahua-invitan-reportar-fallas-alumbrado-publico-marca-cambio/), [Guadalajara](https://elcongresista.mx/politica/jalisco/disminuye-60-fallas-de-alumbrado-publico-en-guadalajara), [León](https://leon.gob.mx/modulos/img/documentos/obrapublica/mantenimiento%20integral/Alumbrado%20p%C3%BAblico/PR-DGOP-DMI-01%20Alumbrado%20p%C3%BAblico%20(SVD).pdf) |
| Causas de falla: robo de cable, golpes a postes | **Consistente**: el Ayuntamiento de Tijuana atribuye las fallas sobre todo a vandalismo, daños al cableado y accidentes vehiculares | [El Imparcial (2026)](https://www.elimparcial.com/tij/tijuana/2026/07/16/vandalismo-y-danos-en-cableado-provocan-la-mayoria-de-las-fallas-en-luminarias-de-tijuana-sdtua/) |
| Una cuadrilla repara de 8 a 15 luminarias al día | **No se encontró fuente.** Se usa como supuesto propio | — |
| El pago a la CFE depende de lo medido o estimado | **No verificada en detalle**; solo se confirmó que el derecho de alumbrado público se cobra en el recibo de la CFE | [Zeta](https://zetatijuana.com/2023/02/calles-y-colonias-de-tijuana-a-oscuras-mas-de-50-mil-luminarias-requieren-modernizarse/) |

**Supuestos propios.** Se simulan 5,000 luminarias (una escala de la ciudad, que tiene unas 77 mil), 80 reportes por día simulado, 4 cuadrillas y un máximo de 3 fallas asignadas a la vez por cuadrilla. Un día simulado dura un minuto. La prioridad depende del tipo de lugar y la reincidencia sube un nivel.

## Despliegue como servicio

El proyecto trae un release de `relx` (`rebar.config`: aplicación, `sasl` y `recon`, con `config/vm.args` y `config/sys.config`) y una unidad de systemd en [`deploy/p70-alumbrado.service`](deploy/p70-alumbrado.service). Se armó y probó en la Raspberry Pi 4 virtual:

```bash
rebar3 release        # arma _build/default/rel/p70_alumbrado_publico
rebar3 tar            # tarball de unos 19 MB, incluye su propia VM (erts)
```

El tarball se extrae en `/opt/p70_alumbrado_publico` y el servicio corre con el usuario `pi` (`Type=simple`, `foreground`, `Restart=on-failure`, `LimitNOFILE=65536`). Los pasos están en el [manual](docs/MANUAL.md#instalación-como-servicio-systemd). Resultado en la Pi: el servicio queda `active (running)` y habilitado, `ping` responde `pong`, la API devuelve las 5,000 luminarias y `/metrics` responde. Si se mata la VM con `SIGKILL`, systemd la levanta sola (el PID cambió de 1906 a 2209) y la API vuelve a responder en menos de 8 segundos.

La cookie de `config/vm.args` del repositorio es un valor de ejemplo (`cambiar_en_produccion`); en la copia instalada se sustituye por una aleatoria que no se guarda en el repositorio.

## Prueba de caos

Se grabó con asciinema en la Raspberry Pi 4 virtual: [ver la grabación](https://asciinema.org/a/W83DW4wpUhF5mrbH) (respaldo en `evidencias/caos.cast`; la captura 12 es de una primera prueba, que corresponde al escenario 1): un nodo corriendo con el catálogo de 5,000 luminarias, tres procesos matados con `exit(Pid, kill)` desde el shell de Erlang y las respuestas de la API comprobadas con `curl`. La estrategia del supervisor raíz es `rest_for_one`; el orden de arranque es servidor, `p70_falla_sup`, `p70_registro`, `p70_bitacora`, `p70_catalogo` y `p70_simulador`.

| # | Qué se mató | Qué se esperaba | Qué ocurrió |
|---|---|---|---|
| 1 | La falla de L-0100 (proceso `p70_falla`, hijo `temporary` de `p70_falla_sup`) | La falla de L-0101 sigue viva; el registro olvida la muerta; un nuevo reporte abre otra falla | El supervisor registró `child_terminated, reason: killed` y no la revivió. `is_process_alive` de la otra falla dio `true`; `GET /api/fallas/L-0100` devolvió "falla no encontrada"; el siguiente reporte dio `nueva` |
| 2 | `p70_falla_sup` (supervisor de todas las fallas) | Se reinicia junto con lo que depende de él; se pierden las fallas en curso; el sistema sigue atendiendo | El supervisor raíz reinició `p70_falla_sup` y `p70_registro` con pids nuevos, además de bitácora, catálogo (regenerado) y simulador, porque van después en la lista. `GET /api/mapa/fallas` devolvió `{"fallas":[]}` y el siguiente reporte de L-0100 dio `nueva` |
| 3 | `p70_catalogo` (dueño de la tabla ETS) | La tabla se regenera igual; las fallas abiertas no se tocan porque el registro va antes en el árbol | Se reiniciaron solo `p70_catalogo` y `p70_simulador`. El resumen devolvió `total: 5000` (128 circuitos) y L-0200 siguió en estado `reportada` con su reporte |

Conclusiones:
- Una falla individual puede morir sin afectar a las demás: es la razón de usar un proceso por falla y de que los hijos sean `temporary` (una falla muerta se reemplaza con el siguiente reporte, no se revive con un estado viejo).
- Matar `p70_falla_sup` es el caso más caro: se pierden las fallas en curso y la bitácora, porque no hay persistencia. El sistema se recupera solo y sigue atendiendo, pero ese estado no vuelve (ver limitaciones).
- A nivel de sistema operativo, matar la VM completa con `SIGKILL` bajo systemd (ver "Despliegue como servicio") la levanta de nuevo con otro PID y sin intervención. Eso se comprobó con el servicio instalado y no forma parte de la grabación.
- El orden del árbol cumple su propósito: el catálogo y el simulador pueden fallar sin tocar las fallas en curso.
- Los escenarios del documento del problema se cubren con tests y simulador: 15 reportes del mismo poste se agrupan en una sola falla (`escenarios/poste`), y reportar la misma luminaria escrita distinto también (`POST /api/reportes`).

## Limitaciones conocidas

- **Datos simulados.** Las 5,000 luminarias se generan con una función determinista alrededor de 7 sectores; no son datos reales y no siguen las calles. El contorno del mapa (frontera y costa) es aproximado, calibrado a mano.
- **Falla de circuito.** Es una falla única (id del circuito) y no desglosa las luminarias; no se enlaza con las fallas individuales de sus postes, que son independientes.
- **Sin persistencia.** Si el nodo se reinicia se pierde el estado de las fallas y la bitácora (el catálogo se regenera igual). Los hijos de `p70_falla_sup` son `temporary` por esa razón.
- **Rutas heurísticas.** El vecino más cercano no es óptimo: una cuadrilla puede recorrer distancias largas porque su primera parada es la falla más urgente aunque esté lejos. No se considera el tráfico ni la base de la cuadrilla.
- **Duplicados por dirección.** Se reconoce calle y número, con o sin sector, tolerando abreviaturas, acentos y mayúsculas. No corrige errores de ortografía, no entiende calles escritas con número ("Calle 10") ni geocodifica direcciones que no estén en el catálogo simulado.
- **Métricas calculadas al consultar.** No hay contadores históricos: el tiempo de reparación solo incluye las fallas reparadas que siguen siendo la vigente de su luminaria (se pierden al reiniciar el nodo o al llegar otro reporte de esa luminaria), y las métricas no se guardan entre consultas. Las tomaría un Prometheus que consulte `/metrics`; aquí no hay uno configurado.
- **Cifras del problema.** Verificadas en su mayoría (ver la sección anterior); la capacidad de 8 a 15 luminarias por cuadrilla al día no tiene fuente y es un supuesto.
- El simulador usa números aleatorios: sus contadores cambian en cada corrida.

## Trabajo futuro

- Enlazar la falla de circuito con las fallas individuales de sus luminarias.
- Capacidad diaria de las cuadrillas (8 a 15 luminarias) y meta de atención.
- Persistencia (ETS o PostgreSQL) y WebSocket o SSE en lugar del refresco cada 5 s.
- Contadores históricos (reparaciones totales, reincidencias) y exportarlos con prometheus.erl, con un Prometheus real consultando `/metrics`.

## Uso de IA

Un asistente de IA ayudó a planear y redactar los prompts y el código base de cada paso. Cada prompt se revisó antes de enviarlo a OpenCode (modelo GLM-5.3-Flash Free, flujo Plan y luego Build), cada comando se aprobó uno por uno y los resultados se verificaron con la salida real de `rebar3 eunit` y `curl` en la Pi.