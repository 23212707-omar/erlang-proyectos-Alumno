# Manual de uso — #70 Alumbrado público

*González Cristóbal Omar · 23212707 · Temas Selectos de Programación Concurrente · TecNM campus Tijuana*

Volver al [README](../README.md) · [Evidencias](../evidencias/README.md)

## 1. Propósito

Recibir reportes de fallas de luminarias, evitar duplicados, asignar cuadrillas y cerrar las reparaciones, con un mapa de fallas vigentes.

## 2. Instalación y ejecución en la Pi

Requisitos: Erlang/OTP 27 y rebar3 instalados con asdf (como en la práctica anterior).

```bash
. ~/.asdf/asdf.sh && export PATH=$HOME/bin:$PATH
git clone -b feat/p70-alumbrado-publico https://github.com/23212707-omar/erlang-proyectos-Alumno ~/erlang-proyectos-Alumno
cd ~/erlang-proyectos-Alumno/proyectos/70-alumbrado-publico
rebar3 compile
rebar3 eunit          # esperado: 39 tests, 0 failures
```

Arranque en segundo plano (puerto 8080):

```bash
setsid nohup rebar3 shell --name p70_alumbrado_publico@127.0.0.1 \
  > /tmp/p70.log 2>&1 < /dev/null &
```

## 3. Endpoints

| Método y ruta | Descripción | Respuesta |
|---|---|---|
| `POST /api/lamparas/:id/falla` | Reporta una falla. Cuerpo opcional: `{"prioridad":"alta\|media\|baja","fuente":"ciudadano\|telemetria"}` | 201 si abre una nueva, 200 si se agrupa, 400 si algo es inválido |
| `POST /api/reportes` | Reporta por dirección escrita a mano: `{"direccion":"Av. Revolución 1234","prioridad":"media","fuente":"ciudadano"}` | 201 o 200; 400 sin calle y número; 404 si no existe; 409 con `candidatas` si varias luminarias comparten la dirección |
| `GET /metrics` | Métricas en formato de texto de Prometheus | 200 `text/plain` |
| `GET /api/diagnostico` | Estado de la VM visto con recon | 200 con procesos, schedulers, memoria y los 5 procesos con más memoria y con más cola |
| `GET /api/mapa/fallas` | Lista las fallas vigentes | 200 con `{"fallas":[...]}` |
| `GET /api/fallas/:id` | Detalle de la falla de una luminaria (con reincidencias) | 200, o 404 |
| `PATCH /api/fallas/:id` | `{"accion":"asignar","cuadrilla":"cuadrilla_1"}` o `{"accion":"reparar"}` | 200, 404 o 409 si la transición no es válida |
| `GET /api/bitacora?limite=N` | Últimos eventos, el más reciente primero (N de 1 a 200) | 200 con `{"eventos":[...]}` |
| `GET /api/catalogo/resumen` | Totales del catálogo por sector | 200 |
| `GET /api/catalogo/puntos` | `[[id, lat, lon], ...]` de las 5,000 luminarias | 200 |
| `GET /api/catalogo/lamparas/:id` | Una luminaria del catálogo | 200, o 404 |
| `GET /api/cuadrillas/rutas` | Ruta de cada cuadrilla con fallas asignadas: paradas en orden de visita (luminaria, lat, lon, prioridad) y `distancia_km` | 200 |
| `GET /api/simulador` | Estado y contadores del simulador | 200 |
| `POST /api/simulador/iniciar` y `/detener` | Inicia o detiene el modo continuo (80 reportes por día simulado, un día = 1 minuto) | 200 |
| `POST /api/simulador/escenarios/poste` | 15 reportes sobre un poste. Cuerpo opcional `{"luminaria":"L-0777"}` | 200, o 404 si no está en el catálogo |
| `POST /api/simulador/escenarios/circuito` | Falla de un circuito completo: **una sola falla** con el id del circuito. Cuerpo opcional `{"circuito":"C-CEN-01"}` | 200, o 404 si no existe |
| `GET /` | Interfaz web (`priv/www`) | HTML |

El `POST /api/lamparas/:id/falla` valida la luminaria contra el catálogo: los ids van de `L-0001` a `L-5000` y cualquier otro responde **404**.

### 3.1 Interfaz web

Con el nodo corriendo, la interfaz está en `http://localhost:8080`. Si la Pi está detrás de un proxy (como en Corellium), se abre un túnel SSH desde la PC con `-L 8080:localhost:8080` y se entra por `localhost:8080`. Requiere internet en el navegador (Tailwind y fuentes desde CDN).

| Vista | Qué permite |
|---|---|
| Mapa y Fallas | Contadores por estado; tarjeta del simulador (iniciar, detener, 15 reportes en un poste, falla de circuito); mapa con las fallas por color (al tocar un punto se ve su dirección); filtros por estado y prioridad que también filtran el mapa; el mapa es real (Leaflet + OpenStreetMap); tarjeta de rutas de cuadrilla (paradas en orden y km) con líneas punteadas en el mapa; lista ordenada por urgencia (actualización cada 5 s) |
| Detalle | Ubicación con mini mapa, reportes agrupados por fuente, reincidencias, ciclo de vida y acciones (asignar, reparar) |
| Reportar | Formulario que acepta el ID de la luminaria o su dirección, con aviso de si el reporte creó una falla nueva, se agrupó o fue reincidencia (y qué dirección se reconoció) |
| Bitácora | Eventos reales con búsqueda por ID y filtros |

## 4. Ejemplo real (salida obtenida en la Pi)

```bash
curl -s localhost:8080/api/catalogo/resumen
# {"total":5000,"circuitos":128,"sectores":[...7 sectores...]}

curl -s localhost:8080/api/catalogo/lamparas/L-0001
# {"id":"L-0001","sector":"Zona Este","circuito":"C-EST-01","lat":32.51194,"lon":-116.87367,...}

curl -s -o /dev/null -w "%{http_code}\n" localhost:8080/api/catalogo/lamparas/L-9999
# 404

curl -s -X POST localhost:8080/api/lamparas/L-0001/falla -H 'content-type: application/json' -d '{"prioridad":"alta","fuente":"ciudadano"}'
# {"luminaria":"L-0001","resultado":"nueva"}

curl -s -X POST localhost:8080/api/lamparas/L-0001/falla -H 'content-type: application/json' -d '{"prioridad":"alta"}'
# {"luminaria":"L-0001","resultado":"agrupada"}

curl -s -X PATCH localhost:8080/api/fallas/L-0001 -H 'content-type: application/json' -d '{"accion":"asignar","cuadrilla":"cuadrilla_1"}'
# {"ok":true}

curl -s -X PATCH localhost:8080/api/fallas/L-0001 -H 'content-type: application/json' -d '{"accion":"reparar"}'
# {"ok":true}

curl -s localhost:8080/api/fallas/L-0001
# {"luminaria":"L-0001","estado":"reparada","prioridad":"alta","reportes":2,"fuentes":{...},"asignada_a":"cuadrilla_1",...,"sector":"Zona Este","lat":32.51194,"lon":-116.87367,"reincidencias":0}

curl -s 'localhost:8080/api/bitacora?limite=5'
# {"eventos":[{"id":3,"tipo":"asignada","luminaria":"L-0001",...}, ...]}
```

**Simulador y escenarios:**

```bash
curl -s -X POST localhost:8080/api/simulador/escenarios/poste -H 'content-type: application/json' -d '{}'
# L-0777: enviados 15, nuevas 1, agrupadas 14            (15 reportes -> 1 sola falla)

curl -s -X POST localhost:8080/api/simulador/escenarios/circuito -H 'content-type: application/json' -d '{}'
# C-CEN-01: luminarias 40, nuevas 1                      (una sola falla de circuito; repetirlo da nuevas 0, agrupadas 1)

curl -s localhost:8080/api/mapa/fallas | grep -o '"luminaria"' | wc -l
# 41

curl -s -X POST localhost:8080/api/simulador/iniciar -H 'content-type: application/json' -d '{}'
sleep 20
curl -s localhost:8080/api/simulador
# activo true, reportes 35, asignadas 35, reparadas 25   (los contadores avanzan solos)
curl -s -X POST localhost:8080/api/simulador/detener -H 'content-type: application/json' -d '{}'
```

### Prioridad por antigüedad (con el simulador detenido)

Se reporta una luminaria con prioridad baja y no se asigna. Cada 120 s abierta sube un nivel (baja → media → alta):

```
curl -s localhost:8080/api/fallas/L-0151
# a los 2 min: {"estado":"reportada","prioridad":"media","prioridad_base":"baja",...}
# a los 4 min: {"estado":"reportada","prioridad":"alta","prioridad_base":"baja",...}
```

En el detalle de la interfaz aparece "Prioridad base: baja. Subió por antigüedad".

### Rutas de cuadrilla (con el simulador en marcha)

```
curl -s localhost:8080/api/cuadrillas/rutas
# {"cuadrillas":[{"cuadrilla":"cuadrilla_1","distancia_km":20.82,
#   "paradas":[{"luminaria":"L-0192","prioridad":"alta","lat":32.514,"lon":-117.11394},
#              {"luminaria":"L-2427","prioridad":"media",...},{"luminaria":"L-4726","prioridad":"alta",...}]},
#  {"cuadrilla":"cuadrilla_2","distancia_km":12.77,"paradas":[...3...]}, ...]}
```

Cada cuadrilla visita primero su falla más urgente y después la más cercana.

### Duplicados con direcciones escritas distinto

La dirección de L-0002 en el catálogo es `Paseo de los Héroes #4929, Zona Río`. Se reporta tal cual y después escrita de otra forma:

```
curl -s -X POST localhost:8080/api/reportes -d '{"direccion":"Paseo de los Héroes #4929, Zona Río"}'
# {"luminaria":"L-0002","resultado":"nueva","direccion":"Paseo de los Héroes #4929, Zona Río"}
curl -s -X POST localhost:8080/api/reportes -d '{"direccion":"PASEO DE LOS HÉROES No.4929, ZONA RÍO"}'
# {"luminaria":"L-0002","resultado":"agrupada","direccion":"Paseo de los Héroes #4929, Zona Río"}
```

En la interfaz (vista Reportar) aparece "Se creó una falla nueva para L-0002" y después "El reporte se agrupó con la falla ya abierta de L-0002", con la dirección reconocida.

Otros resultados:

| Texto escrito | Respuesta |
|---|---|
| `Av. Revolución` (sin número) | 400: dirección inválida, se necesita calle y número |
| `Av. Inexistente 99999` | 404: dirección no encontrada en el catálogo |
| `Paseo de los Héroes #3848, Zona Centro` | 409: dirección ambigua, candidatas `L-0027` y `L-3432` |

Cuando dos postes comparten calle, número y sector, la API no adivina: devuelve las candidatas y el reporte se hace con el ID del poste correcto (por ejemplo `L-0027`, que abrió una falla nueva).

### Métricas y diagnóstico

Con una falla de circuito (40 luminarias), una falla en L-0100 y L-0101 ya reparada:

```
curl -s localhost:8080/metrics
```

Salida real (recortada):

```
# TYPE p70_lamparas_apagadas gauge
p70_lamparas_apagadas 41
# TYPE p70_fallas gauge
p70_fallas{estado="reportada"} 2
p70_fallas{estado="asignada"} 0
p70_fallas{estado="reparada"} 1
# TYPE p70_fallas_abiertas_por_sector gauge
p70_fallas_abiertas_por_sector{sector="Zona Centro"} 1
p70_fallas_abiertas_por_sector{sector="Zona Este"} 1
p70_fallas_abiertas_por_sector{sector="Zona Río"} 0
# TYPE p70_fallas_abiertas_por_prioridad gauge
p70_fallas_abiertas_por_prioridad{prioridad="alta"} 2
# TYPE p70_reparacion_segundos summary
p70_reparacion_segundos_sum 17
p70_reparacion_segundos_count 1
# TYPE p70_beam_procesos gauge
p70_beam_procesos 140
p70_beam_memoria_bytes{tipo="total"} 60143608
p70_beam_cola_mensajes_maxima 0
```

Se calculan al consultar, con lo que hay en el registro de fallas: la lámpara apagada de un circuito cuenta las 40 luminarias, y el tiempo de reparación solo incluye las fallas reparadas que siguen vigentes. Las siete zonas salen siempre, aunque estén en cero.

```
curl -s localhost:8080/api/diagnostico
```

Devuelve el número de procesos y schedulers, la memoria total y, con recon, los 5 procesos con más memoria y con más cola de mensajes. En la misma prueba los de más memoria fueron `p70_simulador` (unos 3.1 MB) y `p70_catalogo` (unos 2.9 MB), y la cola de mensajes de todos estaba en 0, es decir, sin nada atascado.

## 5. Detener el servicio

Con `setsid` o `nohup` el PID que devuelve el shell puede no ser el de la VM de Erlang. Se localiza con `ps` y se detiene con `kill`:

```bash
ps aux | grep beam
kill <PID>
```

## 6. Solución de problemas

| Síntoma | Causa probable | Solución |
|---|---|---|
| `rebar3: command not found` | El shell no cargó asdf | `. ~/.asdf/asdf.sh && export PATH=$HOME/bin:$PATH` |
| `curl` rechaza la conexión | El nodo no está arriba | Revisar `/tmp/p70.log` |
| Respuesta 400 | JSON inválido o prioridad desconocida | Usar `alta`, `media` o `baja` y JSON válido |
| Respuesta 409 en `PATCH` | Transición fuera de orden (por ejemplo reparar dos veces) | Seguir el orden reportada → asignada → reparada |
| Respuesta 404 en `PATCH` | No hay falla para esa luminaria | Reportarla primero con `POST` |
| Respuesta 404 en `POST .../falla` | La luminaria no está en el catálogo (ids `L-0001` a `L-5000`) | Usar un id válido, por ejemplo `L-0001` |
| El mapa muestra solo una nota de error | No cargó `/api/catalogo/puntos` | Revisar que el nodo esté arriba y recargar con Ctrl+Shift+R |
| La interfaz se ve sin estilos | El navegador no tiene internet (Tailwind y fuentes vienen de CDN) | Conectar el navegador a internet |
| El mapa se ve como dibujo simple, sin calles | Leaflet o las teselas de OpenStreetMap no cargaron; la interfaz usa el mapa SVG de respaldo | Conectar el navegador a internet y recargar con Ctrl+Shift+R |
| `localhost:8080` no abre desde la PC | Falta el túnel SSH hacia la Pi | Abrir el túnel con `-L 8080:localhost:8080` |

## Supuestos y cifras por verificar

- Las cifras del documento del problema se contrastaron con fuentes el 14 de noviembre de 2026 (tabla en el README, sección "Cifras del problema: qué se verificó"). La de 8 a 15 luminarias por cuadrilla al día no tiene fuente y es un supuesto. El simulador usa parámetros propios (80 reportes por día, 4 cuadrillas, 3 fallas por cuadrilla) y no pretende reflejar datos reales del municipio.
- El **catálogo es simulado**: 5,000 luminarias generadas con una función determinista alrededor de 7 sectores. No son datos reales del municipio y no siguen las calles.
- El **contorno del mapa (frontera y costa) es aproximado**, calibrado a mano con un mapa de la ciudad. No es cartografía oficial.
- La llave de agrupación sigue siendo el **id de luminaria**; las direcciones escritas a mano se convierten a id con `p70_direccion` (calle y número, con o sin sector). No corrige ortografía ni entiende calles con número ("Calle 10"), y solo conoce el catálogo simulado.
- La **falla de circuito** es una sola falla (id del circuito, con sus 40 luminarias afectadas, ubicada en su centro). No se enlaza con las fallas individuales de sus luminarias, que son independientes. En la interfaz, cada clic en "Falla de circuito" usa el siguiente sector; para repetir el mismo circuito (y ver el agrupado) se usa la API.
- La simulación usa números aleatorios (`rand`): los contadores del modo continuo cambian en cada corrida. Los escenarios y el catálogo sí son reproducibles.
- No hay persistencia: si el nodo se reinicia, se pierde el estado de las fallas y la bitácora (el catálogo se regenera igual).
- La **prioridad por antigüedad** sube un nivel cada 120 s abierta (con el simulador, 2 días simulados = 48 h, antes de la meta de 72 h). Los 120 s son un supuesto propio, elegido para que se vea en una demostración.
- Las **rutas de cuadrilla** usan la heurística del vecino más cercano: no son óptimas, y la primera parada siempre es la falla más urgente aunque esté lejos.
- La reincidencia sube la prioridad de la falla nueva un nivel (baja → media → alta), a partir de la mayor entre la prioridad de la falla anterior y la del reporte.