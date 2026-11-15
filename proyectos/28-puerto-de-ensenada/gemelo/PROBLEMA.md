# #28 — Puerto de Ensenada: gemelo digital con programación lógica

> Extensión del proyecto #28. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el puerto: muelles y grúas como procesos, buques que
pasan de esperar a atracar, descargar y zarpar, una cola de turnos y fallas inyectadas.
Esa simulación responde «¿qué está pasando en el muelle?». El jefe de operaciones
necesita algo más: «¿qué buque entra a qué muelle, con cuántas grúas, y por qué él
antes que otro?».

El gemelo digital es el **modelo lógico** del puerto: hechos que reflejan su estado y
reglas que reflejan cómo se decide en él. Se escribe en Prolog porque lo que hay que
resolver aquí no es calcular un óptimo, sino repartir recursos que no se pueden
compartir, justificar a quién se le falla y saber cuándo no se sabe.

## El puerto que se clona

El Puerto de Ensenada, reducido a 3 muelles, 5 grúas y 6 buques (uno de ellos crucero).
El tiempo se cuenta en minutos desde el inicio de la ventana de prueba. El práctico, los
remolcadores y el canal los comparten las terminales de contenedores y de cruceros.

| Parte | Contenido |
|---|---|
| Entidades | muelle, grúa, buque, contenedor, pila de patio; práctico y remolcadores como recursos compartidos |
| Estado por buque | tipo (carguero o crucero), llegada estimada, movimientos pendientes, hora límite de zarpe (marea o pasajeros), estado (fondeado, atracado, operando, zarpado) |
| Estado por muelle | qué tipo de buque admite, ventanas de marea y calado, turno programado |
| Estado por grúa | operativa o averiada, buque al que está asignada, ritmo de movimientos por hora |
| Estado por patio | pila y altura de cada contenedor según el registro, hora del registro, buque en que debe salir |
| Eventos | llega un buque (a tiempo, adelantado o tarde), atraca, zarpa, se descompone o se repara una grúa, cambia una ventana de marea, un operador reporta lo que ve en el patio |
| Decisiones | ¿qué buque en qué muelle y cuándo?, ¿cuántas y cuáles grúas?, ¿se reasigna una grúa?, ¿quién cede el turno?, ¿se carga sin este contenedor? |

## Situaciones que tu gemelo debe razonar

Las cinco parten del problema original (dos buques por un muelle, rebalanceo de grúas,
grúa que se descompone con un buque tarde, crucero contra carguero, contenedores mal
registrados); algunas añaden complementos derivados del foco «turnos de atraque y
asignación de grúas». En cada una, tu gemelo debe llegar a una decisión **y poder
explicarla**.

### Situación 1 — Dos buques, un muelle y ocho horas de retraso

- **Qué pasa.** Dos buques piden el mismo muelle en horarios que se traslapan. Uno de
  ellos es el que llega ocho horas tarde por mal clima y ocupa, sin quererlo, el muelle
  del siguiente. Atracar exige además práctico, remolcadores y una ventana de marea y
  calado. El buque que se queda fondeado cuesta miles de dólares por cada hora.
- **Qué datos hay.** Turnos programados, llegada estimada actualizada de cada buque,
  duración estimada de su operación, ventanas de cada muelle y disponibilidad del
  práctico y de los remolcadores.
- **Qué debe deducir.** Qué turnos son compatibles: ningún muelle con dos buques a la
  vez, cada atraque con práctico, remolcadores y calado a su hora. Y qué calendarios
  completos existen.
- **Qué debe contestar.** El calendario elegido, el criterio que lo decidió y a quién se
  le falla: cuánto más espera ese buque fondeado que en el calendario contrario. Todos
  los calendarios válidos si se piden; si no hay ninguno, la restricción que lo impide.
- **Por qué es lógica.** Un muelle y un práctico no se comparten en el mismo instante:
  es calendarizar con restricciones, no ordenar por hora de llegada.

### Situación 2 — Cinco grúas, tres buques que las quieren

- **Qué pasa.** Un buque termina antes de lo previsto y libera grúas. Otros dos siguen
  operando y las quieren: uno con muchos contenedores pendientes y salida lejana, otro
  con menos pendientes pero con la marea cerrándose. Cada buque lleva de una a tres
  grúas, y rebalancear no debe hacer que ninguno pierda avance. Cada minuto de más en el
  muelle es dinero.
- **Qué datos hay.** Movimientos pendientes por buque, grúas asignadas, el ritmo de
  movimientos por hora que da el original, el mínimo y máximo de grúas por buque y la
  hora límite de zarpe de cada uno.
- **Qué debe deducir.** Qué buques llegan a su hora límite con las grúas que tienen y
  qué repartos de las cinco grúas hacen que todos lleguen. Ese margen no lo mide ningún
  dato: sale de cruzar pendientes, grúas, ritmo y límite.
- **Qué debe contestar.** El reparto, y si ninguno cumple para todos, qué buque queda mal
  y por cuánto, y qué tendría que cambiar para que cumpliera. Lo intuitivo es dar más
  grúas a quien tiene más contenedores pendientes; es sospechoso porque lo que cuenta es
  el margen contra la salida y el tope de grúas por buque, no el volumen.
- **Por qué es lógica.** El reparto completo debe cumplir varias restricciones a la vez;
  una grúa dada a uno es una grúa que falta a otro.

### Situación 3 — La grúa que se paró a media operación

- **Qué pasa.** Una grúa se descompone a mitad de la operación de un buque. Sin ella, el
  buque ya no termina antes de que se cierre su ventana de marea; si la pierde, sigue
  ocupando el muelle que otro buque tenía programado, ese otro espera fondeado, y su
  práctico y sus remolcadores quedan reservados para un atraque que no ocurrirá. Puede
  que haya un estimado de reparación o que no.
- **Qué datos hay.** La hora de la falla, los movimientos pendientes, las grúas
  operativas, las ventanas de marea, los turnos siguientes y, si existe, el estimado de
  reparación.
- **Qué debe deducir.** Cuántas grúas efectivas le quedan al buque, si llega a su
  ventana, qué muelle queda ocupado de más, qué buques se retrasan por eso y si los
  recursos reservados siguen alcanzando. Cada eslabón es consecuencia del anterior.
- **Qué debe contestar.** La cascada, con la razón de cada eslabón; si hay una grúa de
  otro buque que se puede prestar sin que este pierda su salida; y el veredicto con
  reparación y sin ella, marcando cuál de los dos casos no se sabe.
- **Por qué es lógica.** La consecuencia de una falla viaja por la red de turnos, grúas y
  ventanas. Ningún sensor dice «el siguiente buque se va a retrasar».

### Situación 4 — Crucero o carguero

- **Qué pasa.** Un crucero y un carguero piden el mismo muelle. El crucero tiene horarios
  fijos de pasajeros que debe cumplir antes de zarpar; el carguero cuesta miles de
  dólares por hora si espera. Lo intuitivo es que el crucero siempre va primero, y eso es
  sospechoso: si el crucero no necesita el muelle todavía, quizá el carguero cabe antes y
  nadie pierde. Pero si el carguero se atrasa un poco, el hueco desaparece y sí hay a
  quién fallarle.
- **Qué datos hay.** Horario de abordaje y hora límite de zarpe del crucero, llegada y
  duración estimada del carguero, el hueco libre del muelle y el costo de la espera como
  dato que fijas tú.
- **Qué debe deducir.** Si el carguero cabe completo antes de que el crucero necesite el
  muelle, y qué cambia cuando se le suma un retraso. El «cabe» no está en ningún dato.
- **Qué debe contestar.** Quién atraca primero y por qué; si hay que fallarle a alguien,
  a quién y cuánto le cuesta; y qué tendría que cambiar para que el veredicto fuera el
  contrario.
- **Por qué es lógica.** Dos partes tienen razón y la prioridad se declara una vez, con
  sus excepciones, y vale para todos los buques. Lo que cambia es el hueco, no la regla.

### Situación 5 — El contenedor que el registro ubica y el patio no

- **Qué pasa.** Un contenedor debe cargarse en un buque que está por zarpar. El registro
  lo ubica en una pila; el operador de patio no lo ve ahí, o aparece anotado en dos
  pilas, o su registro es de hace mucho. Los contenedores se apilan por orden de salida y
  sacar uno enterrado obliga a remover los de encima, con movimientos de grúa que otro
  buque necesitaba. Si no sale, un cliente pierde su embarque.
- **Qué datos hay.** Registro de pila y altura con su hora, reportes de los operadores,
  el orden de apilado, el buque de salida de cada contenedor y la hora límite del buque.
- **Qué debe deducir.** En qué posiciones puede estar según el registro y los reportes,
  cuántas remociones costaría llegar a cada una y si los movimientos disponibles alcanzan
  antes de que zarpe el buque.
- **Qué debe contestar.** Tres respuestas distintas: «se carga a tiempo», «no se carga a
  tiempo» y «no se sabe dónde está». Para la tercera, qué inspección lo resolvería; para
  las otras, cuántas remociones y a qué buque le quitan movimientos.
- **Por qué es lógica.** «No aparece» no es «no está» ni «está donde dice el registro». El
  estado real del patio se deduce de varias fuentes que pueden contradecirse.

## Por qué no basta un script

Con `if grua_libre: asignarla_al_buque_con_mas_contenedores()` resuelves un muelle con
datos perfectos y sin fallas. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué buque entra al muelle 2 y con qué grúas? | decisión |
| ¿Por qué el carguero antes que el crucero? | explicación |
| ¿De cuántas formas puedo repartir las cinco grúas hoy? | todas las respuestas |
| ¿Qué tendría que pasar para que el buque 4 zarpe a tiempo? | la pregunta al revés |
| ¿Qué pasa si la grúa 3 tarda más en repararse? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Cómo dices que un muelle, una grúa, el práctico o los remolcadores no se pueden
   compartir en el mismo instante?
2. Crucero o carguero: ¿dónde queda escrita la prioridad, qué la cambia y a quién se le
   falla cuando manda?
3. ¿Cómo distingue tu gemelo «el contenedor no está» de «no sé dónde está»?
4. ¿Qué parte de la explicación le sirve al jefe de operaciones y qué parte es ruido?
5. ¿Qué procesos de tu simulación en Erlang (el muelle, la grúa, el buque) podrían
   alimentar a este gemelo con sus hechos?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del puerto, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar llegadas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 3 muelles, 5 grúas y 6 buques con un crucero, contra los 12 buques y
  2 cruceros de una semana del escenario original.
- Qué tipo de buque admite cada muelle, las ventanas de marea y calado, la disponibilidad
  del práctico y de los remolcadores, los movimientos pendientes de cada buque, las pilas
  del patio y lo que tarda una grúa en pasar de un buque a otro son datos inventados que
  defines tú. No son cifras del Puerto de Ensenada.
- El «ahora» es un hecho del modelo, en minutos, no el reloj del sistema.
- Quedan a decisión del estudiante: cuánto vale una hora de espera, cuánto margen pides
  frente a la marea, cuánto tarda una reparación cuando no hay estimado y qué registro de
  patio ya es demasiado viejo para fiarse.
- Los identificadores de los ejemplos («buque 4», «grúa 3», «muelle 2») son ilustrativos.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Viento que cierra el canal y cambia todas las ventanas de atraque a la vez.
- Cuadrillas con turnos y descansos que limitan cuántas grúas pueden operar.
- Remolcadores ocupados por otro buque que sale al mismo tiempo.
- Planear el apilado del patio desde la entrada para reducir remociones futuras.
- Buques de granel y de pesca que compiten por los mismos muelles.

---
*Las cifras de dominio (25-35 movimientos por hora por grúa, 1-3 grúas por buque, pilas de
3-5 alturas, un buque que llega 8 horas tarde, 3 muelles, 5 grúas, 12 buques y 2 cruceros
en una semana, y el costo de miles de dólares por hora en muelle) vienen del problema
original. Verifica la fuente vigente antes de citarlas en tu entrega.*
