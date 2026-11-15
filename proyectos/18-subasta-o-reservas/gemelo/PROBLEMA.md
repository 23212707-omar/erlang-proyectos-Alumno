# #18 — Subasta o reservas: gemelo digital con programación lógica

> Extensión del proyecto #18. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang un proceso por subasta serializaba las pujas, un reloj cerraba la
subasta y, con mil pujas simultáneas, nunca se adjudicaba dos veces. Esa simulación
responde «¿se asignó una sola vez, y rápido?». Quien administra la plataforma necesita
algo más: «¿esta puja es válida, quién ganó, y se lo puedo demostrar a quien perdió?».

El gemelo digital es el **modelo lógico** de la casa de subastas: hechos que reflejan su
estado y reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque aquí lo
difícil no es ser rápido, sino que cada adjudicación tenga una sola respuesta y una
explicación que aguante una queja.

## La casa de subastas que se clona

La plataforma del problema original, que remata lotes y vende lugares con reservación,
reducida a unos pocos lotes y a un evento. Los lotes, el evento y las personas son
ejemplos ilustrativos del ejercicio.

| Parte | Contenido |
|---|---|
| Entidades | lotes en subasta (una guitarra de colección, una tabla de surf firmada); postores; un evento con lugares limitados (una cena de maridaje en el Valle de Guadalupe); solicitantes, holds y pagos |
| Estado por subasta | cierre publicado, pujas recibidas, máximos de puja automática (secretos), incremento mínimo, extensión de cierre |
| Estado por evento | lugares totales, solicitudes en orden de llegada, holds con su inicio y duración, pagos con la hora en que se registraron y, a veces, el sello del banco |
| Eventos | llega una puja o un reintento; se registra un máximo automático; se acerca o pasa el cierre; se reinicia el sistema; se abre un hold, vence, se paga o se libera un lugar |
| Decisiones | ¿es válida esta puja?, ¿cuál es el cierre real?, ¿quién lidera y a qué precio?, ¿a quién se adjudica?, ¿quién tiene el lugar?, ¿qué puedo afirmar de lo que no quedó anotado? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original (casos difíciles, escenario a simular y datos del
mundo real). En cada una, tu gemelo debe decidir **y poder explicarlo**.

### Situación 1 — Dos pujas, un mismo milisegundo

- **Qué pasa.** En el remate de la guitarra, Marisol e Iván pujan la misma cantidad en el
  mismo milisegundo, cuando aún regía el precio anterior. Cada uno jura haber pulsado
  primero y la bitácora anotó una antes que otra, pero no necesariamente en el orden de
  llegada. Carmen puja justo después, exactamente el precio actual más el incremento. Quien
  pierda se queda sin la guitarra; quien gane debe poder defender su derecho ante una queja.
- **Qué datos hay.** Las tres pujas con monto, instante de llegada al milisegundo y número
  de bitácora, el precio previo y el incremento mínimo.
- **Qué debe deducir.** En qué orden se consideran las dos pujas empatadas, cuál queda
  válida y cuál ya no, porque lo que vale para la segunda depende de lo que aceptó la
  primera; quién lidera y qué precio rige; y si la puja de Carmen, en la frontera, cuenta.
- **Qué debe contestar.** Quién gana provisionalmente, qué desempate lo decidió, a quién
  se le falla y por qué, cuál es la puja mínima que ahora sería válida, y qué dato tendría
  que ser distinto para que ganara el otro.
- **Por qué es lógica.** El desempate se declara una vez y sirve para decidir, para
  justificar ante el perdedor y para contestar «¿y si el reloj hubiera dicho otra cosa?».

### Situación 2 — El cierre que se mueve

- **Qué pasa.** La página dice que la tabla de surf cierra a cierta hora. La plataforma
  extiende el cierre unos minutos si llega una puja tardía, y en los últimos segundos
  entran muchas: unas válidas, otras por debajo del mínimo, otras repetidas. Un postor dice
  que su puja llegó «después del cierre» y se la rechazaron; otro, que la suya, enviada a
  tiempo, debió contar. El primero se queda sin el lote; el segundo, con una queja formal.
- **Qué datos hay.** El cierre publicado, la regla de extensión, las pujas con su instante
  y su monto, y los precios vigentes. Ningún dato dice «el cierre real es este».
- **Qué debe deducir.** En cadena: qué pujas fueron válidas, cuáles de ellas movieron el
  cierre, a qué hora quedó el nuevo, qué pujas llegaron ya fuera de él y cuál terminó
  ganando.
- **Qué debe contestar.** El cierre efectivo, la lista de pujas que lo movieron, el
  ganador, y para cada reclamación si procede y por qué.
- **Por qué es lógica.** Lo intuitivo es «cerró a la hora publicada, lo posterior llegó
  tarde», y es falso; el cierre es una conclusión que depende de las pujas, no un dato.

### Situación 3 — El máximo que nadie ve

- **Qué pasa.** Lucía dejó una puja automática con un máximo que solo ella conoce; Iván
  puja a mano. La pantalla muestra el precio y quién lidera. Al final Iván reclama que
  ofreció más de lo que mostraba el sistema; Lucía exige que su máximo no se revele; un
  auditor pide pruebas de que el resultado es correcto. Dos partes con razón: la privacidad
  de una y el derecho de la otra a entender por qué perdió.
- **Qué datos hay.** Las pujas manuales con su instante, los máximos automáticos con el
  suyo, el incremento mínimo y los precios publicados. Ningún dato dice quién lidera ni el
  precio en un instante dado.
- **Qué debe deducir.** En cada momento, quién lidera y a qué precio; cuándo la puja
  automática sube sola y cuándo se agota; qué pasa si dos máximos coinciden.
- **Qué debe contestar.** El líder y el precio en cualquier instante; una explicación para
  el auditor, completa, y otra para Iván, que lo convence sin exhibir lo que es secreto; y
  qué tendría que cambiar para que Iván ganara.
- **Por qué es lógica.** «Gana el que más ofreció y paga lo que ofreció» es sospechoso
  justo porque parte de lo ofrecido está oculto. La explicación es un objeto que se puede
  mostrar completo o filtrado, sin escribir dos razonamientos.

### Situación 4 — El hold que venció mientras se pagaba

- **Qué pasa.** La cena tiene 5 lugares y se pelean muchos más solicitantes. Cada uno
  recibe un hold temporal que libera el lugar si no se paga. Iván pagó, pero su hold ya
  había vencido y el lugar pasó a la siguiente en la fila, que lo tiene en hold sin pagar
  aún. El banco sella el pago de Iván antes del vencimiento; la plataforma lo registró
  después. De otro pago ni siquiera hay sello. A Iván le cobraron; a la otra persona le
  prometieron el lugar.
- **Qué datos hay.** El cupo, las solicitudes en orden, los holds con inicio y duración,
  los pagos con su hora de registro y, cuando existe, el sello del banco.
- **Qué debe deducir.** Cuántos lugares siguen realmente disponibles (nadie lo mide: sale
  de cupo, pagos y holds vigentes), quién tiene derecho a cada lugar en cada instante, y
  cuáles pagos fueron a tiempo, tarde, o no se puede saber.
- **Qué debe contestar.** El reparto completo de los 5 lugares y la razón de cada uno; para
  los pagos dudosos, cada historia posible y a quién favorece; y qué dato resolvería la
  duda.
- **Por qué es lógica.** «Pagó, luego tiene lugar» es lo obvio y puede estar mal. «No sé
  si pagó a tiempo» no es lo mismo que «pagó tarde».

### Situación 5 — El reintento y el reinicio

- **Qué pasa.** Rosa puja desde la carretera, con mala señal. No recibe confirmación y
  reenvía la misma puja. Además, el sistema se reinició 30 segundos antes del cierre y la
  bitácora tiene un hueco. Entre tanto, Iván pujó. Ahora el reintento ya no supera el precio
  actual. Rosa afirma que su puja fue la primera; Iván, que no se puede aceptar una puja baja.
  Hay dinero y un lote en juego, y una bitácora que debe ser inalterable.
- **Qué datos hay.** Los dos envíos de Rosa con su clave de reintento e instante, las
  pujas de otros, la numeración de la bitácora con su hueco y el evento de reinicio.
- **Qué debe deducir.** Si el segundo envío es el mismo intento o una puja nueva; si el
  primero pudo haberse registrado; y, en cada caso, qué precio tenía que superar Iván.
- **Qué debe contestar.** Tres respuestas: «ya estaba registrada», «no se registró» y «no
  se sabe», con sus consecuencias para el ganador, y qué evidencia decidiría entre ellas.
- **Por qué es lógica.** Ni rechazar el reintento por bajo ni contarlo como puja nueva es
  obviamente correcto. Hay que razonar qué historias son posibles, no suponer una.

## Por qué no basta un script

Con `if monto > actual + incremento: aceptar()` resuelves una puja a la vez, sin empates,
sin reintentos, sin cierres que se mueven. Tu gemelo debe contestar, **con las mismas
reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Es válida la puja de Carmen? | decisión |
| ¿Por qué perdió Iván la guitarra? | explicación |
| ¿Qué pujas movieron el cierre de la tabla? | todas las respuestas |
| ¿Qué tendría que ser cierto para que Iván conserve el lugar de la cena? | la pregunta al revés |
| ¿Qué pasaría si la extensión del cierre fuera más larga? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para saber si una puja es válida en un instante, si «el precio
   actual» no se guarda como dato?
2. Si dos pujas empatan, ¿dónde queda escrito quién gana y con qué evidencia?
3. ¿Cómo distingue tu gemelo «la puja no llegó» de «no sé si llegó»?
4. ¿Qué parte de la explicación puede ver el postor que perdió y cuál solo el auditor?
5. En Erlang un proceso serializaba las operaciones y un temporizador cerraba la subasta.
   ¿Qué de eso podría alimentar a este gemelo, y qué decide el gemelo que un proceso no
   puede explicar?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la casa de subastas, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar pujas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: unos 3 lotes, 8 postores y un evento con 5 lugares y unos 9
  solicitantes, contra las 200 subastas, los 500 postores, las 300 pujas en 10 segundos y
  las 50 personas por 5 lugares del original.
- Son ejemplos del ejercicio, no hechos del mundo: la guitarra, la tabla, la cena, las
  personas y las cantidades que aparecen en ellos.
- El «ahora» es un hecho del modelo, en milisegundos, no el reloj del sistema, para que
  las respuestas se puedan repetir.
- Tú defines y declaras como supuesto: el incremento mínimo; cómo lees la frontera
  («estrictamente mayor a la actual más el incremento»); cuánto se extiende el cierre
  (el original da de 2 a 5 minutos) y qué tan cerca del cierre cuenta una puja como
  tardía; el desempate de pujas al mismo milisegundo; qué pasa si dos máximos
  automáticos coinciden; la duración del hold (el original da de 5 a 15 minutos); cuánto
  pesa el sello del banco frente a la hora de registro; y qué se puede afirmar de lo que
  cae en un hueco de la bitácora.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Sobreventa deliberada de lugares y a quién se le falla si todos se presentan.
- Postores coludidos o que pujan contra sí mismos para subir el precio.
- Un mismo presupuesto repartido entre varias subastas a la vez.
- Lista de espera con prioridad por antigüedad y cancelaciones con reembolso.

---
*Las cifras (cierre extendido de 2 a 5 minutos, hold de 5 a 15 minutos, 200 subastas,
500 postores, 300 pujas en los últimos 10 segundos, 50 personas por 5 lugares, reinicio
30 segundos antes del cierre) son de referencia y vienen del problema original. Verifica
la fuente vigente antes de citarlas en tu entrega.*
