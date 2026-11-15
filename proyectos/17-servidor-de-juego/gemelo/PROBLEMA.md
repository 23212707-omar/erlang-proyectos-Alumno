# #17 — Servidor de juego: gemelo digital con programación lógica

> Extensión del proyecto #17. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el servidor: salas de ritmo fijo, entradas tardías y
desordenadas, una sala que cae sin llevarse a las demás. Esa simulación responde «¿qué
está pasando?». El operador necesita algo más: «¿esta jugada vale?, ¿a quién se le da la
razón?, ¿qué hago con esta sala?, ¿y por qué?».

El gemelo digital es el **modelo lógico** del servidor: hechos que reflejan su estado y
reglas que reflejan cómo se decide en él. Se escribe en Prolog porque aquí no se trata de
calcular, sino de deducir, buscar entre alternativas y justificar.

## El servidor que se clona

Un servidor de juego de una liga abierta, reducido a 4 salas simultáneas y hasta 14
jugadores. Corre tres en raya y trivia (los juegos que menciona el README del proyecto) y
es *autoritativo*: el cliente propone, el servidor decide qué pasó de verdad.

| Parte | Contenido |
|---|---|
| Entidades | servidor → sala → jugador; cola de espera; torneo de eliminación con sus partidos |
| Estado por jugador | nivel, latencia y pérdida medidas (con su instante), sala, si está conectado |
| Estado por sala | juego, participantes, registro de eventos, ritmo de simulación (30 ticks/s), si su último tick se atrasó |
| Eventos | llega una jugada o una pulsación, un jugador se desconecta o regresa, una sala cae, un tick se atrasa |
| Decisiones | ¿vale esta jugada?, ¿quién respondió primero?, ¿qué sala formo?, ¿cuál es la mejor jugada?, ¿qué pasa con el torneo? |

El torneo, los niveles y los vetos son complementos de esta extensión; el servidor, las
salas, el ritmo, el lag y el matchmaking vienen del original.

## Situaciones que tu gemelo debe razonar

Las situaciones 1, 3 y 4 salen del problema original. La 2 la pide el foco del eje
(«jugada legal y mejor jugada por búsqueda») y la 5 parte de la sala que cae del original
pero plantea algo nuevo: un torneo que depende de ella. En cada una, tu gemelo debe llegar
a una decisión **y poder explicarla**.

### Situación 1 — La jugada que llega dos veces y la que no llega

- **Qué pasa.** En tres en raya el servidor es la autoridad: el cliente solo propone.
  Se pierden, duplican y reordenan paquetes. Llega una jugada sobre una casilla ocupada,
  otra idéntica a una ya aceptada, otra de quien no tiene el turno y otra con número de
  secuencia más adelantado de lo que el servidor conoce. Castigar como tramposo a quien
  solo tuvo mala red le quita puntos injustamente; aceptar una trampa arruina al rival.
- **Qué datos hay.** El registro de la sala: cada jugada con su secuencia, quién la envió
  y cuándo llegó; quién juega con qué marca. Ningún dato dice «tablero», «turno» ni «trampa».
- **Qué debe deducir.** El tablero y el turno a partir de las jugadas aceptadas. Para cada
  jugada: si vale, si es repetida, si es ilegal o si aún no se puede saber porque falta
  una anterior; y cuándo lo ilegal es indicio de trampa y cuándo un paquete viejo.
- **Qué debe contestar.** Un veredicto por jugada, con su razón. Ante un hueco en la
  secuencia, «no lo sé» y cuál jugada falta. Y todas las jugadas legales del jugador en turno.
- **Por qué es lógica.** El estado no se guarda: se deduce del historial. «Repetida»,
  «ilegal» y «no lo sé» son tres respuestas distintas, y una consulta puede pedir todas las
  jugadas legales con la misma regla que valida una sola.

### Situación 2 — La mejor jugada, o por qué el bot no puede improvisar

- **Qué pasa.** Un jugador se desconecta a media partida y el servidor pone un bot a
  jugar por él hasta que regrese. Si el bot elige mal, el jugador vuelve con la partida
  perdida y baja de nivel sin culpa. Posición: X abrió en una esquina, O tomó el centro,
  X tomó la esquina opuesta y mueve O.
- **Qué datos hay.** Las jugadas hechas y las líneas que ganan en tres en raya. Ningún
  dato dice cuál jugada es buena.
- **Qué debe deducir.** Para cada jugada legal, si lleva a ganar, a empatar o a perder
  suponiendo que el rival juega lo mejor posible: una búsqueda por las réplicas siguientes.
  Lo intuitivo es la jugada que parece más activa; desconfía de ella hasta demostrarla.
- **Qué debe contestar.** Las mejores jugadas (todas las equivalentes), con la secuencia
  de réplicas que las justifica, y para cada jugada descartada, la secuencia en que falla.
- **Por qué es lógica.** Es una cadena de deducciones sobre un grafo de posiciones: «si
  juego aquí, el rival fuerza allá, yo cubro acullá y entonces…».

### Situación 3 — ¿Quién pulsó primero?

- **Qué pasa.** En una sala de trivia, quien pulsa primero gana el derecho a contestar.
  Dos jugadores pulsan casi a la vez y uno tiene 400 ms de lag y 10 % de pérdida.
  Cada cliente reporta su instante de pulsación y el servidor registra cuándo llegó cada
  una: «yo pulsé primero» contra «yo llegué primero». Además, el último tick de la sala
  se atrasó y el servidor solo ordena llegadas por tick. Hay puntos de clasificación en
  juego, y un cliente puede mentir sobre su reloj.
- **Qué datos hay.** Instante de llegada y tick de cada pulsación, instante que reporta
  cada cliente, latencias medidas con su instante, y si el tick se atrasó. Nada dice quién
  pulsó primero.
- **Qué debe deducir.** El orden probable de las pulsaciones y qué evidencia lo sostiene:
  qué dato es confiable, cuál puede estar mintiendo, cuál es demasiado viejo y cuál no
  distingue dos llegadas del mismo tick. Y si el orden ni siquiera puede establecerse.
- **Qué debe contestar.** Quién gana, con qué evidencia y a quién se le falla; si no hay
  forma justa de decidir, «no lo sé» y qué medición faltó. Quien llegó primero no
  necesariamente pulsó primero, pero compensar sin límite el lag premia a quien lo finge.
- **Por qué es lógica.** Hay dos razones válidas en choque; cuál prevalece se declara una
  vez y vale para toda pulsación. «Empate sin resolver» es distinto de «gana A».

### Situación 4 — Salas balanceadas sin esperar eternamente

- **Qué pasa.** Seis jugadores en la cola: un novato lleva mucho esperando, dos fuertes
  pidieron el mismo juego, dos amigos quieren quedar juntos, uno vetó a otro tras una
  pelea y uno tiene un lag que arruina la trivia. Esperar al rival ideal deja gente
  plantada; formar salas ya genera partidas dispares.
- **Qué datos hay.** Nivel, juego solicitado y tiempo en cola de cada jugador, latencias
  medidas, grupos de amigos, vetos y las salas con lugar.
- **Qué debe deducir.** Qué salas son válidas, quién está en riesgo de esperar de más,
  y, si ningún reparto cumple todo, qué restricción lo impide.
- **Qué debe contestar.** Todos los repartos válidos, el que prefiere tu política y a
  quién se sacrifica; o «no hay reparto» con el motivo. Y qué tendría que cambiar para
  que quien quedó fuera entre.
- **Por qué es lógica.** Son restricciones con varias soluciones válidas, y importa la
  razón de por qué otro reparto no se dio. «Por orden de llegada» es lo obvio; ¿siempre
  es lo justo?

### Situación 5 — La sala cae y el torneo se entera

- **Qué pasa.** Torneo de eliminación de 8 jugadores: cuatro cuartos, dos semifinales y la
  final. Una sala de cuartos cae por un error en plena partida. Las demás siguen (como en
  el original) y sus dos jugadores regresan al lobby, pero la semifinal y la final
  dependen de quién gane ese partido. Hay premio.
- **Qué datos hay.** Qué partido alimenta a cuál, los eventos de la sala hasta que cayó,
  qué jugadores se reconectaron y cuáles partidos ya terminaron.
- **Qué debe deducir.** Qué partidos quedan bloqueados en cascada, a quién espera cada
  uno, y si el resultado del partido caído se puede obtener del registro (partida que ya
  estaba terminada) o no se sabe (partida a medias).
- **Qué debe contestar.** El plan del torneo: qué sigue, qué se suspende y por qué. Si
  una partida a medias ya iba ganada para alguien, él y su rival tienen cada uno su razón:
  deja escrito a quién se le falla y con qué regla.
- **Por qué es lógica.** Un fallo local se propaga por las dependencias entre partidos;
  el gemelo recorre ese grafo y distingue lo que se sabe de lo que se ignora.

## Por qué no basta un script

Con `if tablero[casilla] == vacio: aceptar()` resuelves una jugada con red perfecta. Tu
gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Vale la jugada 5 del jugador B? | decisión |
| ¿Por qué la rechazaste? | explicación |
| ¿Cuáles son todas las jugadas legales de O ahora? | todas las respuestas |
| ¿Qué tendría que haber llegado para que valiera? | la pregunta al revés |
| ¿Y si el lag de A fuera la mitad, quién ganaba la pulsación? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos bastan para reconstruir el tablero sin guardarlo?
2. Cuando dos evidencias chocan (llegada contra reloj del cliente), ¿dónde queda escrito
   cuál gana?
3. ¿Cómo distingue tu gemelo «la jugada es ilegal» de «todavía no sé si es legal»?
4. ¿Qué parte de la explicación puede ver el jugador y cuál solo el operador? ¿Qué
   información no le puedes dar al cliente por seguridad?
5. En tu simulación en Erlang, ¿qué pasaba si el procesamiento de una sala se atrasaba, y
   qué decisión de esa sala saldría mejor de este gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del servidor, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar lecturas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 4 salas y hasta 14 jugadores, contra las 100 salas de 8 jugadores y
  ≈ 24,000 entradas/s del escenario original.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir.
- Inventados por esta extensión: el torneo de 8 jugadores, los niveles, los vetos y los
  grupos de amigos, y la posición de la situación 2. Los identificadores de los ejemplos
  («jugada 5», «jugador B», «sala de cuartos») son ilustrativos.
- Tú defines: la numeración de casillas y las líneas ganadoras, cuánto tarda un jugador
  desconectado en que entre el bot, cuánto atraso de un tick vuelve inordenables dos
  llegadas, cuánta latencia se compensa, qué diferencia de nivel es «balanceada», cuánto
  esperar es «esperar de más» y qué se hace con una partida a medias al caer la sala.
- Trivia: solo modelas el pulsador, no las preguntas.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Ajedrez: jugadas legales por pieza, jaque y tablas.
- Validar velocidad y cadencia de disparo en un juego de acción (trampas por física).
- Reconexión con *snapshot* recortado al área visible: qué se le puede mostrar y qué no.
- Migrar salas entre servidores cuando uno se satura.

---
*Las cifras de dominio (30 ticks/s, 400 ms de lag, 10 % de pérdida, ≈ 24,000 entradas/s,
salas de 8 jugadores) vienen del problema original; el resto son datos del ejercicio.
Verifica la fuente vigente antes de citarlas en tu entrega.*
