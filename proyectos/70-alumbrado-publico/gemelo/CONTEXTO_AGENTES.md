# Contexto para agentes — gemelo digital del proyecto #70 (Alumbrado público)

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
| Luminaria | Lámpara con su poste; unidad sobre la que se decide |
| Circuito | Grupo de luminarias que comparten alimentación desde un tablero |
| Tablero | Punto de alimentación de un circuito; si pierde energía, todo su circuito se apaga |
| Telemetría | Luminaria inteligente que reporta corriente y estado; no todas la tienen |
| Reporte ciudadano | Aviso lento, repetido e impreciso; la dirección viene escrita a mano |
| Falla | Problema consolidado de una luminaria; varios reportes pueden apuntar a una sola |
| Tramo oscuro | Luminarias contiguas en una calle que están apagadas a la vez (se deduce) |
| Sitio sensible | Cruce peligroso, escuela u hospital; da criticidad al lugar |
| Meta de atención | Plazo para atender una falla (por ejemplo 72 h) |
| Reincidencia | La lámpara reparada vuelve a fallar en una semana |
| Cuadrilla | Equipo que repara entre 8 y 15 luminarias al día según distancia y altura |

Cifras de referencia, todas del problema original: 15 reportes sobre el mismo poste; 40
lámparas apagadas por la falla de un circuito; metas de atención de, por ejemplo, 72 h;
cuadrillas que reparan entre 8 y 15 luminarias al día; reincidencia dentro de una
semana; escenario de 5,000 luminarias, 80 reportes diarios y 4 cuadrillas.

Inventado por esta extensión (no son datos del original): la colonia ficticia de unas
24 luminarias, 3 circuitos y 2 cuadrillas; el tablero que debe restablecerse antes de
reparar su circuito; la cuadrilla que se queda sin camión; calles y folios de ejemplo.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar reportes y lecturas simulados o graficar. Prolog nunca es una librería de
  Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Hora).                           % horas desde el inicio del escenario
luminaria(Luminaria, Calle, Circuito).
tramo(Luminaria1, Luminaria2).         % contiguas en la misma calle
circuito(Circuito, Tablero).           % de qué tablero se alimenta
sitio(Luminaria, Tipo).                % Tipo: cruce | escuela | hospital | comun
altura(Luminaria, Altura).             % en la unidad que elija el estudiante
distancia(Luminaria1, Luminaria2, Medida).  % entre dos puntos, misma unidad en todo
reporte(Reporte, Direccion, Hora).     % Direccion: texto como lo escribió el ciudadano
rango(Variable, Minimo, Maximo).       % Variable: corriente | estado
lectura(Luminaria, Variable, Valor, Hora).  % solo las luminarias con telemetría
evento(Luminaria, Evento, Hora).       % Evento: asignada(C) | reparada(C) | cerrada(C)
cuadrilla(Cuadrilla, Estado).          % Estado: disponible | sin_camion
```

Las luminarias sin telemetría no tienen `lectura/4`: de ellas solo se sabe por reportes.
La falla consolidada no es un hecho; se deduce de los reportes. Si el dominio pide
azar (por ejemplo, cuándo llegan los reportes), las reglas no sortean nada: el valor
entra como hecho.

## Contrato del gemelo

- `decide(+Fallas, -Plan, -Explicacion)` — predicado central. `Fallas` es una lista de
  fallas (puede ser de una); `Plan` es el reparto completo: qué cuadrilla atiende cada
  falla y en qué orden, o qué se queda sin atender a tiempo; `Explicacion` justifica
  cada posición. Al pedir más soluciones debe dar los demás planes válidos. Si no
  existe ninguno (capacidad insuficiente, dependencia sin cumplir), lo dice y señala
  el motivo, sin fallar en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  falla duplicada, circuito sin energía, tramo oscuro, reincidente, cierre dudoso),
  consultables en cualquier dirección. `Entidad` puede ser reporte, luminaria o circuito.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe. En
  particular: es la misma falla, es otra, no se sabe; está apagada, está encendida,
  no se sabe.
- La API expone al menos: el mapa de fallas consolidadas con su estado deducido, el
  plan con su explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Duplicados.** Varios reportes con direcciones distintas del mismo poste dan una
   sola falla, y la evidencia lista los reportes que la sustentan. Muchos reportes no
   hacen la falla más urgente por sí solos. Un reporte que podría ser de dos postes
   contiguos da «no se sabe», nombra los dos candidatos y no se fusiona en silencio.
2. **Circuito.** Un tablero sin energía aparece como causa común de las luminarias de su
   circuito, con el camino que las une, también de las que no tienen telemetría, que se
   marcan como inferidas. Luminarias apagadas de un mismo circuito con tablero sano
   siguen siendo fallas independientes. Un reporte de otro circuito no queda afectado.
3. **Reincidencia.** Una luminaria cerrada como reparada sin corriente posterior, o con
   un reporte nuevo en la ventana de reincidencia, no se trata como una falla nueva sin
   más: la explicación dice si es la misma falla, otra o «no se sabe», y por qué. Su
   lugar en la fila no depende solo de tener un folio nuevo. La consulta inversa
   devuelve qué otros cierres de esa cuadrilla conviene revisar.
4. **Prioridad.** Un tramo oscuro continuo pesa distinto de una lámpara apagada entre
   vecinas encendidas. Con capacidad para una sola reparación, el gemelo elige, nombra
   la regla que decidió, dice a quién se le falla y qué tendría que cambiar para
   atender a ambas. La consulta inversa responde por qué una falla no va primero.
5. **Reparto y rutas.** Ninguna cuadrilla recibe más de lo que cabe en un día ni visita
   una luminaria de un circuito sin energía antes de que se restablezca su tablero.
   Con varias asignaciones válidas, al pedir más soluciones aparecen las demás. Si las
   metas no caben, el gemelo lo dice y nombra las fallas que no caben y el recurso
   que falta. Con una cuadrilla sin camión, el plan se recalcula y explica qué cambió.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar un mapa de las luminarias
con su estado deducido (encendida, apagada, inferida, «no se sabe»), las fallas
consolidadas con los reportes que las sustentan, los circuitos afectados y su causa,
el plan de cada cuadrilla con su explicación y la respuesta a «qué falta». Debe verse
bien en celular.
