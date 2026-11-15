# Contexto para agentes — gemelo digital del proyecto #30 (Bicicletas o scooters compartidos)

Este archivo es para el agente (OpenCode u otro) que acompaña al estudiante. Léelo
completo, junto con [`PROBLEMA.md`](PROBLEMA.md) y
[`../problema/readme.md`](../problema/readme.md), antes de proponer cualquier cosa.

## Tu papel

- El proyecto es individual y se califica el razonamiento del estudiante. **Explica,
  pregunta y propone; no entregues la solución completa.**
- Antes de escribir una regla, pide al estudiante que la diga en español.
- Primero la prueba plunit, después la regla.
- Trabaja una situación a la vez, en el orden de `PROBLEMA.md`.
- No inventes cifras. Las de `PROBLEMA.md` vienen del problema original; cualquier otra
  se marca como supuesto y se le pide al estudiante la fuente.

## Dominio

| Término | Significado |
|---|---|
| Estación y anclaje | Punto con anclajes donde se toma o se devuelve una unidad; reporta bicicletas disponibles y anclajes libres |
| Marea | Flujo asimétrico de una zona según la franja del día: se vacía por la tarde o se llena por la mañana |
| Rebalanceo | Mover bicicletas en camión de estaciones que sobran a estaciones que faltan |
| Camión de rebalanceo | Transporta de 20 a 40 bicicletas; su ruta consume tiempo y dinero |
| Estación en riesgo | Estación que se quedará sin bicicletas o sin anclajes; no la mide ningún dato |
| Viaje | Desbloqueo, uso y cierre de una unidad; se cobra por desbloqueo y por minuto |
| Viaje fantasma y cobro doble | Viaje abierto sin usuario real, u orden repetida que se cobra dos veces |
| Reintento de red | La misma orden enviada otra vez; no es otro usuario |
| Zona permitida | Área donde puede quedar un scooter sin dock |
| Batería | El scooter dura de 3 a 6 horas de uso; luego hay que recogerlo y cargarlo |
| Estación callada | Estación que dejó de comunicar; su último reporte es viejo |

Cifras de referencia, todas del problema original: camión de 20 a 40 bicicletas; scooter
de 3 a 6 horas de uso; predicción a 30 minutos; una hora sin comunicación; 40
estaciones, 400 bicicletas y 1,000 viajes al día. Las 8 estaciones, las zonas, los
anclajes, los tiempos de tramo, las franjas, la batería de cada unidad y la zona permitida
son inventados por esta extensión.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar viajes simulados o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Los viajes, las órdenes repetidas y las fallas de red entran como hechos, no se sortean.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                          % minutos desde el inicio de la ventana de prueba
estacion(Estacion, Zona, Anclajes).     % Anclajes: capacidad total (inventada)
tramo(Origen, Destino, Minutos).        % red por la que circulan los camiones
unidad(Unidad, Tipo).                   % Tipo: bicicleta | scooter
camion(Camion, Capacidad, Ubicacion).   % Capacidad: bicicletas que carga
marea(Zona, Inicio, Fin, Sentido).      % Sentido: sale | llega, en una franja de minutos
zona_permitida(Zona).                   % donde puede quedar un scooter
rango(Variable, Minimo, Maximo).        % por ejemplo, batería o bicicletas por estación
lectura(Entidad, Variable, Valor, Minuto). % bicis_disponibles, anclajes_libres, bateria, posicion
evento(Minuto, Tipo, Entidad, Detalle). % desbloqueo | cierre | ancla | silencio | mantenimiento
```

## Contrato del gemelo

- `decide(+Solicitudes, -Plan, -Explicacion)` — predicado central. `Solicitudes` es la
  lista de lo que se pide resolver (órdenes de desbloqueo, estaciones por atender o
  viajes por cerrar; puede ser de una). `Plan` es el reparto completo: quién recibe cada
  unidad, qué camión va a qué estación con cuántas bicicletas y en qué orden, o el cierre
  de cada viaje. `Explicacion` justifica cada asignación y nombra a quién se le falla. Al
  pedir más soluciones debe dar los demás planes válidos. Si no existe ninguno (camión
  insuficiente, sin anclajes libres, sin unidad libre), lo dice y señala el motivo, sin
  fallar en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre una
  estación, una unidad, un viaje o un camión (por ejemplo estación en riesgo, camión que
  llega tarde, viaje terminado, scooter probablemente abandonado), consultables en
  cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de estaciones, unidades y camiones, el plan con su
  explicación, y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Estaciones en riesgo.** El riesgo sale de cruzar el estado actual, la marea de la
   zona y el horizonte de 30 minutos, no de un solo número. Para cada estación en riesgo
   la evidencia dice si un camión llega antes o después, y qué camión. Si ninguno llega a
   tiempo, el gemelo lo dice y da el motivo.
2. **Un camión, dos estaciones.** El plan respeta la capacidad del camión y los anclajes
   libres del destino, y no saca bicicletas de una estación que la marea vaciará. La
   explicación nombra la estación a la que se le falla y por qué; se obtienen todos los
   planes válidos. Si no existe ninguno, lo dice y señala el recurso que falta.
3. **Última bicicleta.** Una unidad en mantenimiento no cuenta como disponible aunque el
   anclaje la muestre. El reintento del mismo usuario no abre un segundo viaje ni un
   segundo cobro; dos usuarios distintos no reciben la misma unidad. A quien queda fuera
   se le ofrece una estación vecina con unidad libre, y la explicación dice por qué.
4. **Viaje abierto.** Si un anclaje confirma la bicicleta, el viaje se da por terminado
   en ese instante y no se cobra tiempo posterior. Si no hay evidencia suficiente, la
   respuesta es «no se sabe», distinta de «sigue abierto», y nombra la inspección que la
   resolvería. Un scooter sin reportar, con batería y posición dudosas, no se da por
   abandonado sin que la evidencia lo sustente.
5. **Estación callada.** Sin reporte reciente, la respuesta no es «vacía» ni «igual que
   antes» sino un rango marcado como inferencia, con los hechos que lo sustentan. La
   decisión de mandar o no un camión nombra qué otra estación pierde el servicio. La
   hipótesis «vuelve la comunicación» cambia el veredicto con las mismas reglas.
6. **Las cinco preguntas** de «Por qué no basta un script» se contestan con consultas
   sobre las mismas reglas, sin predicados duplicados por pregunta.

## Verificación

```bash
swipl -g run_tests -t halt tests/reglas_tests.pl   # pruebas plunit
swipl servidor.pl                                   # arranca el gemelo y su interfaz
```

Nombres de archivo sugeridos: `hechos.pl`, `reglas.pl`, `servidor.pl`,
`tests/reglas_tests.pl`, `web/`. No afirmes que algo pasa si no lo ejecutaste.

## Interfaz

Se diseña en Google Stitch antes de programarla. Debe mostrar el mapa o la lista de las
8 estaciones con su ocupación y su riesgo, los camiones y su ruta propuesta, las órdenes
de desbloqueo en disputa y quién recibe la unidad, los viajes abiertos con su cierre
deducido, los scooters con su batería y su zona, la estación callada marcada como
inferencia, la explicación de cada decisión con a quién se le falla, y la respuesta a
«qué falta». Debe verse bien en celular.
