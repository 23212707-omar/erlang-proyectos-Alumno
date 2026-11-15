# Contexto para agentes — gemelo digital del proyecto #9 (Semáforos o cruceros)

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
| Crucero | Intersección semaforizada; unidad sobre la que se decide |
| Aproximación | Entrada al crucero desde una dirección; tiene carriles |
| Movimiento | Lo que hace un vehículo al cruzar (de frente, vuelta a la izquierda) |
| Fase | Conjunto de movimientos que reciben verde al mismo tiempo |
| Movimientos conflictivos | Pares cuyas trayectorias se cruzan; no pueden tener verde a la vez |
| Amarillo y todo rojo | Cambio y despeje que separan fases conflictivas |
| Ciclo | Tiempo en que se atienden todas las fases una vez |
| Flujo de saturación | Vehículos por hora por carril que pasan durante el verde |
| Despeje peatonal | Tiempo que un peatón necesita para terminar de cruzar |
| *Conflict monitor* | Hardware que fuerza destellos rojos si ve verdes conflictivos |
| Preferencia | Solicitud de un vehículo de emergencia para obtener verde |
| Ola verde | Cruceros consecutivos con un desfase igual al tiempo de viaje entre ellos |

Cifras de referencia: ciclo de 60-120 s; amarillo ~3-4 s; todo rojo ~1-2 s; flujo de
saturación ~1,800-1,900 veh/h/carril; peatón a 1.0-1.2 m/s, 20 m requieren 17-20 s;
400 m a 40 km/h ≈ 36 s; hora pico de 1,200 veh/h por aproximación; escenario de 4
aproximaciones y 3 cruceros. Todo lo demás (carriles, anchos, distancias, plazos de
sospecha) es del estudiante y se marca como supuesto.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundo).
aproximacion(Aproximacion, Carriles).
movimiento(Movimiento, Aproximacion, Tipo).   % Tipo: frente | izquierda
conflicto(Movimiento1, Movimiento2).
paso_peatonal(Paso, Metros).
tiempo_minimo(Tipo, Segundos).                % Tipo: amarillo | todo_rojo
indicacion(Movimiento, Color, DesdeSegundo).  % Color: verde | amarillo | rojo | intermitente
detector(Detector, Aproximacion, Tipo).       % Tipo: lazo | camara | radar
lectura(Detector, Variable, Valor, Segundo).
rango(Variable, Minimo, Maximo).
evento(Crucero, Tipo, Detalle, Segundo).      % boton, preferencia, cambio_de_plan, reinicio...
tramo(Crucero1, Crucero2, Metros).
```

## Contrato del gemelo

- `decide(+Solicitudes, -Plan, -Explicacion)` — predicado central. `Solicitudes` es una
  lista de peticiones (puede ser de una): movimientos con demanda, un paso peatonal,
  una preferencia de emergencia. `Plan` es la secuencia completa de fases o pasos con
  sus duraciones; `Explicacion` justifica cada elemento. Al pedir más soluciones debe
  dar los demás planes válidos. Si no existe ninguno (no cabe en el ciclo, hay verdes
  conflictivos inevitables), lo dice y señala el motivo, sin fallar en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre un
  movimiento, un detector, un crucero o un tramo (por ejemplo detector sospechoso,
  preferencia bloqueada por un peatón, ola degradada), consultables en cualquier
  dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado del crucero, el plan o la decisión con su
  explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Plan de fases.** Ningún plan contiene dos movimientos conflictivos con verde a la
   vez, y entre fases conflictivas hay amarillo y despeje. Si la demanda no cabe en el
   ciclo permitido, el gemelo lo dice y nombra qué lo impide, en vez de fallar en
   silencio. Con más de un plan válido, los da todos.
2. **Peatón.** La fase peatonal dura lo que exige el ancho del paso y la explicación
   recorre la cadena hasta él. Un paso más ancho produce una respuesta distinta con las
   mismas reglas; si el ciclo ya no cabe, lo dice.
3. **Ambulancia.** La secuencia hacia su verde nunca omite amarillo, despeje ni el
   despeje peatonal en curso, y dice a quién se le hace esperar y por qué. Si su
   movimiento ya es compatible con la fase en curso, la respuesta es no cambiar
   nada. Lo «obvio» (cortar todo ya) no es un resultado válido.
4. **Detector.** Un detector «ocupado» contradicho por otras fuentes produce «no se
   sabe», distinto de «hay fila» y de «no hay», con la evidencia; esa lectura nunca
   alarga un verde por sí sola.
5. **Ola verde.** Sin comunicación, el gemelo dice qué coordinación se degrada y qué
   sigue siendo seguro; un controlador reiniciado nunca arranca en una fase que choque
   con lo que muestran sus vecinos o con su propio despeje; lo supuesto se marca como
   tal. De un cambio de plan en pleno ciclo, distingue lo que se aplica y lo que espera.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el crucero en planta con
la indicación de cada movimiento, el plan propuesto con sus duraciones, la explicación
de la decisión, el estado de los detectores (incluido «no se sabe») y la ola de los tres
cruceros con su desfase. Debe permitir lanzar «qué pasaría si» (ambulancia, paso más
ancho, comunicación perdida). Debe verse bien en celular.
