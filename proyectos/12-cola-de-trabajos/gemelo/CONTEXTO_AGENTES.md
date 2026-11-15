# Contexto para agentes — gemelo digital del proyecto #12 (Cola de trabajos)

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
| Trabajo | Tarea que no debe bloquear al usuario (correo, reporte, imagen, llamada a una API); unidad sobre la que se decide |
| Tipo | Clase de trabajo; fija cuánto dura |
| Trabajador | Quien ejecuta un trabajo a la vez; su número tiene un tope útil |
| Dependencia | Un trabajo no puede empezar hasta que termine otro (su requisito) |
| Ciclo | Cadena de dependencias que regresa al mismo trabajo; no tiene orden válido |
| Al menos una vez | Garantía de entrega en la que un trabajo puede ejecutarse dos veces |
| Tiempo de visibilidad | Plazo para confirmar; si el trabajador no termina, otro toma el trabajo |
| Backoff exponencial | Esperas crecientes entre reintentos, con *jitter* (variación) |
| Trabajo envenenado | El que siempre falla |
| Cola de muertos | Donde termina un trabajo tras agotar sus N intentos |

Cifras de referencia: tiempo de visibilidad de 30 s; 1-5 % de errores transitorios en
APIs externas; backoff de 1 s, 2 s, 4 s, 8 s... con jitter; cola de muertos tras N
intentos (el original no da N); trabajos de 50 ms frente a un reporte de 10 minutos;
4 núcleos; escenario de 10,000 trabajos de 3 tipos (50 ms, 2 s y 60 s), servicio externo
caído 5 minutos y reinicio con 200 trabajos en ejecución; un trabajo programado para
«dentro de 3 horas».

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar trabajos y fallas simulados o graficar. Prolog nunca es una librería de
  Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Instante).                       % en milisegundos desde el inicio del escenario
tipo(Tipo, DuracionMs).
trabajo(Trabajo, Tipo, Prioridad).
depende(Trabajo, Requisito).           % Trabajo no empieza hasta que termine Requisito
usa_servicio(Trabajo, Servicio).
programado(Trabajo, Instante).         % no antes de ese instante
evento(Trabajo, Evento, Instante).     % Evento: encolado | tomado | terminado | fallo
servicio(Servicio, Estado, Desde).     % Estado: disponible | caido
limite(Nombre, Valor).                 % Nombre: trabajadores | visibilidad | max_intentos
repetible(Tipo).                       % ejecutarlo dos veces no hace daño
```

No hay mediciones de sensores en este dominio, así que no se usa `rango/3`: el hecho
con instante es `evento/3`. El estado de un trabajo no es un hecho; se deduce de sus
eventos.

## Contrato del gemelo

- `decide(+Trabajos, -Plan, -Explicacion)` — predicado central. `Trabajos` es una lista
  de trabajos (puede ser de uno); `Plan` es el plan completo para esa lista: el orden
  de ejecución y, para cada trabajo, si corre ahora, espera, se retiene o ya no puede
  correr; `Explicacion` justifica cada posición. Al pedir más soluciones debe dar los
  demás planes válidos. Si no existe ninguno, lo dice y señala el motivo.
- `situacion(?Trabajo, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  trabajo en un ciclo, detenido para siempre, retrasado, en duda, con historia
  inconsistente), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe. En
  particular: terminó, no terminó, no se sabe si terminó.
- La API expone al menos: el estado deducido de los trabajos, el plan con su
  explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Orden.** En el plan ningún trabajo aparece antes que sus requisitos, directos o
   indirectos. Con trabajos independientes entre sí, al pedir más soluciones aparecen
   los demás órdenes válidos. Con un ciclo, el gemelo nombra los trabajos que lo forman
   en vez de fallar en silencio o quedarse sin terminar.
2. **Cascada.** Un trabajo que depende, aunque sea indirectamente, de uno muerto
   aparece como detenido para siempre, con la causa de origen y el camino que los une.
   Si el origen solo espera a que vuelva el servicio externo, aparece como retrasado,
   no como perdido. Un trabajo sin relación con el origen no aparece como afectado.
3. **Conflicto.** Un trabajo urgente cuyo requisito no ha terminado no corre, y la
   explicación nombra la dependencia como la causa. Nunca hay más trabajos corriendo
   que trabajadores. Un trabajo programado no corre antes de su hora. La consulta
   inversa devuelve qué tendría que pasar para que le toque.
4. **Dato dudoso.** Un trabajo tomado y sin confirmación da «no se sabe», distinto de
   «terminó» y de «no terminó», y el mismo tiempo sin confirmar no significa lo mismo
   en un tipo corto que en uno largo. Volverlo a lanzar o retenerlo depende de si
   repetirlo es inofensivo, y la duda alcanza a los que dependen de él.
5. **Historia.** Una secuencia de eventos válida se acepta; una que no pudo ocurrir se
   rechaza señalando el primer paso que la rompe. Las mismas reglas enumeran los
   siguientes pasos válidos de un trabajo.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar los trabajos con su
estado deducido (incluido «no se sabe»), la red de dependencias, el plan propuesto con
su explicación, los trabajos afectados por una falla con su causa y la respuesta a
«qué falta». Debe verse bien en celular.
