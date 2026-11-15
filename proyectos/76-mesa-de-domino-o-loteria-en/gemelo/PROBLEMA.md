# #76 — Mesa de dominó o lotería en línea: gemelo digital con programación lógica

> Extensión del proyecto #76. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste las mesas: una máquina de estados por partida,
jugadores que entran, se desconectan y regresan, y un servidor que reparte y valida.
Esa simulación responde «¿la mesa sigue viva y avanza?». Quien arbitra la mesa
necesita otra cosa: «¿esta jugada es legal, la mano ya terminó, a quién se le falla
cuando dos reclaman, y cómo se lo explico a quien se queja?».

El gemelo digital es el **modelo lógico** de la mesa: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque lo que hay que
resolver aquí no es repartir más rápido, sino deducir, justificar y descartar.

## Las mesas que se clonan

Un servidor de juegos de mesa reducido a dos mesas y nueve jugadores: una de dominó
doble seis con 4 jugadores y 7 fichas cada uno, y una de lotería con 5 jugadores y
tablas de 4×4. Cada jugador ve solo lo suyo; el servidor ve todo y decide.

| Parte | Contenido |
|---|---|
| Entidades | mesa → jugador → sesión (un dispositivo conectado); en dominó, fichas; en lotería, tabla de 16 figuras y mazo de cartas |
| Estado | mesa: etapa y variante; jugador: su mano o su tabla y su turno; sesión: abierta o cerrada, y su última señal |
| Eventos | se reparte, se juega una ficha, se pasa, se canta una carta, se grita «¡lotería!», se vence un turno, se cae o vuelve una sesión, se sustituye a un jugador por un bot |
| Decisiones | ¿es legal esta jugada?, ¿terminó la mano y quién gana?, ¿vale este reclamo?, ¿quién juega ahora?, ¿qué sesión manda?, ¿la mesa está abandonada? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original: sus datos, su escenario y sus casos difíciles.
Cada una añade complementos (reglas de arbitraje y datos de contexto) que el original
no detalla. En cada una, tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — La ficha que «sí encaja»

- **Qué pasa.** Es el turno de Dalia en una mesa de dominó y llegan cuatro envíos: una
  ficha que encaja con un extremo pero que Dalia no tiene (cliente modificado), una
  ficha suya que no encaja con ningún extremo, una ficha suya que sí encaja pero
  enviada cuando le tocaba a otro, y un «paso» de alguien que sí tenía jugada.
- **Qué datos hay.** Las jugadas ya hechas, a quién le toca y la mano de cada jugador,
  que solo el servidor conoce.
- **Qué debe deducir.** Cómo está el tablero y cuáles son sus extremos, qué fichas
  puede jugar cada quien, y qué envíos son jugadas legales. Nada de eso es un dato.
- **Qué debe contestar.** Aceptar o rechazar cada envío, la razón en cada caso y, para
  quien juega, qué le habría sido legal. La explicación que ve el resto de la mesa no
  puede delatar las fichas de nadie.
- **Por qué es lógica.** La legalidad nace de que coincidan la ficha, la mano, el
  tablero y el turno; basta que falle una. Y «lo que encaja» no es «lo que es legal».

### Situación 2 — Trancado: nadie juega y alguien gana

- **Qué pasa.** Un dominó se gana quedándose sin fichas, o por puntos si se tranca.
  En una mano avanzada ya no sale nadie: tres jugadores pasan seguidos y el cuarto
  también. Dos jugadores protestan: uno porque «yo tengo menos fichas», otro porque
  «aún no terminó, apenas pasaron tres».
- **Qué datos hay.** Jugadas y pases en orden, y las fichas que le quedan a cada uno.
- **Qué debe deducir.** Si la mano terminó y por qué vía (sin fichas o trancada), en
  qué jugada exacta se trancó, y quién gana al comparar los puntos de cada mano.
- **Qué debe contestar.** El veredicto con su cadena: extremos, quién no tenía jugada,
  puntos y comparación. Y qué habría pasado si una sola ficha se hubiera jugado antes.
- **Por qué es lógica.** «Trancado» no se mide: se deduce de lo que cada mano puede
  hacer. Tres pases seguidos no son una tranca, y tener menos fichas no es ganar.

### Situación 3 — El turno que se acabó

- **Qué pasa.** Rubén se desconecta justo en su turno. Al vencer el tiempo por turno,
  el sistema juega por él o lo sustituye con un bot. Rubén regresa 40 s después, con
  la mesa ya jugada por los demás. Alega que su red falló y pide su ficha de vuelta.
- **Qué datos hay.** Cuándo cayó y volvió su sesión, cuándo empezó y venció su turno,
  qué se jugó mientras tanto y la mano de Rubén.
- **Qué debe deducir.** Si el turno venció, qué hizo el sistema por él y si esa jugada
  era legal, de quién es el turno ahora y qué mano recupera Rubén al volver.
- **Qué debe contestar.** Si Rubén puede actuar ya o debe esperar, qué mano ve, y la
  regla que decide entre dos agravios: la mesa que ya avanzó y el jugador al que la
  red le quitó su ficha. La respuesta debe nombrar a quién se le falla y por qué.
- **Por qué es lógica.** Los 40 s no equivalen a «perdió un turno»: según el tiempo por
  turno y la velocidad de los demás, pudo perder uno, ninguno o volver a tocarle.

### Situación 4 — ¡Lotería! ¡Lotería!

- **Qué pasa.** En una mesa de lotería dos jugadores gritan con 50 ms de diferencia.
  Gana quien completa primero la figura que pide la variante de esa mesa (fila,
  columna, esquinas o tabla llena). El servidor recibe un grito antes que el otro, pero
  el aparato del segundo declara una hora anterior. Uno de los dos dice haber marcado
  una carta que todavía no se cantaba.
- **Qué datos hay.** Las cartas cantadas con su instante, la tabla de cada jugador, la
  variante, y de cada grito el instante en que lo recibió el servidor y la hora que
  declaró el aparato (que puede faltar o ser imposible).
- **Qué debe deducir.** Qué casillas cuentan como marcadas (solo con cartas ya
  cantadas), quién completó la figura de la variante, qué gritos son válidos y en qué
  orden se pueden comparar.
- **Qué debe contestar.** Quién gana, si hay empate, y por qué el otro grito se
  rechaza o se queda en segundo lugar. Si no hay forma de ordenar los gritos, decir
  «no lo sé» y no inventar un ganador.
- **Por qué es lógica.** Ganar no es llegar primero: es llegar con la figura completa.
  Y «llegó después» no es lo mismo que «no se puede saber cuál fue primero».

### Situación 5 — ¿Quién sigue en la mesa?

- **Qué pasa.** Marisol reconecta desde su celular mientras la sesión de su laptop
  sigue abierta, y ambas mandan jugadas. A la vez, los otros tres jugadores se van y
  sus turnos los juegan bots. La mesa avanza sola, pero ya no hay nadie.
- **Qué datos hay.** Las sesiones de cada jugador con su última señal, qué jugadores
  son humanos y cuáles bots, y las jugadas recibidas desde cada dispositivo.
- **Qué debe deducir.** Qué sesión de Marisol manda, si la otra sigue viva o solo está
  callada, quiénes siguen presentes de verdad y si la mesa está abandonada.
- **Qué debe contestar.** Qué jugada vale, qué mano recibe cada dispositivo (la misma
  y exacta, sin duplicarla), y si la mesa se espera, se cierra o se limpia, con razón.
- **Por qué es lógica.** Que la mesa tenga actividad no es que tenga gente, y una sesión
  abierta no es una persona presente. Hay que razonar sobre sesiones, no sobre un valor.

## Por qué no basta un script

Con `if ficha.lado in extremos: jugar(ficha)` resuelves una jugada con la mesa quieta
y sin tramposos. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Puede Dalia jugar esa ficha ahora? | decisión |
| ¿Por qué no? | explicación |
| ¿Qué fichas puede jugar Dalia? | todas las respuestas |
| ¿Qué tendría que haber en el tablero para que esa ficha fuera legal? | la pregunta al revés |
| ¿Qué pasaría si Rubén hubiera pasado en vez de jugar? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos bastan para reconstruir el tablero en cualquier momento, y qué debe
   quedar solo como deducción?
2. ¿Quién arbitra dos reclamos casi simultáneos, con qué criterio, y dónde queda escrito?
3. ¿Qué información no debe salir nunca del servidor, y cómo explica tu gemelo un
   rechazo sin revelarla?
4. ¿Cómo distingue tu gemelo «esta jugada es ilegal» de «no tengo cómo saber si lo es»?
5. En tu simulación en Erlang, ¿qué estado vivía en el proceso de cada mesa y qué parte
   de él alimentaría a este gemelo en lugar de decidirse allá?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de las mesas, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar repartos simulados o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 2 mesas y 9 jugadores, contra las 200 mesas (150 de dominó y 50 de
  lotería) y 700 jugadores del escenario original.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir. El reparto de fichas y de cartas entra como hecho: no se sortea.
- Los nombres (Dalia, Rubén, Marisol), las fichas y cartas de los ejemplos y la
  variante de cada mesa son del ejercicio, no del original.
- Defines tú: el tiempo por turno (el original da «20-30 s» como ejemplo), qué jugada
  hace el sistema o el bot por un ausente, quién abre la mano, cómo se comparan los
  puntos y cómo se desempata, qué hacer con gritos que no se pueden ordenar, cuánto
  silencio vuelve dudosa una sesión y cuándo una mesa se considera abandonada.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Torneo de varias manos con puntaje acumulado y reglas de desempate entre jugadores.
- Dominó por parejas, con fichas que se pueden delatar entre compañeros.
- Colusión entre jugadores que comparten información fuera de la mesa.
- Espectadores que ven la mesa con una vista distinta a la de los jugadores.
- Lotería con varias tablas por jugador y reclamos sobre más de una.

---
*Las cifras son de referencia y vienen del problema original (28 fichas, 7 por
jugador, tablas de 4×4, turno de 20-30 s, 40 s de regreso, 50 ms entre gritos, 200
mesas y 700 jugadores). Verifica la fuente vigente antes de citarlas en tu entrega.*
