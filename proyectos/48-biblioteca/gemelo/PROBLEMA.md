# #48 — Biblioteca: gemelo digital con programación lógica

> Extensión del proyecto #48. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la biblioteca: un proceso por préstamo que pasa de activo a
vencido y devuelto, una cola de reservas por libro y un calculador de multas. Esa
simulación responde «¿en qué estado está este préstamo?». Quien atiende el mostrador, y el
alumno que espera un libro antes de su examen, necesitan algo más: «¿le presto o no, a quién
le toca el libro, cuánto debe, y por qué?».

El gemelo digital es el **modelo lógico** de la biblioteca: hechos que reflejan dónde está
cada ejemplar y quién espera por él, y reglas que reflejan cómo se decide en el mostrador.
Se escribe en Prolog porque aquí no se cuentan días: se deduce quién tiene derecho a qué,
se justifica a quién se le falla y se distingue «no debe» de «no sé si debe».

## La biblioteca que se clona

Una biblioteca universitaria de Tijuana, reducida a unos 8 títulos con unos 12 ejemplares,
unos 8 alumnos, 2 mostradores y una cola de unas 6 reservas. Es la simulación del problema
original; lo que se añade está listado en «Supuestos».

| Parte | Contenido |
|---|---|
| Entidades | título (ISBN) → ejemplar (código de barras, con su material); alumnos; mostradores; préstamos, renovaciones, reservas y multas |
| Estado por ejemplar | disponible, prestado, devuelto sin revisar, dañado o perdido; material (general o de sala) |
| Estado por préstamo | alumno, ejemplar, fecha de salida, renovaciones concedidas, devolución registrada o no |
| Estado por reserva | alumno, título, instante de la solicitud, aviso enviado y su estado, apartada o no |
| Estado por alumno | libros que trae, multas pendientes y pagadas, si está bloqueado |
| Eventos | se presta; se renueva; se devuelve (a tiempo, tarde o dañado); se declara perdido; se reserva; se avisa; se recoge o no; se paga una multa |
| Decisiones | ¿se presta?, ¿se renueva?, ¿cuánto se debe?, ¿a quién le toca el libro?, ¿qué se hace con lo que nadie recoge o con lo que no regresa? |

## Situaciones que tu gemelo debe razonar

Las cinco parten del problema original (sus casos difíciles, su escenario a simular, sus
datos del mundo real y sus preguntas guía); los complementos que el original no trae van
señalados. En cada una, tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — La multa que el almanaque no calcula

- **Qué pasa.** Un alumno con multa pendiente intenta pedir un libro, como en el escenario
  del original. Su último préstamo venció hace unos días y en medio hubo días en que la
  biblioteca no abrió. Para colmo, jura que ya devolvió ese libro y el registro no
  aparece. En juego: una multa que quizá no corresponde y un alumno sin libro ante examen.
- **Qué datos hay.** Préstamos con su fecha de salida, el material de cada ejemplar,
  renovaciones concedidas, el calendario de días inhábiles, devoluciones registradas con su
  instante, pagos de multa y la tarifa. Ningún dato dice «debe» ni «bloqueado».
- **Qué debe deducir.** Cuándo vence cada préstamo, cuáles días de retraso generan multa,
  cuánto se debe por préstamo y en total una vez descontado lo pagado, si el alumno queda
  bloqueado, y si lo que pide ahora se le puede prestar.
- **Qué debe contestar.** Prestar, no prestar o «no se sabe» (la devolución sin registro no
  se da por cierta ni por falsa), con cada préstamo que pesa en la respuesta, y qué
  tendría que pasar para desbloquearlo. Lo intuitivo es restar dos fechas y multiplicar
  por la tarifa; pero el calendario de la biblioteca no es el del almanaque.
- **Por qué es lógica.** El adeudo no es un dato: se deduce en cadena (vencimiento, días
  que cuentan, multa, adeudo neto, bloqueo). Y «no debe» no es «no consta que deba».

### Situación 2 — Dos mostradores, un solo ejemplar

- **Qué pasa.** Dos bibliotecarios prestan el mismo ejemplar casi a la vez (primer caso
  difícil del original). Cada alumno salió convencido de que lo tiene, pero físicamente
  solo uno lo trae. Cada mostrador capturó su registro con su propia hora, y el sistema
  los recibió en un orden que no necesariamente es el de lo ocurrido. Mientras tanto, otro
  alumno apartó ese título. Hay dos alumnos de buena fe y uno de ellos pierde.
- **Qué datos hay.** Los eventos del ejemplar con su hora, su mostrador y el orden en que
  llegaron, el último estado del ejemplar antes del conflicto (si se devolvió y se revisó),
  las reservas del título y, si ya lo hubo, el resultado de buscarlo físicamente.
- **Qué debe deducir.** Si la secuencia de estados del ejemplar es posible tal como está
  registrada, cuáles registros son compatibles entre sí, a quién corresponde el ejemplar
  según lo que se sabe y qué es lo que no se sabe.
- **Qué debe contestar.** El estado del ejemplar («prestado a tal alumno» o «en conflicto:
  no se sabe») y, para el alumno que no se queda con el libro, qué se le dice y qué lugar
  de la cola le toca. Lo intuitivo es «gana el registro con la hora más temprana»; pero
  son dos relojes, y lo que llegó primero al sistema no es lo que ocurrió primero.
- **Por qué es lógica.** Una secuencia válida de estados es una restricción, y dos hechos
  incompatibles no se resuelven sumándolos: hay que decir qué consta y qué no.

### Situación 3 — Veinticinco esperan un libro

- **Qué pasa.** Un título con un solo ejemplar y 25 reservas, como en el escenario del
  original; en finales hay más de 10 personas por ejemplar. El ejemplar está prestado y
  vence en unos días. La alumna del último lugar pregunta «¿cuándo me toca?». Cuando el
  libro regresa, puede volver dañado; o puede no volver y declararse perdido. Y a quien
  iba primero en la cola ya le cayó un bloqueo o ya trae el máximo de libros.
- **Qué datos hay.** Reservas con su instante, el préstamo vigente del ejemplar y su
  vencimiento, el resultado de la revisión del ejemplar al regresar, los préstamos y
  bloqueos de cada alumno que espera, y cuántos ejemplares tiene el título.
- **Qué debe deducir.** El lugar real de cada reserva (no el de la lista, si alguien no
  puede recibir el libro), a quién se avisa primero cuando haya ejemplar, cuándo podría
  tocarle como pronto a cada una y qué cambia si el ejemplar regresa dañado o no regresa.
- **Qué debe contestar.** Por reserva: su lugar, quién es la siguiente que sí puede
  recibirlo y un rango de espera o «no se sabe»; y, si el libro se pierde, qué pasa con
  las 25 y por qué. Lo intuitivo es «la alumna 25 espera 25 plazos»; pero el orden de la
  lista no es el de entrega, y un ejemplar dañado o perdido no se entrega a nadie.
- **Por qué es lógica.** La espera no se mide con ningún dato: se deduce de la cola, del
  vencimiento, de las renovaciones y de quién puede recibir el libro.

### Situación 4 — La reserva que nadie recogió

- **Qué pasa.** El libro regresó y se avisó a la siguiente de la cola; se le apartó por 48
  horas (caso difícil del original). Pasó ese plazo y no llegó. Pero en el intervalo hubo
  días con la biblioteca cerrada y el aviso consta como «enviado», no como «recibido». El
  alumno que sigue en la cola lleva semanas esperando y tiene examen pronto.
- **Qué datos hay.** La reserva con su estado, el aviso con su estado y su instante, el
  calendario de días inhábiles, la cola detrás de ella y el «ahora».
- **Qué debe deducir.** Si el plazo realmente venció, si la alumna no recogió o no se
  enteró, a quién pasa el ejemplar y qué hacer si ella aparece después de que se liberó.
- **Qué debe contestar.** Conservar, liberar al siguiente o «no se sabe», con la razón; y,
  si se liberó, qué lugar le toca a quien llega tarde. Lo intuitivo es «pasaron 48 horas,
  se libera»; pero no en todas esas horas se podía recoger, y enviado no es recibido.
- **Por qué es lógica.** Las dos partes tienen razón, y «no recogió» y «no pudo
  enterarse» llevan a respuestas distintas que el gemelo no debe confundir.

### Situación 5 — Renovar el libro que otros esperan

- **Qué pasa.** El original dice que la renovación se permite «si nadie lo ha apartado» y
  que cada alumno tiene un tope de libros a la vez. Un alumno pide renovar un libro de
  texto en semana de exámenes. Las reservas se hacen por título, no por ejemplar: ninguna
  señala su ejemplar, pero el título tiene reservas pendientes. Hay otro ejemplar «libre»
  en el estante, que resulta ser de sala o estar en revisión.
- **Qué datos hay.** El préstamo y sus renovaciones previas, el material y estado de cada
  ejemplar del título, las reservas pendientes, el vencimiento actual, y las multas y los
  libros que trae el alumno.
- **Qué debe deducir.** Cuántos ejemplares del título se pueden prestar de verdad, si las
  reservas quedan sin atender si renueva, y si el alumno cumple lo demás para renovar.
- **Qué debe contestar.** Renovar, negar o «no se sabe» (ejemplar en revisión sin
  resultado), con la causa, y qué tendría que cambiar para que se pudiera. Lo intuitivo es
  «hay un ejemplar en el estante»; pero estar en el estante no es estar disponible.
- **Por qué es lógica.** Choca el derecho de quien ya tiene el libro con el de quien
  espera, y las prioridades se declaran una vez y valen para todos los casos.

## Por qué no basta un script

Con `if dias_retraso > 0: multa = dias_retraso * tarifa` resuelves un préstamo con datos
perfectos. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Puede el alumno 5 sacar un libro hoy? | decisión |
| ¿Por qué no? | explicación |
| ¿Qué alumnos están bloqueados hoy? | todas las respuestas |
| ¿Qué tendría que pasar para que el alumno 5 pudiera sacar un libro? | la pregunta al revés |
| ¿Qué pasaría si el ejemplar del título A se declara perdido hoy? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Quién es el dueño del estado de un ejemplar: el préstamo, la reserva o el propio
   ejemplar? ¿Cómo evita tu gemelo que dos hechos lo contradigan?
2. ¿Qué pasa con la cola de reservas cuando se pierde el libro? ¿Dónde queda escrito?
3. Cuando la primera de la cola no puede recibir el libro, ¿qué le dices a ella y qué le
   dices a la siguiente?
4. ¿Cómo distingue tu gemelo «no recogió» de «no se enteró», y «no pagó» de «el pago no se
   registró»?
5. ¿Qué eventos de tu simulación en Erlang (estados del préstamo, cola de reservas por
   libro, calculador de multas) podrían alimentar a este gemelo como hechos?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la biblioteca, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar préstamos simulados o
  graficar.

## Supuestos de esta extensión

- Escala reducida: unos 8 títulos, unos 12 ejemplares, unos 8 alumnos, 2 mostradores y
  una cola de unas 6 reservas, contra los 10,000 ejemplares, 3,000 usuarios, 300 préstamos
  al día y 25 reservas del escenario original.
- El «ahora» es un hecho del modelo, en horas, no el reloj del sistema. Los
  identificadores de los ejemplos («alumno 5», «título A») son ilustrativos.
- El calendario concreto de días inhábiles, el mostrador que captura cada registro, los
  avisos con estado, la revisión de los ejemplares y la mezcla de ejemplares de sala y
  generales dentro de un título son complementos de esta extensión, no del original.
- Los define y verifica el estudiante, porque el original no los da: el plazo exacto de
  cada material, la tarifa y el tope de libros dentro de los rangos del original, a
  partir de qué adeudo se bloquea, si los días
  inhábiles generan multa, cuántas renovaciones caben, cuándo un libro vencido se da por
  perdido, qué cuenta como horas de plazo de una reserva, y cómo se ordena lo que llega a
  la vez de dos mostradores.

## Extensiones posibles

Fuera del problema original: investiga y cita tus fuentes antes de fijar cifras.

- Distintos tipos de usuario (alumno, docente) con límites diferentes.
- Reposición de un libro perdido o pago de su valor, y qué pasa con la multa acumulada.
- Ejemplares en encuadernación o reparación y su regreso a circulación.
- Préstamo entre bibliotecas para un título sin ejemplares libres.
- Avisos de vencimiento próximo y su efecto sobre quién renueva.

---
*Las cifras (préstamo de 3 a 15 días; reserva de sala de 2 a 3 días y general de 7 a 15;
3 a 5 libros a la vez; multa de $5 a $10 MXN por día; 1 a 20 ejemplares por obra; más de
10 personas por ejemplar en finales; 10,000 ejemplares, 3,000 usuarios y 300 préstamos al
día; un título con 1 ejemplar y 25 reservas; 48 horas de apartado) son de referencia y
vienen del problema original. Verifica la fuente vigente antes de citarlas en tu entrega.*
