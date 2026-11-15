# #39 — Sala de urgencias: gemelo digital con programación lógica

> Extensión del proyecto #39. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).
> Es una simulación educativa de gestión de colas, no un dispositivo médico: nada de lo
> que decida tu gemelo es consejo clínico.

## Del simulador al gemelo

En la parte de Erlang simulaste la sala: pacientes que llegan, una cola por prioridad,
consultorios que se ocupan y se liberan. Esa simulación responde «¿quién sigue?». Quien
coordina el turno necesita algo más: «¿a quién le vamos a fallar, por qué, y estaba en
nuestras manos evitarlo?».

El gemelo digital es el **modelo lógico** de la sala: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque lo que hay que
resolver aquí no es ordenar una lista, sino deducir, justificar y reconocer cuándo un
dato no alcanza para decidir.

## La sala que se clona

Una sala de urgencias de un hospital general de Tijuana, con los 5 médicos y las 12
camillas del escenario original y unos 20 pacientes en pantalla en lugar de 100 llegadas
en 12 horas. Los pacientes y sus números de ejemplo son ilustrativos; los límites de
espera por nivel, el accidente de 8 heridos y el verde que empeora vienen del original.

| Parte | Contenido |
|---|---|
| Entidades | pacientes, médicos, camillas, y las camas del hospital (otro sistema, fuera de urgencias) |
| Niveles | rojo (inmediato), naranja (hasta 10 min), amarillo (hasta 60), verde (hasta 120), azul (hasta 240) |
| Estado por paciente | nivel vigente, minuto de llegada, tomas de signos con su minuto, quién lo atiende y desde cuándo, si está de alta o con ingreso pendiente |
| Estado por recurso | médico libre u ocupado y con quién; camilla según urgencias y según el hospital |
| Eventos | llega alguien, se clasifica, se repite el triage, empieza o termina una atención, alta de urgencias, ingreso pendiente de cama, llega un accidente |
| Decisiones | ¿quién sigue?, ¿cuál es su nivel hoy?, ¿qué camillas están libres de verdad?, ¿está saturada la sala?, ¿a quién se le falló y por qué? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original: el accidente de 8 heridos, el verde que empeora,
la inanición contra la gravedad, el desbordamiento por camas ocupadas y la medición de la
saturación. Lo que el original no dice (qué miden los signos, cómo se registran las altas,
qué se audita al final del turno) lo añade esta extensión como complemento. En cada una,
tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — Ocho heridos y cinco médicos

- **Qué pasa.** Un accidente carretero deja 8 heridos que llegan al mismo tiempo, cuando
  la sala ya tiene pacientes esperando y médicos atendiendo. Hay 12 camillas y 5 médicos.
  Un médico que deja a su paciente por un herido le falla a ese paciente.
- **Qué datos hay.** El nivel de cada herido tras su triage, quién esperaba y desde cuándo,
  qué médico atiende a quién y desde cuándo, las camillas ocupadas y el «ahora». Cuánto
  dura una atención por nivel no lo da el original: lo fijas tú.
- **Qué debe deducir.** Quiénes, entre heridos y pacientes previos, pueden ser atendidos
  dentro del límite de su nivel con los médicos que hay, y quiénes ya no, aunque todo se
  haga bien. Ningún dato dice «no alcanzamos»: sale de combinar niveles, límites, tiempos
  y médicos. Lo intuitivo es «hay 12 camillas y 8 heridos, caben». Es sospechoso porque
  una camilla no atiende a nadie.
- **Qué debe contestar.** El reparto completo de médicos y camillas, con las demás
  alternativas válidas; a quién se le falla y por qué ese y no otro. Si ningún reparto
  cumple todos los límites, lo dice y señala el motivo en lugar de fallar en silencio.
- **Por qué es lógica.** Son restricciones sobre recursos finitos con prioridades en
  conflicto; un reparto se verifica contra las reglas, no se calcula con una fórmula.

### Situación 2 — El verde que ya no es verde

- **Qué pasa.** El paciente 14 fue clasificado verde y lleva 90 minutos en espera. En el
  triage periódico, sus signos cambiaron frente a la toma anterior. Mientras, el paciente
  17, también verde, no tiene una sola toma desde que llegó, y su acompañante insiste en
  que está peor. Un empeoramiento que nadie vio es un fallo de la sala.
- **Qué datos hay.** El nivel con que entró cada uno, su llegada, sus tomas de signos con
  el minuto (pueden faltar o no cuadrar), lo que dice el acompañante y el «ahora». Cada
  cuánto debe repetirse el triage y qué cambio de signos cuenta como empeorar no lo dice
  el original: lo defines tú.
- **Qué debe deducir.** Si cada uno empeoró, a qué nivel pasa, desde cuándo corre el
  límite del nivel nuevo, si el triage periódico se cumplió y a quién desplaza al subir.
  Ningún sensor mide «empeoró»: sale de comparar tomas. Lo intuitivo es «lleva 90 de 120,
  aún le quedan 30». Es sospechoso porque el 120 pertenecía a un nivel que ya no tiene.
- **Qué debe contestar.** El nivel vigente y por qué; «sí», «no» o «no lo sé» sobre si
  empeoró (el 17 no es «estable»: nadie lo ha medido); qué toma falta; a quién desplaza.
- **Por qué es lógica.** «Verde» es una conclusión que se retira cuando llega evidencia
  nueva, y la falta de dato no equivale a «sin cambios».

### Situación 3 — La espera que no termina

- **Qué pasa.** Una noche de mucha gente, un médico queda libre. Compiten tres: un naranja
  recién clasificado, un verde que ya rebasó el límite de su nivel y un azul que está a
  punto de rebasarlo. Si la gravedad manda siempre, nadie de nivel bajo pasa jamás; si
  manda el tiempo, un grave espera mientras otro más leve ya sufrió. Ambos tienen razón.
- **Qué datos hay.** Nivel, llegada, espera acumulada y límite de cada paciente; quién se
  libera y cuándo; cuántos esperan detrás. Cuánto se atiende cada nivel lo fijas tú.
- **Qué debe deducir.** El orden en que atender, cuál de los tres no llegará a tiempo
  pase lo que pase, y si alguien lleva tanto sin pasar que ya es un caso de inanición,
  aunque su límite no haya vencido. Lo intuitivo es «el más grave primero, siempre». Es
  sospechoso porque entonces el azul no pasa nunca mientras sigan llegando graves.
- **Qué debe contestar.** El orden, a quién se le falla, la regla que decidió y qué
  tendría que cambiar (otro médico libre, una llegada menos) para que el afectado pase.
- **Por qué es lógica.** Dos criterios legítimos chocan; la prioridad se declara una vez
  y vale para todos los casos, y la justificación de a quién se falla sale de ella.

### Situación 4 — La camilla que el tablero da por libre

- **Qué pasa.** Un paciente ya atendido tiene ingreso ordenado, pero el hospital no tiene
  cama: sigue en su camilla de urgencias. Urgencias lo capturó como «alta» y el tablero
  marca la camilla libre; el sistema de camas del hospital lo marca «pendiente de cama».
  Dos sistemas no se ponen de acuerdo, y llega un rojo.
- **Qué datos hay.** La ocupación de las 12 camillas según urgencias, el estado de cada
  paciente ya atendido (alta, ingreso pendiente), las camas del hospital y la hora de
  cada registro. Algunas capturas se hicieron a mano y pueden estar equivocadas.
- **Qué debe deducir.** Cuántas camillas están libres de verdad, cuáles tienen dueño
  aunque el tablero diga lo contrario y cuál de los dos registros merece más crédito.
  Orden de ingreso y falta de cama implican que sigue en la camilla, que la camilla no
  está disponible y que el rojo no tiene lugar: tres deducciones encadenadas. Lo
  intuitivo es «el tablero marca camillas libres, hay lugar».
- **Qué debe contestar.** Cuántas camillas hay realmente, con la explicación de cada una;
  «no lo sé» donde los registros se contradicen sin forma de saber cuál es el cierto;
  dónde puede quedar el rojo y qué habría que mover para que fuera posible.
- **Por qué es lógica.** El estado real se deduce de varias fuentes que pueden
  contradecirse, y una conclusión se retira cuando se aclara una de ellas.

### Situación 5 — ¿Está saturada la sala?

- **Qué pasa.** La jefa de turno quiere saber si hay saturación antes de que sea tarde, y
  a la mañana siguiente la dirección pregunta por cada paciente que esperó más que su
  límite: ¿faltó capacidad o se decidió mal? Una tarde hay camillas libres y todos los
  médicos con pacientes graves mientras otros esperan; otra, las 12 camillas están
  llenas y la sala funciona porque varios ocupantes ya están atendidos y solo esperan una cama.
- **Qué datos hay.** Llegadas y atenciones del turno con su minuto, la espera por nivel
  (de la llegada al médico), quién rebasó su límite, médicos libres, camillas ocupadas
  por pacientes ya atendidos y el «ahora». Qué cuenta como saturación no lo da el
  original: lo defines tú.
- **Qué debe deducir.** Si la sala está saturada, desde qué minuto lo estaba y qué señal
  lo delató primero. Ningún dato mide «saturación»: sale de varios a la vez. Para cada
  paciente que rebasó su límite, si era inevitable con los recursos de ese momento o si
  otra orden de atención lo habría evitado. Lo intuitivo es medir las camillas llenas.
- **Qué debe contestar.** «Sí», «no» o «no lo sé» con la evidencia; el primer momento de
  alerta; la lista de incumplimientos con su causa; y la hipótesis: qué habría pasado si
  los 8 heridos hubieran llegado a esa hora.
- **Por qué es lógica.** Una conclusión que no vive en ningún sensor, y una auditoría que
  repite las decisiones con las mismas reglas para ver qué cambia.

## Por qué no basta un script

Con `if nivel == "rojo": atender_primero()` resuelves una sala con un solo recurso y datos
perfectos. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿A quién atiende el médico que se acaba de liberar? | decisión |
| ¿Por qué el paciente 14 ya no es verde? | explicación |
| ¿Cuáles pacientes no llegarán a tiempo con el reparto actual? | todas las respuestas |
| ¿Qué tendría que pasar para que el azul pase antes que el amarillo? | la pregunta al revés |
| ¿Qué pasaría si llegan los 8 heridos ahora? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Cómo evitas que un nivel bajo espere para siempre sin comprometer a los graves, y
   dónde queda escrito?
2. ¿Qué señal te avisa primero de que la sala se saturó, y por qué no basta con contar
   camillas?
3. ¿Cómo distingue tu gemelo «estable» de «nadie lo ha revisado»?
4. ¿Qué parte de la explicación le sirve a la jefa de turno y qué parte es ruido?
5. Tu simulación en Erlang hace pasar al frente una emergencia de nivel 1 con la cola
   llena. ¿Qué le preguntarías al gemelo después, para saber a quién se le falló?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la sala, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar llegadas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: unos 20 pacientes en pantalla, contra las 100 llegadas en 12 horas del
  escenario original. Los 5 médicos, las 12 camillas y los 8 heridos son los del original.
- El hospital, los números de paciente y los casos de los ejemplos (14, 17, el rojo que
  llega) son ilustrativos; tú los ubicas en tu escenario.
- El «ahora» es un hecho del modelo, en minutos, no el reloj del sistema, para que las
  respuestas se puedan repetir.
- El original no da, y por tanto son decisiones tuyas, declaradas: cuánto dura una
  atención por nivel, cada cuánto se repite el triage, qué cambio de signos cuenta como
  empeorar, desde cuándo corre el límite de un nivel al que se sube, qué cuenta como
  saturación y cuánto sin pasar es inanición.
- Qué datos define el estudiante: el catálogo de signos y sus rangos, las altas y los
  ingresos pendientes, y qué registro prevalece cuando dos sistemas se contradicen.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Quirófano, laboratorio y rayos X como recursos compartidos que alargan la atención.
- Enfermeras de triage y su carga cuando llegan muchos pacientes a la vez.
- Pacientes que se van sin ser atendidos y qué hace el gemelo con su lugar.
- Pacientes que requieren un tipo de médico específico o un familiar que los acompañe.
- Traslado a otro hospital cuando la sala no puede recibir más.

---
*Las cifras son de referencia y vienen del problema original (los límites por nivel, los
5 médicos, las 12 camillas, los 8 heridos, los 90 minutos y las 100 llegadas en 12 horas).
Verifica la fuente vigente antes de citarlas en tu entrega.*
