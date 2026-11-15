# #46 — Asistencia por QR: gemelo digital con programación lógica

> Extensión del proyecto #46. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el pase de lista: un proceso por sesión de clase con su
código QR que se renueva cada pocos segundos, un registro de asistencia, y escaneos que se
aceptan o se rechazan (vencidos, repetidos, compartidos por foto). Esa simulación responde
«¿este escaneo entró o no?». Quien da la clase, y quien decide si un alumno tiene derecho a
evaluación, necesita algo más: «¿qué le pongo a este alumno, quién me lo puede discutir, y
por qué?».

El gemelo digital es el **modelo lógico** de la asistencia: hechos que reflejan lo que
ocurrió y reglas que reflejan cómo se decide en la escuela. Se escribe en Prolog porque lo
que hay que resolver aquí no es calcular un porcentaje, sino deducir qué pasó cuando los
datos se contradicen, justificar a quién se le falla y distinguir «faltó» de «no consta que
asistió».

## La asistencia que se clona

Una escuela como un tecnológico, reducida a 3 grupos, 4 aulas, unos 8 alumnos por grupo y
un semestre corto de sesiones. Es una simulación planteada por el problema original; lo que
se añade (dispositivos compartidos, justificantes con estado, correcciones con fecha) está
marcado en las situaciones.

| Parte | Contenido |
|---|---|
| Entidades | escuela → grupo → alumno; docente por grupo; aulas; sesiones con uno o más segmentos; códigos QR; teléfonos de los alumnos |
| Estado por sesión | grupo, horario, segmentos (aula y tramo de tiempo), códigos emitidos con su vigencia, si está abierta, cerrada o cancelada |
| Estado por alumno | grupos en que está inscrito, escaneos, correcciones del docente, justificantes y su estado |
| Estado por escaneo | alumno, sesión, código usado, hora según el teléfono, hora en que llegó al servidor, dispositivo, red vista y ubicación aproximada |
| Eventos | se emite o vence un código; llega un escaneo (a veces tarde o dos veces); el docente cierra la sesión, cambia de aula o corrige un registro; se presenta o se resuelve un justificante |
| Decisiones | ¿este escaneo cuenta?, ¿asistencia, retardo o falta?, ¿a quién creerle?, ¿tiene este alumno derecho a evaluación? |

## Situaciones que tu gemelo debe razonar

Las cinco parten del problema original; los complementos derivados añaden un detalle que
el original no menciona y se señalan en cada una. En cada situación, tu gemelo debe llegar
a una decisión **y poder explicarla**.

### Situación 1 — El escaneo que llegó después de lo que pasó

- **Qué pasa.** Una alumna escanea el código desde el pasillo, donde casi no hay señal. Su
  teléfono guarda el escaneo y lo manda cuando recupera conexión; llega al servidor mucho
  después de que empezó la clase, y luego llega otra vez (reintento). El reloj de otro
  teléfono está desajustado. Hay una tolerancia de entrada (el original da 10 min como
  ejemplo) y, pasada, el alumno cuenta con retardo o con falta.
- **Qué datos hay.** Por cada escaneo, la hora según el teléfono, la hora en que llegó, el
  código que traía y la vigencia de cada código emitido; el horario de la sesión. Nada
  dice «a qué hora escaneó de verdad».
- **Qué debe deducir.** Cuándo es razonable creer que ocurrió el escaneo, qué escaneos son
  el mismo hecho repetido, y si un reloj contradice lo que el servidor sabe. De ahí sale
  si el alumno estuvo a tiempo, con retardo o sin llegar a registrarse.
- **Qué debe contestar.** El estatus de cada alumno, con la hora que se usó y por qué esa y
  no otra; y, si los datos no alcanzan para decidir entre dos estatus, «no se sabe» en
  lugar de adivinar. Lo obvio es creer la hora de llegada al servidor (castiga a quien tuvo
  mala señal) o creer la hora del teléfono (premia a quien adelanta el reloj); ambas son
  sospechosas.
- **Por qué es lógica.** El instante que importa no está en ningún campo: se deduce de
  varios datos que se respaldan o se contradicen. La cadena es larga: código, vigencia,
  instante probable, minutos desde el inicio, estatus.

### Situación 2 — El código que viajó por mensaje

- **Qué pasa.** Un alumno fotografía el código de la pantalla del salón y se lo manda a un
  amigo que no está. Los códigos dinámicos están pensados para evitarlo, pero el amigo
  puede escanear mientras el código sigue vigente (el original da entre 10 y 30 s). Otro
  alumno sí está en el salón, pero escanea con datos móviles porque la red del aula no le
  da señal. Además, dos escaneos distintos de la misma sesión vienen del mismo teléfono
  (complemento derivado: dispositivo compartido).
- **Qué datos hay.** Código usado y su vigencia, red vista y ubicación aproximada del
  escaneo (en interiores la imprecisión es de decenas de metros, según el original),
  dispositivo, y los demás escaneos de la misma sesión.
- **Qué debe deducir.** Qué escaneos se pueden dar por buenos, cuáles son sospechosos y
  cuáles no tienen cómo saberse. Ninguna lectura sola prueba presencia ni ausencia.
- **Qué debe contestar.** Por escaneo: cuenta, no cuenta o queda en duda, con las señales
  que coinciden y las que se contradicen. Y a quién se le falla si se equivoca: al alumno
  honesto (falso rechazo) o a la clase y al docente (falso registro). Lo intuitivo es que
  un código vigente demuestra presencia; no lo demuestra, y escanear desde fuera de la red
  del aula tampoco demuestra ausencia.
- **Por qué es lógica.** Es un dilema real: dos partes tienen razón y el costo del error
  no es el mismo (pregunta guía 1 del original). La regla debe declarar una vez cómo se
  pesan las señales y poder justificarlo ante el alumno que reclama.

### Situación 3 — La sesión que se cerró con alumnos sin registrar

- **Qué pasa.** El docente cierra la sesión con alumnos todavía sin registro por mala
  señal. Más tarde, a algunos les llega un escaneo guardado en el teléfono; a otros el
  docente les pone la asistencia a mano. Una de esas correcciones se hace días después, sin
  motivo capturado, para un alumno cuyo único escaneo vino de un teléfono que escaneó por
  otro compañero.
- **Qué datos hay.** Hora de cierre, escaneos con su hora de llegada, correcciones con
  docente, motivo y fecha; y los demás escaneos de esa sesión. La bitácora de correcciones
  que pide el original es un dato, no una decisión.
- **Qué debe deducir.** Qué alumnos quedaron sin registro por culpa del cierre y no por
  ausencia, qué correcciones tienen respaldo y cuáles se contradicen con otros datos.
- **Qué debe contestar.** Por alumno: asistió, faltó o «sin registro, no consta»; y para
  cada corrección, si procede, si queda pendiente de revisión y qué la sustenta. El
  gemelo debe poder responder también a quién perjudica cada veredicto.
- **Por qué es lógica.** Es rendición de cuentas: el docente y el sistema dicen cosas
  distintas y la regla decide cuánto pesa la palabra de cada uno. «Sin registro» y
  «faltó» no son lo mismo, aunque en una hoja de cálculo se vean igual.

### Situación 4 — La clase que cambia de aula a la mitad

- **Qué pasa.** Una sesión empieza en un aula y, a la mitad, pasa a otra (el original
  menciona las sesiones que cruzan cambio de aula). Hay un código para cada tramo. Un
  alumno escanea en la primera aula y no aparece en la segunda; otro llega cuando ya se
  cambiaron; otro escanea el código viejo desde la red del aula anterior justo después del
  cambio.
- **Qué datos hay.** Los tramos de la sesión con aula y horario, el código de cada tramo y
  su vigencia, la red y la ubicación de cada escaneo, y la hora del cambio de aula (puede
  haberse avisado tarde).
- **Qué debe deducir.** Qué aula y qué red son las esperadas en cada instante, a qué tramo
  pertenece cada escaneo, y qué cuenta como asistir a «la sesión» cuando solo se estuvo en
  una parte.
- **Qué debe contestar.** El estatus por alumno y por tramo, y si la sesión cuenta
  completa, parcial o no cuenta, con la razón. Si dos señales discrepan (red del aula
  anterior, código del tramo nuevo), «no se sabe» hasta que algo más lo aclare.
- **Por qué es lógica.** La misma red o la misma ubicación significan cosas distintas según
  el tramo: el contexto cambia las reglas en medio de la clase. Y el aula esperada es un
  dato que depende del tiempo, no un atributo fijo de la sesión.

### Situación 5 — El 80 % que no es lo que parece

- **Qué pasa.** El original recuerda que muchas instituciones exigen un mínimo de
  asistencia (a menudo 80 %) para tener derecho a evaluación. A fin de semestre, cuatro
  alumnos están cerca del mínimo: uno con retardos, otro con un justificante pendiente,
  otro con una sesión cancelada que quizá no cuenta, y otro con una corrección del docente
  que se discute (complemento derivado: justificantes con estado y fecha). El de menos
  faltas no es el que tiene más peligro.
- **Qué datos hay.** Los estatus por sesión que salen de las situaciones 1 a 4, los
  justificantes con su estado y fecha, las sesiones canceladas o sin cerrar, y las
  sesiones que cuentan para el grupo.
- **Qué debe deducir.** Cuántas sesiones cuentan de verdad para cada alumno, cuántas
  asistencias, y si el veredicto de cada uno depende de algo todavía abierto.
- **Qué debe contestar.** Por alumno: tiene derecho, no lo tiene, o «depende de» un dato
  pendiente, y qué tendría que cambiar para invertir el veredicto. Lo intuitivo es ordenar
  por número de faltas; es sospechoso porque cuentan las sesiones realizadas, los
  justificantes y qué hace cada estatus con el porcentaje.
- **Por qué es lógica.** La decisión encadena cinco o más deducciones, cada una de las
  cuales ya se resolvió en otra situación, y alguien pierde algo real: el derecho a
  presentar evaluación. La pregunta al revés («¿qué le falta?») es la que sirve en la
  ventanilla.

## Por qué no basta un script

Con `if ahora - inicio <= 10 * 60: asistencia()` resuelves un alumno con un reloj fiable y
una red perfecta. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué le pongo al alumno 4 en la sesión de hoy? | decisión |
| ¿Por qué retardo y no asistencia? | explicación |
| ¿Quiénes están por debajo del mínimo? | todas las respuestas |
| ¿Qué le falta a la alumna 6 para conservar su derecho? | la pregunta al revés |
| ¿Qué pasaría si se aprueba el justificante pendiente? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué cuesta más, rechazar a un alumno que sí estaba o registrar a uno que no estaba? ¿Dónde
   queda escrita esa decisión en tu gemelo?
2. ¿Qué datos puede creer el servidor y cuáles solo puede tomar como pista del teléfono?
3. ¿Cómo distingue tu gemelo «no asistió» de «no sé si asistió»?
4. ¿Qué parte de la explicación le sirve al alumno que reclama y cuál al docente?
5. ¿Qué eventos de tu simulación en Erlang (código renovado, escaneo aceptado, rechazado,
   duplicado, sesión cerrada) podrían alimentar a este gemelo como hechos?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la asistencia, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar escaneos simulados o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 3 grupos, 4 aulas y unos 8 alumnos por grupo, contra los 60 grupos de 35
  alumnos del escenario original. Cuántas sesiones tiene el semestre corto lo fijas tú.
- El «ahora» es un hecho del modelo, en segundos, no el reloj del sistema, para que las
  respuestas se puedan repetir.
- Los identificadores y cantidades de los ejemplos («alumno 4», «alumna 6») son
  ilustrativos, no datos del escenario.
- Los dispositivos compartidos, los justificantes con estado y los motivos y fechas de las
  correcciones son complementos de esta extensión, no del original.
- Los define y verifica el estudiante, porque el original no los da: cuánto dura la
  vigencia de un código (el original da un rango), a partir de cuándo el retardo es falta,
  cuánto se tolera un reloj desajustado, qué margen de ubicación se acepta, cuánto pesa
  cada señal de presencia, cuánto vale un retardo para el porcentaje, cuánto después del
  cierre aún se acepta un escaneo guardado y cuándo una corrección tardía exige revisión.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Alumnos que cambian de grupo a mitad de semestre y qué pasa con sus asistencias previas.
- Un alumno inscrito en dos grupos que empiezan a la misma hora.
- Eventos escolares oficiales que justifican a todo un grupo.
- Docente suplente que usa el QR de otro docente.
- Reportes por grupo para tutoría y detección temprana de deserción.

---
*Las cifras (tolerancia de ejemplo de 10 min, mínimo de asistencia de «a menudo 80 %»,
renovación del código cada 10 a 30 s, imprecisión de decenas de metros en interiores, 60
grupos de 35 alumnos) son de referencia y vienen del problema original. Verifica la fuente
vigente antes de citarlas en tu entrega.*
