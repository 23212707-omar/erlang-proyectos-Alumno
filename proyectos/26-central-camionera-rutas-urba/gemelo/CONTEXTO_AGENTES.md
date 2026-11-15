# Contexto para agentes — gemelo digital del proyecto #26 (Central camionera / rutas urbanas)

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
| Parada | Punto donde una ruta recoge o deja pasajeros; algunas son de trasbordo |
| Tramo | Segmento entre dos paradas consecutivas; varias rutas pueden compartirlo |
| Ruta | Secuencia de paradas; urbana o foránea (Ensenada, Mexicali) |
| Unidad | Camión o autobús con GPS; pertenece a una ruta, que puede cambiar a mitad del viaje |
| Lectura | Posición GPS con su instante; tiene error y puede faltar o saltar |
| Progreso | Qué tanto ha avanzado una unidad en su ruta; lo defines tú, no se mide |
| ETA | Llegada estimada a una parada; siempre se deduce, nunca es un hecho puro |
| Detenida | Unidad cuyas lecturas no cambian más allá del error del GPS por un tiempo |
| Bunching | Varias unidades de una ruta viajan juntas y dejan un hueco largo detrás |
| Trasbordo | Cambio de ruta en una parada donde se cruzan dos rutas, o en la central |
| Andén | Lugar de la central donde una unidad sube o baja pasajeros; limitado |
| Inferencia | Valor deducido de otros, nunca presentado como lectura |

Cifras de referencia, todas del problema original: reporte GPS cada 10 s con error de
5 a 15 m; velocidad urbana de 15 a 20 km/h en hora pico; una unidad detenida 15 min por
avería; escenario completo de 30 unidades, 6 rutas y 12 andenes. Inventados por esta
extensión, no datos reales: la red de 3 rutas y 8 paradas, las 6 unidades urbanas, los 2
foráneos, los 4 andenes, los boletos y quién va a bordo, y todos los nombres.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Las lecturas con ruido y los bloqueos entran como hechos, no se sortean.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundo).                          % segundos desde el inicio de la jornada
ruta(Ruta, Tipo, Paradas).               % Tipo: urbana | foranea; Paradas: lista en orden
tramo(Desde, Hasta, Metros).             % arista de la red; varias rutas lo pueden compartir
rango(Variable, Minimo, Maximo).         % por ejemplo, error del GPS, velocidad en hora pico
unidad(Unidad, Ruta, Tipo).              % Tipo: urbano | foraneo
lectura(Unidad, Tramo, Metros, Segundo). % posicion GPS: tramo y metros recorridos en el
horario(Unidad, Parada, Segundo).        % hora programada de paso, llegada o salida
anden(Anden).
ocupa(Anden, Unidad, Desde, Hasta).      % ocupacion vigente o reservada, en segundos
boleto(Persona, Unidad).                 % boleto de un servicio foraneo
a_bordo(Persona, Unidad).                % quien viaja en que unidad
evento(Segundo, Tipo, Entidad, Detalle). % sin_reporte | detenida | bloqueo | despeje |
                                         % cambio_ruta | solicitud_anden | salida
```

## Contrato del gemelo

- `decide(+Solicitudes, -Plan, -Explicacion)` — predicado central. `Solicitudes` es la
  lista de lo que se pide (una ruta para un pasajero, un andén para una unidad, una
  decisión de espera; puede ser una sola); `Plan` es el resultado completo (itinerario con
  trasbordos y llegada, reparto de andenes o decisión de esperar); `Explicacion` justifica
  cada paso con los hechos que lo sustentan y la base de cada llegada. Al pedir más
  soluciones debe dar las demás alternativas válidas. Si no existe ninguna (parada
  aislada por el bloqueo, andenes insuficientes, ciclo de dependencias) lo dice y señala
  el motivo, sin fallar en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre una unidad,
  un tramo, una ruta o un trasbordo (por ejemplo detenida, ruta afectada por un bloqueo,
  unidades en bola, trasbordo en riesgo), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de cada unidad con la base de su llegada, la ruta
  alterna con su explicación, la asignación de andenes, y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Unidades creíbles.** Una unidad detenida (lecturas sin cambio dentro del error del
   GPS) no se cuenta como la próxima en llegar aunque sea la más cercana. Una unidad sin
   reportar queda como «no lo sé», distinto de «fuera de servicio» y de «avanza». Una
   lectura imposible se descarta con su razón; ninguna ETA de unidad sin base sale como
   medida.
2. **Bloqueo y red.** Con un tramo bloqueado, el gemelo lista las rutas y paradas que
   dependen de él, incluidas las indirectas, y todas las alternativas con trasbordo. Si
   ninguna llega, lo dice con el motivo. La consulta inversa dice qué tendría que
   despejarse para que la ruta directa vuelva a ser viable.
3. **Andén.** Con horas reales, un reparto que solo era válido con las programadas deja
   de serlo. Si no cabe todo, el gemelo señala quién se queda sin andén y por qué; con
   más soluciones devuelve los demás repartos.
4. **Trasbordo contra andén.** Con la llegada del urbano sin buena base, el trasbordo es
   «en duda», no «perdido». Las dos opciones nombran a quién se le falla. Esperar no es
   siempre la mejor aunque lo parezca, y la explicación recorre la cadena que lo causa.
5. **Ruta y bunching.** En un tramo compartido, la unidad queda «en duda» entre dos rutas;
   tras pasar por un tramo exclusivo, la ruta se resuelve y las paradas de la otra dejan
   de contarla. Dos unidades en bola de una misma ruta no cuentan como dos llegadas
   independientes y el hueco se señala.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar un mapa esquemático de la
red con las unidades y su estado (avanza, detenida, sin dato, en duda de ruta), la llegada
a cada parada con su base y su edad, los bloqueos, los andenes con sus ocupaciones, las
alternativas de ruta con trasbordos y la respuesta a «qué falta». Debe verse bien en
celular y distinguir con color y texto entre lectura e inferencia.
