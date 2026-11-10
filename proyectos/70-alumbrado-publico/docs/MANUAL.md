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
rebar3 eunit          # esperado: 34 tests, 0 failures
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
| `GET /api/mapa/fallas` | Lista las fallas vigentes | 200 con `{"fallas":[...]}` |
| `GET /api/fallas/:id` | Detalle de la falla de una luminaria (con reincidencias) | 200, o 404 |
| `PATCH /api/fallas/:id` | `{"accion":"asignar","cuadrilla":"cuadrilla_1"}` o `{"accion":"reparar"}` | 200, 404 o 409 si la transición no es válida |
| `GET /api/bitacora?limite=N` | Últimos eventos, el más reciente primero (N de 1 a 200) | 200 con `{"eventos":[...]}` |
| `GET /api/catalogo/resumen` | Totales del catálogo por sector | 200 |
| `GET /api/catalogo/puntos` | `[[id, lat, lon], ...]` de las 5,000 luminarias | 200 |
| `GET /api/catalogo/lamparas/:id` | Una luminaria del catálogo | 200, o 404 |
| `GET /api/simulador` | Estado y contadores del simulador | 200 |
| `POST /api/simulador/iniciar` y `/detener` | Inicia o detiene el modo continuo (80 reportes por día simulado, un día = 1 minuto) | 200 |
| `POST /api/simulador/escenarios/poste` | 15 reportes sobre un poste. Cuerpo opcional `{"luminaria":"L-0777"}` | 200, o 404 si no está en el catálogo |
| `POST /api/simulador/escenarios/circuito` | Falla de un circuito completo. Cuerpo opcional `{"circuito":"C-CEN-01"}` | 200, o 404 si no existe |
| `GET /` | Interfaz web (`priv/www`) | HTML |

El `POST /api/lamparas/:id/falla` valida la luminaria contra el catálogo: los ids van de `L-0001` a `L-5000` y cualquier otro responde **404**.

### 3.1 Interfaz web

Con el nodo corriendo, la interfaz está en `http://localhost:8080`. Si la Pi está detrás de un proxy (como en Corellium), se abre un túnel SSH desde la PC con `-L 8080:localhost:8080` y se entra por `localhost:8080`. Requiere internet en el navegador (Tailwind y fuentes desde CDN).

| Vista | Qué permite |
|---|---|
| Mapa y Fallas | Contadores por estado; tarjeta del simulador (iniciar, detener, 15 reportes en un poste, falla de circuito); mapa con las fallas por color (al tocar un punto se ve su dirección); filtros por estado y prioridad que también filtran el mapa; lista ordenada por urgencia (actualización cada 5 s) |
| Detalle | Ubicación con mini mapa, reportes agrupados por fuente, reincidencias, ciclo de vida y acciones (asignar, reparar) |
| Reportar | Formulario con aviso de si el reporte creó una falla nueva, se agrupó o fue reincidencia |
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
# C-CEN-01: luminarias 40, nuevas 40                     (hoy: 40 fallas independientes)

curl -s localhost:8080/api/mapa/fallas | grep -o '"luminaria"' | wc -l
# 41

curl -s -X POST localhost:8080/api/simulador/iniciar -H 'content-type: application/json' -d '{}'
sleep 20
curl -s localhost:8080/api/simulador
# activo true, reportes 35, asignadas 35, reparadas 25   (los contadores avanzan solos)
curl -s -X POST localhost:8080/api/simulador/detener -H 'content-type: application/json' -d '{}'
```

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
| `localhost:8080` no abre desde la PC | Falta el túnel SSH hacia la Pi | Abrir el túnel con `-L 8080:localhost:8080` |

## Supuestos y cifras por verificar

- Las cifras del documento del problema (consumo sodio frente a LED, 8–15 luminarias por cuadrilla al día, meta de 72 h) **no se verificaron contra fuentes externas**; el simulador usa parámetros propios (80 reportes por día, 4 cuadrillas, 3 fallas por cuadrilla) y no pretende reflejar datos reales del municipio.
- El **catálogo es simulado**: 5,000 luminarias generadas con una función determinista alrededor de 7 sectores. No son datos reales del municipio y no siguen las calles.
- El **contorno del mapa (frontera y costa) es aproximado**, calibrado a mano con un mapa de la ciudad. No es cartografía oficial.
- Por ahora la llave de agrupación es el **id de luminaria**. Los reportes ciudadanos con direcciones escritas distinto necesitarán una normalización de dirección a id de luminaria (pendiente).
- La **falla de circuito** abre hoy 40 fallas independientes (una por luminaria); juntarlas en una sola falla de circuito está pendiente.
- La simulación usa números aleatorios (`rand`): los contadores del modo continuo cambian en cada corrida. Los escenarios y el catálogo sí son reproducibles.
- No hay persistencia: si el nodo se reinicia, se pierde el estado de las fallas y la bitácora (el catálogo se regenera igual).
- La reincidencia aún no sube la prioridad automáticamente; la nueva falla toma la prioridad que indica el reporte.