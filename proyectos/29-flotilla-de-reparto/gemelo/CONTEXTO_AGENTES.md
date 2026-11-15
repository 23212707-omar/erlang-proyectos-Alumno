# Contexto para agentes — gemelo digital del proyecto #29 (Flotilla de reparto)

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
| Unidad | Vehículo de reparto con su conductor; tiene capacidad de peso y de volumen |
| Entrega | Paquete para un cliente en un punto del mapa, con una ventana; pasa por pendiente, en ruta, entregada o fallida |
| Asignada | Entrega que pertenece a una sola unidad en un orden de su ruta |
| Huérfana | Entrega pendiente que ninguna unidad tiene asignada |
| Duplicada | Entrega asignada a más de una unidad a la vez |
| Ventana | Intervalo en que el cliente espera la entrega («entre 2 y 4 pm») |
| Capacidad | Peso y volumen: caber en una medida no implica caber en la otra |
| Horas máximas de manejo | Tope de minutos al volante de un conductor |
| Tramo | Camino entre dos puntos del mapa, con tiempo base y tiempo con tráfico |
| Llegada estimada | Hora a la que se espera llegar a una parada; no la mide ningún dato |
| Reporte en lote | Lecturas de una unidad sin señal que llegan juntas, con la hora en que ocurrieron |
| Entrega fallida | Cliente ausente o dirección mala; el paquete sigue a bordo hasta reprogramarse |

Cifras de referencia, todas del problema original: 15 unidades y 900 entregas en el día;
avería a las 11 a. m. con 40 entregas pendientes; paradas de 2 a 5 minutos; entregas
fallidas de 5 a 15 %; GPS cada 10 s; una hora sin señal. El mapa, los tiempos de tramo,
pesos, volúmenes, capacidades, ventanas, el tope de manejo y la ventana de un reintento
son inventados por esta extensión.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  El tráfico, las averías y los silencios entran como hechos, no se sortean.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                          % minutos desde el inicio de la jornada
unidad(Unidad, CapPeso, CapVolumen).    % capacidad de peso y de volumen (escala del estudiante)
entrega(Entrega, Punto, Peso, Volumen). % paquete y punto del mapa al que va
ventana(Entrega, Desde, Hasta).         % ventana prometida al cliente, en minutos
tramo(Origen, Destino, MinutosBase).    % arista del mapa; tiempo sin tráfico
asignacion(Entrega, Unidad, Orden, Minuto). % asignación vigente y el instante en que se hizo
manejado(Unidad, Minutos).              % minutos al volante acumulados; el tope es del estudiante
rango(Variable, Minimo, Maximo).        % por ejemplo, minutos de una parada, velocidad, estado de motor
lectura(Unidad, Variable, Valor, Minuto). % posición, velocidad, motor; Minuto es cuando se midió
evento(Minuto, Tipo, Entidad, Detalle). % averia | silencio | reporte_lote | urgente | entregada | fallida | tramo_lento
```

## Contrato del gemelo

- `decide(+Entregas, -Plan, -Explicacion)` — predicado central. `Entregas` es la lista de
  entregas por (re)asignar (puede ser de una: el urgente, la fallida, las de una unidad
  averiada); `Plan` da a cada una su unidad y su lugar en la ruta, o «sin cubrir»;
  `Explicacion` justifica cada asignación y nombra a quién se le falla. Al pedir más
  soluciones debe dar los demás planes válidos. Si no existe ninguno (capacidad,
  ventana o recogida imposibles), lo dice y señala el motivo, sin fallar en silencio.
  Las asignaciones que no necesitaban cambiar no cambian.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre una entrega,
  una unidad o un tramo (por ejemplo huérfana, duplicada, en riesgo de perder su ventana,
  unidad en duda), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de unidades, entregas y tramos, el plan con su
  explicación, y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Avería.** Ninguna entrega pendiente de la unidad averiada queda huérfana ni
   duplicada. El plan respeta peso Y volumen, las ventanas ya prometidas y las horas
   máximas, y contempla que alguien recoja el paquete. Se obtienen todos los planes
   válidos; si no hay ninguno, el gemelo dice qué entregas quedan sin cubrir y por qué.
   Las asignaciones de las demás unidades que no hacía falta tocar no cambian.
2. **Urgente.** La explicación muestra, por unidad candidata, qué entregas posteriores
   retrasa el urgente y cuánto. La unidad más cercana no se elige por ese solo hecho. Si
   a alguien hay que fallarle, se nombra a quién, cuánto, y qué tendría que cambiar para
   no fallarle a nadie. La prioridad vive en un solo lugar: cambiarla ahí cambia los
   veredictos de todos los casos.
3. **Silencio.** Cada entrega de la unidad callada recibe «se entregó», «no se entregó»
   o «no se sabe»; no todas reciben el mismo veredicto. Lo dudoso nunca se trata como
   hecho. Al llegar el reporte en lote los veredictos se recalculan con las mismas reglas
   y el gemelo señala las entregas duplicadas o huérfanas por una decisión previa.
4. **Llegada.** La llegada estimada sale de encadenar tramos y paradas anteriores. Cada
   entrega recibe «llega en ventana», «llega tarde» o «depende de la duración de las
   paradas». Un tramo lento marca las entregas de todas las rutas que pasan por él, y la
   consulta inversa («¿qué rutas toca este tramo?») usa las mismas reglas. Se detecta al
   conductor que no alcanza a terminar dentro de sus horas.
5. **Fallida.** Un paquete fallido cuenta contra la capacidad de la unidad hasta que se
   entrega o se descarga. Una entrega con dirección mala es «no ubicable», no «sin
   unidad». Añadir una fallida cambia, con las mismas reglas, el veredicto de un urgente
   o de una reasignación que antes cabía.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el mapa con las unidades y
sus rutas, las entregas con su estado y su ventana, la carga de cada unidad en peso y en
volumen, las unidades en duda por silencio, el tramo lento y las rutas que toca, el plan
propuesto con su explicación y a quién se le falla, y la respuesta a «qué falta». Debe
verse bien en celular.
