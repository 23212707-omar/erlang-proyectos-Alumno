# Contexto para agentes — gemelo digital del proyecto #46 (Asistencia por QR)

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
  (vigencia exacta del código, paso de retardo a falta, tolerancia de reloj, margen de
  ubicación, peso de cada señal de presencia, valor de un retardo, plazo de un escaneo
  guardado tras el cierre) se marca como supuesto y se le pide al estudiante la fuente.
- Es un ejercicio con datos simulados, no un sistema real de una escuela.

## Dominio

| Término | Significado |
|---|---|
| Sesión | Una clase de un grupo; puede tener varios segmentos (tramos) en aulas distintas |
| Segmento | Tramo de una sesión con su aula y su horario |
| Código QR dinámico | Código que se renueva cada pocos segundos para que sirva solo quien está presente |
| Escaneo | Registro que manda el teléfono del alumno con el código que leyó |
| Tolerancia | Minutos tras el inicio en que aún se cuenta asistencia completa |
| Retardo / falta | Estatus de quien llega pasada la tolerancia / de quien no llega a registrarse |
| Justificante | Documento que explica una falta; tiene estado (presentado, aprobado, rechazado) |
| Corrección manual | Cambio que hace el docente a un registro, con bitácora |
| Sin registro | No hay dato de asistencia; no equivale a falta |
| Derecho a evaluación | Mínimo de asistencia que exige la institución para presentar evaluación |

Cifras de referencia (todas del problema original): tolerancia de entrada de ejemplo de
10 min; mínimo de asistencia «a menudo 80 %»; códigos renovados cada 10 a 30 s;
geolocalización de interiores imprecisa por decenas de metros; 60 grupos de 35 alumnos en
el escenario. Son órdenes de magnitud. Marcadas como inventadas por esta extensión: la
escala reducida (3 grupos, 4 aulas, unos 8 alumnos por grupo), los dispositivos
compartidos, los justificantes con estado y los motivos y fechas de las correcciones.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar escaneos simulados o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Si el escenario necesita azar (qué reintento llega primero, qué reloj se desajusta),
  entra como hecho, no se sortea.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundo).                                  % instante del modelo, en segundos
inscrito(Alumno, Grupo).
sesion(Sesion, Grupo, Inicio, Fin).
segmento(Sesion, Aula, Desde, Hasta).            % una sesión puede tener varios tramos
qr_emitido(Sesion, Token, Desde, Hasta).         % vigencia de cada código
escaneo(Escaneo, Alumno, Sesion, Token, HoraTelefono, HoraRecibido, Dispositivo).
lugar(Escaneo, Red, Metros, Imprecision).        % red vista y ubicación aproximada
evento_sesion(Sesion, Evento, Segundo).          % abierta | cerrada | cancelada | cambio_aula(Aula)
correccion(Sesion, Alumno, Docente, Estado, Motivo, Segundo).
justificante(Alumno, Sesion, Estado, Segundo).   % presentado | aprobado | rechazado
politica(Nombre, Valor).                         % tolerancia, vigencia, mínimo...; los fija el estudiante
```

## Contrato del gemelo

- `decide(+Caso, -Decision, -Explicacion)` — predicado central. `Caso` es un escaneo, un
  par alumno y sesión, o un alumno (para el derecho a evaluación); las demás sesiones,
  escaneos, correcciones y justificantes entran como hechos. `Decision` dice el estatus
  (asistencia, retardo, falta, sin registro, escaneo que no cuenta o en duda, derecho o no
  a evaluación, o «depende de»). Al pedir más soluciones, da las demás decisiones que
  también serían defendibles con los datos, en su orden de conveniencia. `Explicacion` es
  una lista de hechos y condiciones que justifican la decisión, incluida la parte a la que
  se le falla.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (instante probable
  de un escaneo, escaneo repetido, escaneo sospechoso, alumno sin registro por cierre,
  corrección sin respaldo, tramo esperado, alumno por debajo del mínimo), consultables en
  cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe. Un dato
  ausente (reloj sin respaldo, ubicación imprecisa, justificante pendiente, sesión sin
  cerrar) nunca cuenta como «no».
- La API expone al menos: el estado de cada sesión y de cada alumno, la decisión con su
  explicación, la lista de escaneos sospechosos o en duda, la bitácora de correcciones con
  su respaldo y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Escaneo tardío.** Un escaneo hecho dentro de la tolerancia y recibido después de ella
   no se trata igual que uno hecho fuera; un reintento no duplica; un reloj que contradice
   lo que respaldan los demás datos produce «no se sabe» o una decisión que nombra la
   contradicción, nunca un estatus por el solo valor del reloj.
2. **Código compartido.** Un código vigente no basta para dar por buena la presencia; un
   escaneo desde fuera de la red del aula no basta para darlo por falso. Con señales que
   chocan, el resultado es «en duda» y la explicación lista las señales a favor y en
   contra. Dos escaneos de alumnos distintos desde un mismo dispositivo se señalan.
3. **Cierre y correcciones.** Un alumno sin registro por cierre de la sesión no queda como
   «faltó» sin más: sale «sin registro». Una corrección sin motivo o contradicha por otros
   datos queda pendiente de revisión y nombra qué la contradice.
4. **Cambio de aula.** La misma red cuenta distinto según el tramo; el estatus se da por
   tramo y la sesión resulta completa, parcial o sin asistencia. Señales discrepantes en la
   frontera del cambio dan «no se sabe».
5. **Derecho a evaluación.** El veredicto sale de las sesiones que cuentan, no de contar
   faltas; un alumno con menos faltas puede quedar peor que otro. Con un justificante
   pendiente que cambiaría el veredicto, la respuesta es «depende de» y la consulta inversa
   dice qué tendría que cambiar.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar la lista de la sesión con
el estatus de cada alumno y la hora que se usó, los escaneos sospechosos o en duda con sus
señales, la bitácora de correcciones con su respaldo, el avance de cada alumno hacia el
mínimo de asistencia y la respuesta a «qué falta». Debe verse bien en celular.
