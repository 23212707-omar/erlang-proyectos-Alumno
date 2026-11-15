# #63 — Reservas de hotel: gemelo digital con programación lógica

> Extensión del proyecto #63. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el hotel: un calendario por tipo de habitación, una
reserva como máquina de estados y una prueba de caos donde varias reservas compiten por
el último cuarto. Esa simulación responde «¿quién ganó?». El hotel necesita algo más:
«¿se puede vender este rango, por qué no, y a quién se le falla cuando dos tienen razón?».

El gemelo digital es el **modelo lógico** del hotel: hechos que reflejan su inventario y
sus reservas, y reglas que reflejan cómo se decide si una noche, un rango o un cuarto
se pueden vender. Se escribe en Prolog porque lo que hay que resolver aquí no es contar
cuartos, sino acomodar sin contradicciones, justificar y saber decir «no lo sé».

## El hotel que se clona

Un hotel mediano de Rosarito, reducido a 3 tipos de habitación (sencilla, doble, suite)
y un calendario corto. Se reserva por **tipo** y la habitación física se asigna después.

| Parte | Contenido |
|---|---|
| Entidades | hotel → tipo de habitación → habitación física; reservas; solicitudes; canales (directo, agencia en línea) |
| Estado por tipo y noche | cuántas reservas lo ocupan; cuántas retenciones siguen vigentes; cuántos cuartos están fuera de servicio |
| Estado por reserva | tipo, llegada, salida, tarifa pactada, en qué etapa va (en proceso, confirmada, en casa, cancelada) y cuarto asignado, si ya lo tiene |
| Políticas (del original) | check-in 15:00 y check-out 12:00; retención de 10-15 min mientras se paga; cancelación gratuita hasta 48 h antes; sobreventa de 3-10 % con política de reubicación |
| Eventos | llega una solicitud, se retiene, se paga o expira la retención, se cambia o se cancela una reserva, llega el huésped, un cuarto se daña |
| Decisiones | ¿se puede vender este rango?, ¿a quién le toca el último cuarto?, ¿esta sobreventa es intencional?, ¿a qué cuarto se reasigna?, ¿procede este cambio de fechas? |

## Situaciones que tu gemelo debe razonar

Las cinco parten del problema original (sus casos difíciles, su escenario, sus preguntas
guía y sus datos del mundo real). Lo que cada una añade sin cifras se dice en su texto.
En cada una, tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — Cinco noches y la tercera está llena

- **Qué pasa.** Una familia que viene a una cirugía en Tijuana pide cinco noches en
  doble. Con una noche llena basta para no poder vender el rango. Otra clienta paga en
  este momento y su retención ocupa cupo mientras dure; si vence y la pasarela de pago
  no ha contestado, nadie sabe si esa noche está libre. Y otra reserva sale el mismo día
  en que alguien más llega al último cuarto. Si el gemelo se equivoca, hay una familia
  en el lobby o una venta perdida.
- **Qué datos hay.** Cuartos por tipo, reservas con llegada y salida, eventos de
  retención y pago con su instante, el «ahora». Nadie guarda «noches libres»: ningún
  dato dice si un rango se puede vender.
- **Qué debe deducir.** El cupo de cada noche del rango y, de ahí, el del rango entero;
  qué noche lo impide; qué retención deja el cupo en duda; y si la reserva que sale un
  día choca con la que llega ese mismo día.
- **Qué debe contestar.** «Sí», «no» o «no se sabe», con la noche responsable. Lo
  intuitivo es contar como ocupada la noche del día de salida; es sospechoso por los
  horarios de check-out y check-in. También, qué rangos cercanos sí caben y qué tendría
  que liberarse para que el pedido quepa.
- **Por qué es lógica.** La disponibilidad de un rango es una conjunción de noches que
  nadie mide, y «no hay cupo» y «no sé si hay cupo» son respuestas distintas.

### Situación 2 — Dos reservas, un último cuarto

- **Qué pasa.** Fin de semana de convención: la mayoría de las noches ya está vendida y
  queda un solo cuarto doble. Dos solicitudes lo piden casi al mismo tiempo. Una entra
  directo, con la retención vigente y pocos minutos de los 10-15 que dura. La otra viene
  de una agencia en línea que confirmó a su cliente con una consulta de disponibilidad de
  hace rato (las agencias consultan cientos de veces por cada reserva real). Una pide una
  noche; la otra, cuatro, y una de ellas es esa noche. Las dos tienen razón.
- **Qué datos hay.** Las solicitudes con su canal y el instante en que se capturaron,
  los eventos de retención, la hora de la última consulta de la agencia y el cuarto
  restante.
- **Qué debe deducir.** Qué conjuntos de solicitudes caben a la vez sin repetir cuarto
  ninguna noche, y cuáles repartos son válidos cuando no caben todas.
- **Qué debe contestar.** El reparto completo; a quién se le falla y con qué criterio
  de desempate, declarado, no escondido; los demás repartos válidos si los hay; y qué
  cambiaría el resultado (por ejemplo, que la retención venza).
- **Por qué es lógica.** No se busca ganador por solicitud sino un acomodo que cumpla
  todo a la vez, y el desempate debe poder leerse y discutirse.

### Situación 3 — El cuarto dañado

- **Qué pasa.** Una doble queda inutilizable por varias noches. Hay un huésped alojado
  en ella y reservas futuras de doble que contaban con ese cuarto. El hotel quiere
  reasignar sin afectar al huésped: que no pierda noches, que no pague más y, si se puede,
  que no cambie de cuarto a media estancia. En juego: un huésped molesto en plena
  estancia, o una reserva futura sin cuarto.
- **Qué datos hay.** Habitaciones físicas por tipo, cuartos fuera de servicio y desde
  cuándo, reservas con su cuarto asignado, si ya lo tienen, y el calendario de las
  siguientes noches.
- **Qué debe deducir.** La capacidad real por tipo y noche tras el daño; qué noches
  quedan sin cupo por culpa del daño; quiénes están afectados directamente y quiénes por
  arrastre; y qué cuartos del mismo tipo (o de otra categoría) están libres **todas** las
  noches que el afectado necesita.
- **Qué debe contestar.** La lista de afectados con la cadena que los alcanza, un plan
  de reasignación completo, y los planes alternos. Si no existe ninguno, lo dice y señala
  la noche que lo impide, sin fallar en silencio.
- **Por qué es lógica.** Un cuarto dañado cambia varias reglas a la vez, y reasignar es
  encadenar deducciones con restricciones de continuidad.

### Situación 4 — ¿Sobreventa a propósito o error?

- **Qué pasa.** Los hoteles venden por encima de su capacidad porque algunos cancelan o
  no llegan, y deben tener una política de reubicación para cuando todos llegan. El
  sábado de la convención las ventas de dobles rebasan los cuartos. Puede ser decisión
  del hotel o un error de dos ventas simultáneas sin coordinar. Otra noche tiene menos
  ventas que cuartos en papel, pero varios están fuera de servicio. Si es error, hay un
  huésped sin cuarto; si es intencional, el hotel debe pagar la reubicación.
- **Qué datos hay.** Ventas por noche y tipo, autorizaciones de sobreventa registradas
  (quién, qué margen, cuándo), cuartos fuera de servicio, cancelaciones con su política
  de 48 h y los eventos de cada venta con su instante.
- **Qué debe deducir.** Contra la capacidad **efectiva**, no la nominal, qué noches están
  por encima; cuáles de esas están dentro de un margen autorizado y cuáles no; y qué
  noches están sobrevendidas aunque parezcan tener lugar.
- **Qué debe contestar.** Por noche y tipo: «intencional», «error» o «no se sabe» (la
  sobreventa existe pero falta el registro de quién la autorizó), con la evidencia. Y, si
  todos llegan, cuántos quedarían sin cuarto y con qué reubicación.
- **Por qué es lógica.** Nada marca una sobreventa como intencional o errónea: se deduce
  de varios datos, y «no autorizada» no es lo mismo que «no registrada».

### Situación 5 — Cambiar fechas sin perder el precio

- **Qué pasa.** Una clienta con reserva del 10 al 14 pide pasarla al 12-16 y que le
  respeten el precio original. Dos de las noches nuevas están llenas, en parte por la
  propia reserva. Las dos últimas son de convención, con tarifa más alta, y falta poco
  para la llegada: la cancelación gratuita llega hasta 48 h antes. En juego: la clienta
  paga de más o pierde su fecha, o el hotel regala noches de las caras.
- **Qué datos hay.** La reserva con su tarifa pactada, la lista de precios vigente por
  noche, los eventos de la reserva con su instante y el «ahora».
- **Qué debe deducir.** El cupo del rango nuevo sin contar dos veces lo que la reserva
  ya ocupa; si el cambio cae dentro o fuera de la ventana gratuita; y el importe que
  resulta, según lo que declares que significa «mantener el precio».
- **Qué debe contestar.** Si el cambio procede, noche por noche con qué precio, con qué
  penalización si la hay, y qué pasaría con otra interpretación de «mantener el
  precio». Lo intuitivo es que las noches llenas impiden el cambio; es sospechoso si
  esas noches están llenas por la propia reserva.
- **Por qué es lógica.** La reserva es entidad y parte del inventario a la vez: una
  conclusión que cambia según el estado de la propia reserva y de la política.

## Por qué no basta un script

Con `if disponibles[tipo][noche] > 0: reservar()` vendes una noche con datos perfectos y
sin competencia. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Puedo vender la doble del 10 al 14? | decisión |
| ¿Por qué no? ¿Qué noche lo impide? | explicación |
| ¿Qué rangos de cinco noches caben en doble este mes? | todas las respuestas |
| ¿Qué tendría que liberarse para que quepa? | la pregunta al revés |
| ¿Qué pasa si se daña otra doble el viernes? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué se bloquea al reservar un rango de fechas y por cuánto tiempo?
2. ¿Cómo decide tu gemelo cuándo la sobreventa es intencional y cuándo es un error?
3. ¿Qué hechos necesitas para saber cuántos cuartos quedan una noche, y cuáles **no**
   deberías guardar?
4. ¿Cómo distingue tu gemelo «no hay cupo» de «no sé si hay cupo»?
5. En Erlang un proceso por tipo serializa su calendario y la prueba de caos hace que
   las reservas compitan por el último cuarto. ¿Qué decide ese proceso que tu gemelo
   no, y qué explica tu gemelo que el proceso no puede?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del hotel, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la
  decisión con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar solicitudes simuladas
  o graficar la ocupación.

## Supuestos de esta extensión

- Escala reducida: 12 habitaciones (5 sencillas, 5 dobles y 2 suites) y 14 noches,
  contra las 120 habitaciones, 4 tipos y 90 días del escenario original.
- Los días del ejemplo, los números de reserva, los precios y las cantidades de las
  situaciones son del ejercicio, no datos del hotel real. «Del 10 al 14» viene del
  original; el «12-16» de la situación 5 y el resto son nuestros.
- El «ahora» es un hecho del modelo, en minutos desde la medianoche del primer día del
  calendario, no el reloj del sistema, para que las respuestas se puedan repetir.
- Tú defines: el margen exacto de sobreventa dentro del 3-10 % de referencia, cuántos
  minutos dura la retención dentro de 10-15, cuánto se espera a una pasarela que no
  contesta, el criterio de desempate de la situación 2, qué significa «mantener el
  precio», cuánto es la penalización y si una categoría superior puede ofrecerse a un
  huésped reasignado. Decláralos como supuestos.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Bloques de cuartos para una convención y la fecha en que se liberan los no usados.
- Lista de espera cuando un rango se llena y alguien cancela.
- Habitaciones conectadas para familias numerosas.
- Reubicar a un huésped en otro hotel y hacerse cargo de la diferencia.
- Auditoría de reembolsos: demostrar por qué se cobró o se perdonó cada penalización.

---
*Las cifras de dominio (horarios de check-in y check-out, retención de 10-15 min,
cancelación gratuita hasta 48 h, sobreventa de 3-10 %, noches del ejemplo) son de
referencia y vienen del problema original. Verifica la fuente vigente antes de citarlas
en tu entrega. La escala del hotel y los números de los ejemplos son del ejercicio.*
