# #22 — Torre de control TIJ: gemelo digital con programación lógica

> Extensión del proyecto #22. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la torre: un proceso por vuelo, un `gen_statem` por ciclo
de vida, un feed de actualizaciones y un tablero que todos ven. Esa simulación responde
«¿en qué estado está cada vuelo y quién se entera?». Quien opera la torre necesita algo
más: «¿cuál es el estado verdadero, qué puede pasar después y a quién arrastra esta
demora?».

El gemelo digital es el **modelo lógico** del aeropuerto: hechos que reflejan su estado y
reglas que reflejan cómo se decide en él. Se escribe en Prolog porque lo que hay que
resolver no es calcular, sino validar una historia, seguir una aeronave de vuelo en vuelo
y saber decir «no lo sé».

## El aeropuerto que se clona

Una jornada de TIJ reducida a una pista, 3 puertas, 4 aeronaves y 10 vuelos de salida y
llegada. El escenario es el del problema original, a escala pequeña; los complementos
que no trae (una aeronave de reserva, nombres genéricos de fuentes, rutas) se listan en
«Supuestos».

| Parte | Contenido |
|---|---|
| Entidades | aeropuerto → pista única, puertas; aeronave → rotación de vuelos; fuentes de mensajes |
| Estados del ciclo (original) | programado, check-in abierto, abordando, última llamada, puerta cerrada, rodando, despegó, en vuelo, aterrizado, demorado, cancelado |
| Estado por vuelo | salida o llegada, aeronave, hora programada (STD/STA), estimada (ETD/ETA) y real (ATD/ATA), puerta, causa de demora declarada |
| Estado del sistema | si hay niebla, dónde está cada aeronave, qué puerta está ocupada, qué aeronave es la de reserva |
| Eventos | llega un mensaje de estado (emitido en un instante, recibido en otro), cambia una hora o una puerta, se cancela un vuelo, hay niebla, se reinicia el sistema |
| Decisiones | ¿qué estado muestra el tablero?, ¿qué paso es legal?, ¿a quién arrastra esta demora?, ¿qué pasa con el vuelo de regreso?, ¿en qué orden usan la pista? |

## Situaciones que tu gemelo debe razonar

Las cinco parten del problema original (sus casos difíciles, su escenario y sus datos
del mundo real). La 4 y la 5 añaden un complemento que el original no trae y que se
declara en «Supuestos». En cada una, tu gemelo debe llegar a una decisión **y poder
explicarla**.

### Situación 1 — El mensaje que llegó último no es el que pasó último

- **Qué pasa.** Del vuelo de salida 4 llegan, de fuentes distintas, «última llamada»,
  «abordando» y «puerta cerrada»; por una red lenta, «abordando» se recibe después de
  «puerta cerrada». Del vuelo 6 se recibe «despegó» y, minutos después, un «abordando»
  emitido antes. Del vuelo 9 llega «puerta cerrada» y nunca «abordando». Tras un
  reinicio, lo único que queda es la lista de mensajes. Un pasajero decide con el
  tablero si corre a una puerta que quizá ya cerró.
- **Qué datos hay.** Cada mensaje con su fuente, el estado que reporta, el instante en
  que se emitió y el instante en que se recibió. Ninguna fuente guarda «el estado actual».
- **Qué debe deducir.** El estado de cada vuelo en el «ahora»; qué mensajes caben en una
  historia legal y cuáles no; qué se puede afirmar de un paso que nadie reportó; y, si la
  historia no cuadra, el primer mensaje que la rompe.
- **Qué debe contestar.** El estado vigente y los pasos que podrían seguir desde ahí (si
  hay varios, todos); para cada mensaje descartado, la razón; para un paso sin reporte,
  tres respuestas distintas: «ocurrió», «no ocurrió» y «no lo sé».
- **Por qué es lógica.** La misma descripción de qué puede seguir a qué sirve para
  validar una historia, para predecir lo que sigue y para reconstruir tras un reinicio.
  Lo intuitivo es tomar el último mensaje recibido; es sospechoso porque recibido no es
  lo mismo que ocurrido.

### Situación 2 — Dos fuentes, dos verdades

- **Qué pasa.** El sistema de la aerolínea sigue diciendo «abordando» para el vuelo 3.
  La torre registra «rodando» para la aeronave 2 y la fuente de posición la ve moviéndose
  en plataforma; la página del aeropuerto aún muestra la hora programada. Si el tablero
  dice «rodando» y la aerolínea tenía razón, el pasajero rezagado abandona la puerta y
  pierde su vuelo. Si dice «abordando» y el avión ya rodó, la gente hace fila para nada
  y la aerolínea responde por el reclamo. Las dos partes tienen razón en algo.
- **Qué datos hay.** Mensajes de cada fuente con su instante, lecturas de posición con
  la aeronave a la que pertenecen, ETD y, si existe, ATD. Nadie dice qué fuente miente.
- **Qué debe deducir.** Si hay una contradicción real o solo hablan de instantes
  distintos; qué afirmación es compatible con el resto de la evidencia; y cuándo la
  evidencia no alcanza para decidir.
- **Qué debe contestar.** Qué muestra el tablero, qué evidencia perdió y por qué, a quién
  se le falla con esa decisión y qué tendría que llegar para cambiarla. Si no alcanza,
  «no lo sé» en vez de elegir al azar.
- **Por qué es lógica.** Qué fuente manda no se escribe en cada caso: se declara una vez
  y la explicación debe poder nombrar a la perdedora.

### Situación 3 — La niebla se fue, la demora se quedó

- **Qué pasa.** La niebla de la mañana retrasa 20 minutos todas las salidas de la mañana.
  La aeronave 1 hace salida de mañana, regreso a mediodía, salida de tarde y regreso de
  noche; la aeronave 2 solo salida de mañana y regreso temprano. A mediodía ya no hay
  niebla. Aun así, el pasajero de la salida de la tarde pregunta si debe salir hacia el
  aeropuerto, y la aerolínea declara «clima» como causa de todo lo demorado.
- **Qué datos hay.** La rotación publicada de cada aeronave, horarios programados y
  estimados, la ventana de niebla y las causas declaradas. Ningún dato dice «heredada».
- **Qué debe deducir.** Qué vuelos posteriores se ven alcanzados por la demora inicial y
  cuáles no, aunque estén en la misma cadena; la causa de origen de cada demora; y si un
  vuelo es origen de demora o víctima de la de otro.
- **Qué debe contestar.** Los afectados con la cadena de aeronave que los une a la
  niebla, su nueva hora estimada y la causa deducida; los no afectados y por qué; y las
  causas declaradas que contradicen la deducida.
- **Por qué es lógica.** La demora heredada no es dato de ningún vuelo: es una conclusión
  que se propaga por la rotación (en el original, cerca de la mitad de las demoras
  iniciales vienen de aeronaves que llegaron tarde). Lo intuitivo es «la niebla ya se
  fue, la tarde sale a tiempo»; es sospechoso porque la aeronave no se enteró.

### Situación 4 — Vuelo cancelado: ¿y el de regreso?

- **Qué pasa.** La aerolínea cancela la salida del vuelo 5, que operaba la aeronave 3. Esa
  misma aeronave debía volver como vuelo 6 y salir de nuevo en el vuelo 7. El 6 sigue
  «programado» en el tablero. Hay una sola aeronave de reserva, y el vuelo 8 la reclama
  porque su aeronave quedó inmovilizada. En el destino, los pasajeros del 6 esperan
  noticias; en TIJ, los del 8 también.
- **Qué datos hay.** La rotación, los estados de los vuelos, las lecturas de posición de
  las aeronaves, cuál es la de reserva y la cancelación con la fuente que la reportó.
  Ningún dato dice dónde está la aeronave 3.
- **Qué debe deducir.** Dónde está cada aeronave; si el 6 y el 7 pueden operarse con la
  que les tocaba; si hay forma de salvarlos con la de reserva; y si la cancelación es
  firme o solo la afirma una fuente.
- **Qué debe contestar.** El estado de 6, 7 y 8 con su causa; quién se queda con la
  aeronave de reserva cuando dos vuelos la necesitan, con la razón y a quién se le falla;
  y qué tendría que cambiar para que el perdedor la obtuviera. Si la cancelación es
  dudosa, «no lo sé» y que no se cancele nada en cadena.
- **Por qué es lógica.** Un vuelo es posible solo si lo que pasó antes con su aeronave lo
  permite, y eso se propaga. Lo intuitivo es «cae uno, caen todos los de su cadena»; es
  sospechoso porque importa dónde quedó la aeronave, no qué decía el itinerario.

### Situación 5 — Una pista, varias salidas y un cambio doble

- **Qué pasa.** Al levantarse la niebla, varias salidas retrasadas quedan listas para
  rodar casi a la vez y hay una sola pista, el recurso más crítico. Cada despegue y cada
  aterrizaje exige separación de tiempo, y también aterrizan vuelos. Además, el vuelo 4
  cambia de puerta y de hora a la vez: la nueva hora cae donde otras dos salidas ya
  esperan pista, y la nueva puerta sigue ocupada por una aeronave que aún no sale. Cada
  minuto perdido en la pista se arrastra por la rotación de la situación 3.
- **Qué datos hay.** Horas estimadas, puertas asignadas con su intervalo, qué vuelos
  están listos para rodar, qué llegadas toman la pista, y los dos cambios del vuelo 4
  con el instante de cada mensaje (puede haber llegado uno solo).
- **Qué debe deducir.** En qué órdenes se puede usar la pista sin violar la separación;
  qué vuelo choca con la puerta nueva; y cuál de los dos cambios del vuelo 4 puede darse
  por bueno.
- **Qué debe contestar.** Un orden concreto de pista y los demás órdenes válidos; para
  cada vuelo que queda atrás, qué lo desplazó y cuánta demora arrastra; y qué muestra
  el tablero del vuelo 4 mientras el cambio no esté completo.
- **Por qué es lógica.** Un recurso único con restricciones se declara una vez y el
  motor busca los órdenes; descartar uno es justificar qué restricción rompe.

## Por qué no basta un script

Con `vuelo.estado = ultimo_mensaje.estado` copias lo que dijo alguien. Tu gemelo debe
contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué estado muestra el tablero para el vuelo 4? | decisión |
| ¿Por qué la salida de la tarde aparece demorada si ya no hay niebla? | explicación |
| ¿Qué vuelos de hoy arrastra la niebla de la mañana? | todas las respuestas |
| ¿Qué tendría que pasar para que el vuelo 7 salga a su hora? | la pregunta al revés |
| ¿Qué pasaría si se cancela el vuelo 5? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué necesitas saber de un mensaje, además del estado que reporta, para decidir si
   cuenta?
2. Cuando dos fuentes se contradicen, ¿dónde queda escrito cuál manda y si manda siempre?
3. ¿Cómo distingue tu gemelo «no ocurrió» de «ocurrió y no me enteré»?
4. ¿Qué parte de la cadena de demoras le sirve al pasajero y cuál a la aerolínea?
5. En tu simulación Erlang, ¿qué hacía el proceso de un vuelo al reiniciarse, y en qué se
   parece a reconstruir su estado desde los mensajes?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del aeropuerto, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar mensajes simulados o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 1 pista (como el original), 3 puertas, 4 aeronaves y 10 vuelos,
  contra los 120 vuelos al día, picos de 10 movimientos por hora y 300 clientes del
  escenario original. Los números de vuelo y de aeronave de los ejemplos son
  ilustrativos.
- Complementos que el original no trae, inventados por esta extensión: la aeronave de
  reserva, las rotaciones, las rutas y los nombres genéricos de las fuentes (aerolínea,
  torre, posición, página del aeropuerto).
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir.
- Los datos que defines tú: las transiciones legales (incluido dónde caben «demorado» y
  «cancelado»), qué fuente manda en cada caso, desde cuántos minutos de diferencia una
  hora cuenta como demora, el tiempo mínimo de una aeronave en tierra entre vuelos, la
  separación entre movimientos en la pista, qué antigüedad vuelve dudoso un mensaje, el
  criterio para repartir la aeronave de reserva y qué horas son «la mañana».

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Jornada máxima de la tripulación y su efecto en la cadena de demoras.
- Pasajeros con conexión, incluidos los que cruzan por el puente a San Diego.
- Cambio de sentido de pista por viento.
- Aeronave en mantenimiento que sale de la rotación a media jornada.
- Compensación a pasajeros según la causa de la demora.

---
*Las cifras son de referencia (órdenes de magnitud) y vienen del problema original:
once estados, 120 vuelos al día, picos de 10 movimientos por hora, 300 clientes, 20
minutos de niebla y cerca de la mitad de las demoras por aeronave previa. La escala
reducida, las aeronaves, las rutas y la aeronave de reserva son datos del ejercicio.
Verifica la fuente vigente antes de citar las primeras en tu entrega.*
