# #43 — Citas médicas: gemelo digital con programación lógica

> Extensión del proyecto #43. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la agenda: un proceso por médico con sus huecos, citas que
pasan de agendada a confirmada, atendida o cancelada, recordatorios con temporizador y, si
dos pacientes toman el mismo hueco a la vez, solo uno lo consigue. Esa simulación responde
«¿qué cita quedó en qué hueco?». Quien administra la clínica necesita algo más: «¿a quién
le doy este hueco, qué hago con las citas de un médico enfermo, a quién le falta aviso, y
por qué?».

El gemelo digital es el **modelo lógico** de la clínica: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque lo que hay que
resolver aquí no es calcular, sino repartir tiempo y consultorios que no alcanzan, deducir
lo que ningún registro dice y distinguir «no vino» de «no sé si vendrá».

## La clínica que se clona

Una clínica de consulta externa en Tijuana, reducida a 4 médicos y 2 consultorios, con unas
veinte citas a la vista. Es una simulación planteada por el problema original; lo que se
añade (actores y detalles) está marcado en las situaciones.

| Parte | Contenido |
|---|---|
| Entidades | clínica → médico, consultorio; pacientes; citas; recordatorios; lista de espera |
| Estado por médico y consultorio | bloques que quitan agenda (guardia, vacaciones, cirugía, limpieza) |
| Estado por cita | paciente, médico, consultorio, tipo (general, primera vez, procedimiento), inicio, eventos y recordatorios |
| Estado por paciente | preferencias si las dio, historial de inasistencias, si espera un hueco |
| Eventos | se agenda, confirma, cancela o atiende una cita; no se presenta; sale o falla un recordatorio; se reinicia el sistema; cambia la hora del reloj |
| Decisiones | ¿cabe esta cita?, ¿a quién se le da el hueco?, ¿cuántas citas de más?, ¿qué aviso falta?, ¿quién queda sin cita? |

## Situaciones que tu gemelo debe razonar

Las cinco parten del problema original; las derivadas añaden un detalle que el original
no menciona y se señalan en cada una. En cada situación, tu gemelo debe llegar a una
decisión **y poder explicarla**.

### Situación 1 — El hueco que parece libre

- **Qué pasa.** Dos pacientes eligen el mismo horario en el mismo segundo. En la agenda del
  médico ese hueco se ve libre, pero una cita ocupa también un consultorio, y el original
  advierte que hay tiempos de preparación y limpieza. El médico atiende en los dos
  consultorios, y una cirugía o una guardia le bloquea parte del día (el bloqueo de
  consultorio por limpieza tras un procedimiento largo es complemento derivado). Uno pide
  una consulta general; el otro, una primera vez, que dura bastante más.
- **Qué datos hay.** Citas con médico, consultorio, tipo e inicio; bloques de agenda; las
  duraciones por tipo y la preparación que tú fijes. Nadie guarda «hueco utilizable».
- **Qué debe deducir.** Para cada tipo de cita, qué horarios sirven de verdad: sin
  traslape de médico, sin traslape de consultorio, con preparación y sin pisar un bloque.
  Y si las dos solicitudes caben juntas.
- **Qué debe contestar.** Para cada paciente, horario, médico y consultorio con la razón
  de cada elemento; por qué los demás huecos «libres» no sirven; los otros repartos
  válidos; y, si no caben ambos, a quién se le falla, por qué y cuál es el siguiente
  hueco. Lo obvio es dar el hueco a quien llegó primero; es sospechoso porque puede
  dejar sin lugar a quien tenía una sola opción cuando existía un reparto para ambos.
- **Por qué es lógica.** «Sin traslape» son varias condiciones que se cumplen a la vez
  sobre tres cosas (médico, consultorio, tiempo). El mismo modelo que rechaza un horario
  sirve para proponer los que sí caben.

### Situación 2 — Quince citas sin médico

- **Qué pasa.** Un médico se enferma por la mañana y deja 15 citas sin atender. Hay que
  reagendarlas respetando preferencias, y los huecos de los otros médicos no alcanzan para
  todas. Dos pacientes tienen razón: uno lleva
  semanas esperando esa cita y no quiere otro médico; otro tiene un motivo que, según la
  recepción, no puede esperar (el motivo capturado y su nivel de urgencia son complemento
  derivado). De varios pacientes no hay preferencia capturada.
- **Qué datos hay.** Las citas afectadas con tipo y desde cuándo esperaban; preferencias
  de quienes las dieron; huecos reales de los demás médicos y consultorios; el ahora.
- **Qué debe deducir.** Qué repartos reubican a todos sin traslape; cuáles preferencias se
  cumplen y cuáles se ceden en cada uno; y la cadena: mover una cita libera un hueco que
  otra necesita, y esa libera otro para una tercera.
- **Qué debe contestar.** La reubicación completa con la razón de cada pareja y la
  preferencia sacrificada; los demás repartos válidos; si no alcanza, quién queda sin
  reubicar, por qué él y qué hueco lo resolvería. Quien no dio preferencia aparece como
  «no se sabe», no como «le da igual».
- **Por qué es lógica.** Las preferencias y los recursos son condiciones sobre el mismo
  reparto. Cuál se cede primero se declara una vez, y la pregunta al revés («¿qué habría
  que ceder para que alcance?») sale de las mismas reglas.

### Situación 3 — El 20 % que no siempre falta

- **Qué pasa.** La clínica sobre-agenda una franja porque cerca de uno de cada cinco
  pacientes no se presenta (20 % en el escenario; entre 15 % y 30 % se reporta). Si
  todos llegan, hay esperas largas; si faltan y no se sobre-agendó, un médico
  queda ocioso. Esa tarde, en una franja casi todos confirmaron; en
  otra, la mitad no ha contestado y uno de ellos ya faltó antes (las confirmaciones y el
  historial de inasistencias son complemento derivado). Una de las citas es un
  procedimiento largo.
- **Qué datos hay.** Citas por franja con su estado de confirmación, recordatorios,
  historial de inasistencias del paciente y la capacidad de médico y consultorio. Nadie
  mide «va a faltar»; cuántas de más tolera la clínica lo decides tú.
- **Qué debe deducir.** El riesgo de ausencia de cada franja, que sale de combinar varias
  señales, y si admite una cita extra y de qué tipo.
- **Qué debe contestar.** Por franja, «sí», «no» o «no se sabe» y la evidencia; el
  peor caso (todos llegan): quién espera y cuánto; y qué cambia si un paciente sin
  respuesta confirma o cancela. Lo obvio es sumar una cita extra por cada cinco en toda
  franja; es sospechoso porque el promedio no describe a una franja ya confirmada.
- **Por qué es lógica.** La misma cifra de ausencias vale distinto según lo que se sepa de
  cada paciente. «Confirmó», «canceló» y «no contestó» son tres estados, y la política de
  sobrecupo se declara una vez.

### Situación 4 — El recordatorio que nadie sabe si salió

- **Qué pasa.** Cada cita debe recibir recordatorios a 48 h y 2 h antes, con opción de
  confirmar o cancelar. Una noche el sistema se reinicia y, al volver, hay recordatorios
  cuya hora ya pasó: de unos hay constancia de envío, de otros de falla y de otros nada.
  Esa semana cambia la hora del reloj (horario de verano): una cita queda a 48 h o a 2 h
  distinto según se cuente en reloj o en tiempo real. Distinguir enviado de entregado
  es complemento derivado.
- **Qué datos hay.** Citas con su inicio, los eventos de cada recordatorio con su
  instante, el ahora y el cambio de hora. Nadie guarda «debió salir» ni «en duda».
- **Qué debe deducir.** Qué recordatorios ya debían haber salido, cuáles constan, cuáles
  fallaron, cuáles no se sabe; y la cadena: sin constancia del aviso de 48 h y con el de
  2 h aún pendiente, la cita queda sin confirmar, su franja gana riesgo y el paciente es
  candidato a una llamada.
- **Qué debe contestar.** Por cita, sus recordatorios debidos, cumplidos y en duda; qué
  enviar ahora y qué no, para no duplicar; a quién llamar; y a qué hora real cae el de
  2 h en el día del cambio. Reenviar o no, tras cuánto atraso, lo decides tú.
- **Por qué es lógica.** «Debió salir» se deduce de la cita y del ahora; «salió», de
  eventos. «Sin constancia» no es «no salió», y de esa duda cuelgan otras conclusiones.

### Situación 5 — El hueco que deja una cancelación

- **Qué pasa.** Un paciente cancela y libera un hueco que puede ofrecerse a la lista de
  espera. Esperan tres: el que lleva más tiempo, uno que solo acepta a ese médico y pide
  primera vez (que dura más que el hueco, con su preparación), y uno al que el médico marcó
  como pronto (la marca y cancelar con pocas horas de aviso son complemento derivado). Si
  la cancelación llega tarde, quizá ya no hay tiempo de avisar a nadie.
- **Qué datos hay.** El hueco con médico, consultorio, inicio y fin; la cancelación con su
  instante; la lista de espera con tipo de cita, preferencias, antigüedad y marcas; el ahora.
- **Qué debe deducir.** Quién es elegible (su cita cabe con su preparación, acepta ese
  médico, hay tiempo de avisarle) y, entre los elegibles, en qué orden. Y si conviene
  partir el hueco entre dos consultas cortas.
- **Qué debe contestar.** A quién se ofrece, por qué él y no los demás, a quién se le
  falla y qué se hace si no contesta o si ya no hay tiempo («ya no se puede ofrecer»).
  Lo obvio es ofrecer al primero de la lista; es sospechoso porque quizá su cita no
  cabe y el hueco se pierde. Entre dos elegibles con razón, la regla debe justificar.
- **Por qué es lógica.** Primero se descarta lo que no cabe y después se ordena. La
  política de prioridad se declara una vez y vale para todos los huecos.

## Por qué no basta un script

Con `hueco = next(h for h in huecos if h.medico == m and h.libre)` asignas un hueco a un
paciente a la vez, con datos perfectos. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué hueco le doy al paciente 7? | decisión |
| ¿Por qué no a las 10, si la agenda del doctor lo muestra libre? | explicación |
| ¿Qué repartos reubican las citas del médico enfermo? | todas las respuestas |
| ¿Qué tendría que pasar para que el paciente 9 alcance cita esta semana? | la pregunta al revés |
| ¿Qué pasaría si el paciente 4 cancela dentro de dos horas? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para que un traslape sea imposible, y de qué tres cosas puede
   traslaparse una cita?
2. Cuando «el primero que pidió» y «el que más lo necesita» se contradicen, ¿dónde queda
   escrito cuál gana?
3. ¿Cómo distingue tu gemelo «el recordatorio no salió» de «no sé si salió»?
4. ¿Qué parte de la explicación le sirve a la recepcionista y qué parte es ruido?
5. En Erlang un proceso por médico garantiza que, si dos toman el mismo hueco, solo una
   cita se agenda. ¿Qué de eso alimenta a este gemelo, y qué decide el gemelo que ese
   proceso no puede: a quién debió tocarle?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la clínica, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra el reparto
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar citas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 4 médicos, 2 consultorios y unas veinte citas, contra los 10 médicos,
  4 consultorios y 200 citas al día del escenario original. Los números de pacientes, citas
  y franjas de los ejemplos son identificadores del ejercicio.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas se
  puedan repetir. Los instantes se cuentan en minutos.
- Tú defines: la duración exacta de cada tipo dentro de los rangos del original; cuánto
  dura la preparación y la limpieza (el original no da cifra); cuántas citas de más
  tolera una franja; qué preferencias son duras y cuáles se pueden ceder; cuánto aviso
  mínimo hace falta para ofrecer un hueco; cuánto atraso admite reenviar un recordatorio;
  y cuántas inasistencias hacen sospechoso a un paciente.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Equipos compartidos (ultrasonido, sala de procedimientos) como otro recurso a repartir.
- Pacientes que necesitan dos citas encadenadas (estudio y luego consulta con resultado).
- Médico que atiende en varias clínicas y necesita tiempo de traslado entre ellas.
- Teleconsulta que no ocupa consultorio pero sí al médico.

---
*Las cifras son de referencia (órdenes de magnitud) y vienen del problema original.
Verifica la fuente vigente antes de citarlas en tu entrega.*
