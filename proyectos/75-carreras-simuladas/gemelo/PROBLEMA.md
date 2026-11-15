# #75 — Carreras simuladas: gemelo digital con programación lógica

> Extensión del proyecto #75. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la carrera: cada piloto como proceso que reacciona a
eventos, un orden y unos tiempos consistentes, apuestas hasta la salida y pagos al
final. Esa simulación responde «¿corre, avanza y se puede repetir?». Quien opera el
juego necesita otra cosa: «¿este evento puede ocurrir ahora, qué se le paga a cada
apostador, y cómo lo justifico ante quien reclama?».

El gemelo digital es el **modelo lógico** de la carrera: hechos que reflejan su estado
y reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque lo que hay
que resolver aquí no es simular más rápido, sino deducir, justificar y descartar.

## La carrera que se clona

Una carrera de un juego de apuestas ficticias (fichas virtuales, nunca dinero real),
reducida a 6 pilotos, 10 vueltas, 8 apostadores y unas 12 apuestas. Las apuestas son
parimutuel: se suma lo apostado, la casa descuenta una comisión y el resto se reparte
entre quienes acertaron.

| Parte | Contenido |
|---|---|
| Entidades | carrera → piloto → vueltas; apostador → apuesta (a un piloto, con fichas) |
| Estado | carrera: etapa y salida programada contra salida real; piloto: vuelta y tiempo de cada vuelta; apuesta: instante en que la recibió el servidor y hora que declaró el aparato |
| Eventos | se abren o se cierran las apuestas, se da la salida, adelantamiento, error, falla mecánica, choque, bandera amarilla, lluvia, safety car, parada en pits, suspensión, llegada a meta |
| Decisiones | ¿cuenta esta apuesta?, ¿es válido este evento ahora?, ¿sigue en carrera este piloto?, ¿quién ganó?, ¿cuánto se le paga a cada apuesta o se le reembolsa? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original (escenario, casos difíciles y datos del mundo
real); los detalles que las completan son de esta extensión. En cada una, tu gemelo
debe llegar a una decisión **y poder explicarla**.

### Situación 1 — La apuesta del segundo de la salida

- **Qué pasa.** Las apuestas se reciben hasta antes de la salida. Mariana apuesta 50
  fichas casi al mismo tiempo en que se apagan los semáforos; su aparato marca una
  hora, el servidor recibió el mensaje en otra, y la salida real no coincide con la
  programada. Otra apuesta llega con el mismo instante que la salida; una tercera,
  de un aparato sin hora.
- **Qué datos hay.** Por apuesta, el instante en que la recibió el servidor y la hora
  declarada por el aparato (o su ausencia); la salida programada y la salida real; los
  eventos de la carrera.
- **Qué debe deducir.** En qué etapa estaba la carrera cuando cada apuesta cuenta que
  llegó, y con cuál reloj se juzga. Ningún dato dice «apuesta válida»: sale de comparar
  relojes y eventos.
- **Qué debe contestar.** Por apuesta: «cuenta», «no cuenta» o «no se sabe» (hora
  dudosa), con la razón y el dato que faltaría; y el camino que sigue la apuesta (de
  recibida a aceptada y liquidada, o a rechazada y reembolsada).
- **Por qué es lógica.** Dos relojes y dos versiones de «salida» se contradicen y la
  regla que elige debe quedar escrita una vez para todas las apuestas. Hay un dilema
  real: la casa no puede aceptar apuestas con la carrera corriendo, pero tampoco
  castigar a quien tiene mala red. Lo intuitivo es que cuenta lo que el apostador
  envió antes de la salida; revisa por qué es sospechoso.

### Situación 2 — El safety car y las tres paradas

- **Qué pasa.** En una vuelta intermedia sale el safety car: neutraliza la carrera y
  comprime al grupo. Tres autos entran a pits justo en ese momento. La bitácora llega
  desordenada: registra un adelantamiento, las tres entradas a pits y la salida del
  safety car, y dos de esos eventos comparten el mismo instante.
- **Qué datos hay.** Eventos con su fuente y su instante, la salida a pista del safety
  car y las posiciones registradas por vuelta.
- **Qué debe deducir.** La etapa de la carrera en cada instante (en curso, neutralizada,
  en curso otra vez), cuáles eventos son posibles en cada etapa, cuáles órdenes de los
  eventos empatados son compatibles con eso, y qué clasificación queda vigente.
- **Qué debe contestar.** Cada evento como válido, inválido o ambiguo, con la etapa que
  lo decide; la secuencia que sí es posible (y las demás, si hay varias); y la
  clasificación que se usará para pagar.
- **Por qué es lógica.** Encadena la salida del safety car, la carrera neutralizada, el
  evento que ya no cabe y la posición que no cambió. Lo intuitivo es que lo que está
  en la bitácora pasó y cuenta; revisa si es cierto.

### Situación 3 — El piloto que se calla

- **Qué pasa.** A mitad de carrera el piloto 4 deja de reportar vueltas. Pudo chocar,
  fallar su auto o perder su proceso en el cronometraje. Varios apostadores tienen
  fichas en él. Más adelante llega, tarde, un registro suyo.
- **Qué datos hay.** Las vueltas de cada piloto con su instante, los eventos de la
  dirección de carrera y las apuestas por piloto. Ningún dato dice «abandonó» salvo,
  si acaso, un evento de la dirección.
- **Qué debe deducir.** El estado de cada piloto (sigue, abandonó o sin dato), si el
  silencio es del piloto o del sistema (según qué más calla), y qué pasa con sus
  apuestas mientras tanto y cuando se sabe.
- **Qué debe contestar.** «Sigue», «abandonó» o «no se sabe», con las razones, el dato
  que daría certeza y qué le pasa a cada apuesta: se mantiene, se pierde o se
  reembolsa. Y qué hacer con el registro tardío de alguien declarado fuera.
- **Por qué es lógica.** «Abandonó» y «no lo sé» no son lo mismo, y se distinguen
  comparando varias fuentes. Hay un dilema real: la casa y el apostador tienen razón a
  la vez. Lo intuitivo es que quien no reporta abandonó y su apuesta se pierde; revisa
  quién más guardó silencio y a quién le costaría el error.

### Situación 4 — Dos autos, un mismo tiempo

- **Qué pasa.** Dos pilotos cruzan la meta con el mismo tiempo en milésimas: fotofinish.
  Hay apuestas por cada uno de los empatados, por un tercero y ninguna por el cuarto.
  Las fichas son enteras y el reparto deja un residuo. En otra carrera nadie apostó por
  quien ganó.
- **Qué datos hay.** Los tiempos de cada vuelta de cada piloto, las apuestas con sus
  fichas y la comisión de la casa. Ningún dato dice «empate», «ganador» ni «pago».
- **Qué debe deducir.** Las posiciones finales, si el empate es real, quién cuenta como
  ganador, el pozo neto, lo que le toca a cada apuesta acertada y qué pasa con el
  residuo y con el pozo sin ganadores.
- **Qué debe contestar.** Por apuesta: «gana», «pierde» o «se reembolsa», con sus
  fichas y la razón; y que lo repartido cuadre con el pozo neto, sin fichas perdidas.
- **Por qué es lógica.** Encadena tiempos, empate, ganadores, pozo y pago. Hay un
  dilema real: los apostadores de cada empatado tienen la misma razón, y la casa no
  puede inventar un desempate que no esté escrito. Lo intuitivo es que gana el que
  cruzó primero por una milésima, y que el pago es lo que se veía al apostar; revisa
  ambas cosas.

### Situación 5 — Suspendida o cancelada

- **Qué pasa.** La lluvia obliga a detener otra carrera. Un empleado anota en la
  bitácora «cancelada»; la dirección no ha confirmado. Una apuesta llega con la carrera
  ya detenida. Si es cancelación, hay reembolso; si la carrera ya se había corrido en
  buena parte, tal vez hay un resultado.
- **Qué datos hay.** Eventos con su fuente (bitácora o dirección) e instante, vueltas
  completadas por piloto y las apuestas con sus fichas.
- **Qué debe deducir.** Si la carrera está suspendida, cancelada o terminada, si hay
  resultado válido para pagar, y qué apuestas se reembolsan, cuáles se pagan y cuáles
  se rechazan por llegar tarde. Si se reanuda, qué eventos siguen siendo posibles.
- **Qué debe contestar.** Por apuesta: «se paga», «se reembolsa», «se rechaza» o «no se
  sabe» (aún sin confirmar), con la regla y la fuente que la sostienen.
- **Por qué es lógica.** Secuencias de etapas donde unas son definitivas y otras
  reversibles, y una fuente cuenta más que otra. Hay un dilema real: quien acertó con
  la carrera casi acabada y quien perdería si se paga. Lo intuitivo es que cancelada
  siempre significa reembolso; revisa qué distingue una carrera que no se corrió de
  una que se corrió casi toda.

## Por qué no basta un script

Con `if t_apuesta < t_salida: aceptar()` resuelves una apuesta con relojes perfectos y
una carrera sin sobresaltos. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Cuenta la apuesta 7? | decisión |
| ¿Por qué no se le pagó a Luis? | explicación |
| ¿Qué apuestas ganan en esta carrera? | todas las respuestas |
| ¿Qué tendría que pasar para que la apuesta 7 hubiera entrado? | la pregunta al revés |
| ¿Qué pasaría si la carrera se suspende en la vuelta 8? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir una apuesta, y qué relojes intervienen?
2. ¿Qué distingue un evento imposible de uno raro pero posible?
3. ¿Cómo distingue tu gemelo «abandonó» de «no sé si abandonó»?
4. Cuando un empate o una suspensión dejan el pago sin regla clara, ¿dónde queda
   escrito qué se hace y con qué desempate?
5. En tu simulación en Erlang, ¿cómo lograste que la carrera se pudiera reproducir, y
   qué dato de ella (un evento, un tiempo, un piloto que cae) alimentaría a este gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la carrera, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar carreras o graficar.

## Supuestos de esta extensión

- Escala reducida: 6 pilotos, 10 vueltas, 8 apostadores y unas 12 apuestas, contra los
  20 pilotos, 50 vueltas y 500 apuestas del escenario original. El safety car cae en
  una vuelta intermedia de tu carrera, no necesariamente la 20.
- El «ahora» es un hecho del modelo, en milésimas de segundo desde la apertura de las
  apuestas, no el reloj del sistema, para que las respuestas se puedan repetir.
- Nombres, números de piloto y apuesta, las 50 fichas y «la vuelta 8» son del ejercicio.
- Las apuestas son parimutuel. Del original vienen: la comisión de la casa, el safety
  car, las paradas simultáneas, el fotofinish, el reembolso y los tiempos en milésimas.
- Defines tú, porque el original no da la cifra ni la regla: la comisión, cuánto antes
  de la salida se cierran las apuestas y con qué reloj, qué eventos caben bajo el
  safety car, cuánto silencio de un piloto es dudoso, desde cuántas vueltas una carrera
  detenida tiene resultado, quién confirma una cancelación, y a dónde va el residuo
  del reparto.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Apuestas combinadas (podio, vuelta rápida) sobre los mismos hechos.
- Sanciones a posteriori que cambian la clasificación ya liquidada.
- Paradas en pits como decisión de estrategia, según desgaste y clima.

---
*Las cifras de dominio son de referencia y vienen del problema original. Verifica la
fuente vigente antes de citarlas en tu entrega.*
