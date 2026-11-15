# Contexto para agentes — gemelo digital del proyecto #50 (Examen en línea)

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
- Los nombres de alumnos, la docente, la coordinación y las cantidades de los ejemplos
  son ilustrativos. No los presentes como casos reales.

## Dominio

| Término | Significado |
|---|---|
| Intento | Presentación del examen por un alumno; tiene su propio temporizador |
| Sesión | Conexión de un dispositivo a un intento; un intento puede tener varias |
| Autoguardado | Envío continuo de respuestas al servidor para no perderlas |
| Bitácora | Registro de eventos con su instante: inicio, guardados, reconexiones, pestañas |
| Vencimiento | Instante en que el servidor da por terminado el tiempo de un intento |
| Pausado por desconexión | Nombre de un estado del intento, no una orden de detener el tiempo |
| Entrega | Cierre del intento, por el alumno o por vencimiento |
| Extensión | Tiempo adicional concedido a un alumno con una justificación |
| Inconformidad | Reclamo de un alumno; se resuelve con evidencia de la bitácora |

Cifras de referencia, todas del problema original: sesión típica de 30 a 90 min con 20 a
60 preguntas; grupos de 30 a 300 alumnos; caídas de segundos a minutos; el escenario de
200 alumnos, 60 min, 10 % con al menos una desconexión, 4 min de desconexión cerca del
final y un reinicio del servidor a mitad del examen. Todo lo demás (alumnos, docente,
coordinación, tamaños reducidos) es ilustrativo de esta extensión.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar eventos simulados o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Las desconexiones y el reinicio del servidor no se sortean: entran como hechos.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundo).                              % segundos desde el inicio del escenario
alumno(Alumno, Grupo).
intento(Intento, Alumno, Examen).
examen(Examen, DuracionSegundos).
sesion(Sesion, Intento).
evento(Fuente, Sujeto, Evento, Segundo).     % Fuente: servidor | cliente | coordinacion
                                             % Evento: inicia | autoguarda | pierde_conexion
                                             % | reconecta | cambia_pestana | entrega
                                             % | cae | arranca | aprueba_extension
respuesta(Intento, Pregunta, Valor, Sesion, SegundoServidor).
marca_cliente(Intento, Pregunta, Segundo).   % lo que declara el navegador; no confiable
extension(Extension, Intento, Segundos).
justificacion(Extension, Autor, Segundo).    % instante que el autor declara
```

El estado de un intento, el tiempo restante, el vencimiento y la vigencia de una sesión
**no son hechos**: se deducen de los eventos. Las tolerancias y los plazos son
predicados que añade el estudiante con sus supuestos.

## Contrato del gemelo

- `decide(+Intento, -Decision, -Explicacion)` — predicado central. En este proyecto la
  entidad es un intento y `Decision` es lo que procede con él en el «ahora»: aceptar o
  rechazar una respuesta, entregar, aplicar o no una extensión, marcar para revisión.
  Incluye el siguiente paso válido; al pedir más soluciones da los demás pasos válidos y,
  si ninguno existe (historia imposible), lo dice y señala la primera entrada que la
  rompe, sin fallar en silencio. `Explicacion` es una lista de hechos y condiciones que
  justifican la decisión, incluida la regla que perdió cuando hubo conflicto.
- `situacion(?Intento, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  intento vencido, sesión vigente, respuesta tardía, historia imposible), consultables
  en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado deducido de cada intento, la decisión con su
  explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Cuatro minutos.** Un intento «pausado por desconexión» sigue gastando tiempo. Si
   la reconexión llega después del vencimiento, el intento aparece entregado en el
   instante del vencimiento, no en el de la reconexión, y cuentan solo las respuestas
   guardadas antes. Con tiempo de sobra, el mismo intento puede continuar.
2. **Último segundo.** Una respuesta recibida después de que el alumno entregó no cuenta
   aunque llegue antes del vencimiento. Una cuya marca del navegador es anterior pero
   que el servidor recibe después del cierre no cuenta. Un empate entre recepción y
   cierre da «no se sabe». En cada caso la explicación nombra los dos eventos cuyo orden
   decide.
3. **Dos sesiones.** Sesiones sucesivas y sesiones traslapadas reciben tratamientos
   distintos y la explicación dice cuál fue. Sin evento de pérdida de la primera sesión
   no se afirma que siguiera conectada ni que no: da «no se sabe» y dice qué dato falta.
   Nunca se descartan respuestas guardadas sin que la explicación lo justifique.
4. **Reinicio.** Al arrancar el servidor ningún temporizador se reinicia. Un intento sin
   evento de inicio recibe un vencimiento acotado o «no se sabe», no un valor inventado.
   Un autoguardado fechado dentro del hueco se señala como la primera entrada que rompe
   la historia. Que nadie haya reportado una desconexión no se lee como que no la hubo.
5. **Extensión.** Una extensión aprobada después del cierre no altera un intento ya
   entregado: la explicación nombra las dos reglas en choque, cuál prevalece, a quién se
   le falla y qué evidencia habría cambiado el veredicto. «Antes» o «después» se decide
   por el orden de los eventos registrados, no por el instante que el autor declara.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el estado deducido de cada
intento y su tiempo restante, la línea de tiempo de eventos con las entradas en duda o
imposibles, las sesiones de cada alumno, la decisión con su explicación y la respuesta
a «qué falta». Debe verse bien en celular.
