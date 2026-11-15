# #24 — Cruce CBX / puente peatonal: gemelo digital con programación lógica

> Extensión del proyecto #24. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el puente: un proceso por ventanilla, un generador de
llegadas y un estimador de espera. Esa simulación responde «¿cuánta gente hay en cada
fila y cuánto tarda?». Quien opera el cruce necesita algo más: «¿cuántas ventanillas abro
en cada módulo, a quién atiendo primero, qué espera le publico a quien está decidiendo si
cruza, y por qué?».

El gemelo digital es el **modelo lógico** del puente: hechos que reflejan su estado y
reglas que reflejan cómo se decide en él. Se escribe en Prolog porque lo que hay que
resolver no es sumar colas, sino repartir lo que no alcanza, deducir lo que ningún
sensor mide y saber decir «no lo sé».

## El puente que se clona

Un puente peatonal cerrado como el de Cross Border Xpress (unos 390 metros entre el
aeropuerto y una terminal al otro lado de la frontera), reducido a un solo sentido de
cruce, 3 módulos en serie y una hora de operación con un bloque de vuelos. El escenario
es el del problema original, a escala pequeña; los complementos que no trae se listan en
«Supuestos».

| Parte | Contenido |
|---|---|
| Entidades | puente → 3 módulos en serie (venta/validación, revisión migratoria, inspección aduanera) → ventanillas; personal del turno; vuelos del itinerario; personas con pase vigente |
| Estado por módulo | ventanillas abiertas según el plan y cuáles atienden de verdad, personas en fila y en el tramo que lo separa del siguiente, tiempo de servicio observado (1 a 5 min por persona), tope de personas por hora |
| Estado por persona | vuelo con su hora, módulo en que está, cuándo se formó, prioridad declarada (tripulación, discapacidad, adulto mayor) y si consta |
| Eventos | se acerca un vuelo, llega una persona, termina una atención, una ventanilla se cierra, se publica una espera |
| Decisiones | ¿cuántas ventanillas abrir y con qué personal?, ¿quién pasa primero?, ¿qué ventanilla se da por caída?, ¿qué espera publicar? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original (sus datos del mundo real, su escenario y sus casos
difíciles). Las situaciones 1, 4 y 5 añaden complementos que el original no trae y que se
declaran en «Supuestos». En cada una, tu gemelo debe llegar a una decisión **y poder
explicarla**.

### Situación 1 — Llega un vuelo con 180 pasajeros y el personal no alcanza

- **Qué pasa.** En plena hora pico, con unas 600 personas por hora entrando, aterriza un
  vuelo con 180 pasajeros que llegan al puente al mismo tiempo. Cada módulo tiene un tope
  de personas por hora y cada persona tarda de 1 a 5 minutos en una ventanilla. El turno
  tiene personal para abrir ventanillas, pero no para abrirlas todas en los tres módulos.
  Si el gemelo se equivoca, 180 personas esperan de más y alguien pierde su vuelo.
- **Qué datos hay.** El itinerario con sus horas y pasajeros, las ventanillas que hay en
  cada módulo, el personal del turno, el tope por hora y los tiempos de servicio
  observados. Ningún dato dice «la demanda de la próxima hora» ni «este módulo no
  alcanzará».
- **Qué debe deducir.** Cuánta gente llegará a cada módulo y cuándo (el vuelo cae primero
  en uno y después en los siguientes, con desfase); qué módulos no alcanzan con lo abierto
  hoy; y cuáles repartos de ventanillas y personal sí alcanzan.
- **Qué debe contestar.** El reparto por módulo y por tramo de la hora; todos los repartos
  válidos, si hay varios; y, si ninguno cabe, qué módulos y qué límites lo impiden y qué
  habría que sacrificar.
- **Por qué es lógica.** Abrir una ventanilla en un módulo es no abrirla en otro: es
  repartir con restricciones, no comparar una fila con un número. Y la demanda no es un
  dato: es un calendario de vuelos que se convierte en carga.

### Situación 2 — La ventanilla que se apagó sin avisar

- **Qué pasa.** En revisión migratoria el plan dice que cuatro ventanillas están
  abiertas, pero una deja de registrar atenciones. Como cada persona puede tardar hasta 5
  minutos, el silencio puede ser un cierre sin aviso o una atención larga. Nadie la
  declaró cerrada, así que el plan sigue contándola. Detrás hay una fila que cree que
  avanza.
- **Qué datos hay.** La orden de apertura, las atenciones registradas con su hora, los
  tiempos de servicio y la fila frente a cada ventanilla.
- **Qué debe deducir.** Si la ventanilla atiende, está caída o no se sabe; la capacidad
  real del módulo bajo cada posibilidad; y qué cambia en el reparto de la Situación 1
  si de verdad está caída.
- **Qué debe contestar.** Un veredicto por ventanilla (atiende, cerrada, no se sabe) con
  su evidencia; la capacidad efectiva del módulo en cada caso; qué dato aclararía la duda;
  y qué hacer con la gente de esa fila. Mover la fila le falla a quien está a medio
  trámite; no moverla, a quien espera ante una ventanilla muerta.
- **Por qué es lógica.** Lo que dice el sistema (abierta) contradice lo que se observa
  (nadie atiende). «Cerrada» y «no lo sé» son respuestas distintas con consecuencias
  distintas, y la abierta en el plan puede ser la que no cuenta.

### Situación 3 — El cuello de botella no está donde está la fila

- **Qué pasa.** La inspección aduanera atiende despacio y su fila llena el tramo que la
  separa del módulo anterior. Quienes ya terminaron la revisión migratoria no pueden
  avanzar y se quedan ocupando su ventanilla; las ventanillas de migración parecen
  abiertas y con personal, pero ya no atienden. La fila de migración crece y llena a su
  vez el tramo de venta/validación, y la fila llega a la entrada del puente. La fila más
  larga está al principio; la causa, tres módulos más allá.
- **Qué datos hay.** Personas en fila y en cada tramo, ventanillas abiertas por módulo,
  tiempos de servicio y qué cabe en cada tramo. Ningún dato dice «bloqueado».
- **Qué debe deducir.** Qué módulos están bloqueados por otro, en qué orden se propagó y
  dónde está el origen; y qué aperturas destraban el puente y cuáles no.
- **Qué debe contestar.** El origen del problema, la cadena que lo une con la fila de la
  entrada y dónde conviene abrir ventanillas. Lo intuitivo es abrir donde está la fila
  más larga; es sospechoso porque ese módulo no es la causa y abrir allí solo manda más
  gente a un tramo que ya no cabe.
- **Por qué es lógica.** Cada bloqueo nace de otro: la cadena se deduce, no se recorre
  con un ciclo. Una cola es síntoma; la causa solo aparece al relacionar módulos.

### Situación 4 — La prioridad contra el vuelo que sale pronto

- **Qué pasa.** En la fila de migración hay personas con prioridad (tripulaciones,
  personas con discapacidad, adultos mayores) y personas sin ella. Dos con prioridad
  llegan seguidas. Quien lleva más tiempo esperando, sin prioridad, tiene un vuelo que
  sale pronto. Además, alguien dice ser adulto mayor sin que conste (o se capturó mal), y
  otra persona entra en dos categorías a la vez.
- **Qué datos hay.** Personas con su hora de llegada a la fila, categoría declarada, si
  consta o no, hora de su vuelo y ventanillas disponibles.
- **Qué debe deducir.** El orden de atención y a quién le llega tarde su vuelo con ese
  orden; y qué cuenta una prioridad que no se puede comprobar: ni cierta ni falsa.
- **Qué debe contestar.** El orden completo con la razón de cada puesto; a quién se le
  falla (a quien lleva la prioridad o a quien pierde el vuelo) y por qué ese criterio y
  no otro; el trato de la prioridad dudosa; y qué tendría que cambiar para que el orden
  fuera el contrario.
- **Por qué es lógica.** Es un dilema: respetar la prioridad y evitar que alguien pierda
  su vuelo son dos razones válidas que chocan. La regla que desempata se escribe una vez,
  vale para toda la fila y debe poder justificarse ante quien pierde.

### Situación 5 — La espera que lees en la pantalla

- **Qué pasa.** Una persona mira la espera publicada y decide si cruza. En los últimos
  minutos solo han terminado dos atenciones en revisión migratoria, un vuelo viene en
  camino y parte de la fila avanzará por prioridad. Si el número es bajo y falso, la
  persona se forma y pierde su vuelo; si es alto y falso, se va sin necesidad.
- **Qué datos hay.** Fila y ventanillas efectivas por módulo (las Situaciones 2 y 3),
  tiempos de servicio recientes con su hora, vuelos próximos y prioridades presentes.
  Ningún dato es «la espera de quien llega ahora».
- **Qué debe deducir.** La espera de quien llega ahora, módulo por módulo y en total,
  contando los bloqueos, a quienes lo adelantarán y a quienes llegarán antes de que le
  toque; y cuánta base tiene ese número: si hay pocos datos recientes, no lo sabe.
- **Qué debe contestar.** La espera con el cálculo de dónde sale, o «no lo sé» con lo que
  faltaría; y cuánto bajaría si se abre una ventanilla. Lo intuitivo es publicar lo que
  muestra la fila de hoy; es sospechoso porque una fila corta ahora puede ser una espera
  larga en diez minutos.
- **Por qué es lógica.** La espera no se mide: se deduce de lo que dicen las demás
  situaciones. Y publicar un número sin base es afirmar lo que no se sabe.

## Por qué no basta un script

Con `if cola > limite: abrir_ventanilla(modulo)` abres una ventanilla donde hay fila, con
una sola fila y sin que nadie esté bloqueado. Tu gemelo debe contestar, **con las mismas
reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Cuántas ventanillas abro en cada módulo para el vuelo 8? | decisión |
| ¿Por qué no abrir otra en venta? | explicación |
| ¿De cuántas formas puedo repartir al personal en la hora pico? | todas las respuestas |
| ¿Qué tendría que pasar para publicar «15 minutos»? | la pregunta al revés |
| ¿Qué pasa si migración pierde una ventanilla ahora? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué significa que una ventanilla esté «abierta»: lo que dice el plan o lo que se ve
   atender?
2. ¿Dónde queda escrito cuándo un módulo bloquea a otro, y cómo se encadena hasta la
   entrada del puente?
3. ¿Cómo distingue tu gemelo «la espera es corta» de «no tengo datos para decirlo»?
4. Cuando la prioridad de una persona choca con el vuelo de otra, ¿dónde queda escrito a
   quién se le falla?
5. En Erlang cada ventanilla es un proceso y el estimador calcula la espera. ¿Qué de eso
   podría alimentar a este gemelo, y qué decide el gemelo que el proceso no puede?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del puente, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra el reparto
  de ventanillas y la espera con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar llegadas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: un sentido de cruce, 3 módulos y hasta 4 ventanillas por módulo
  (contra las 2 a 6 del original), una hora de operación y unos pocos vuelos, uno de
  ellos con 180 pasajeros. Los números de vuelo y de ventanilla de los ejemplos son
  ilustrativos.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir.
- Complementos que el original no trae: el personal del turno como recurso que alcanza
  para abrir solo parte de las ventanillas; el tramo entre módulos con capacidad limitada;
  la hora del vuelo de cada persona (derivada del pase de abordar); que la prioridad
  declarada conste o no; y que el cierre de una ventanilla pueda no avisarse.
- Tú defines: el personal disponible y qué módulos puede cubrir cada persona; el tope de
  personas por hora de cada módulo (el original dice que existe, sin cifra); cuánta
  gente cabe en cada tramo; cuántos minutos de silencio vuelven dudosa a una ventanilla;
  cuántas observaciones bastan para publicar una espera; cuándo un vuelo ya está en
  riesgo; y qué manda, la prioridad o el vuelo. Decláralo.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Los dos sentidos a la vez, compartiendo el personal del turno.
- Cambio de turno a media hora pico y personal que se retira antes de tiempo.
- Un vuelo cancelado o adelantado que cambia la demanda que ya estaba prevista.
- Avisar a la aerolínea cuando la espera pone en riesgo a sus pasajeros.
- Cierre del puente por una emergencia y qué pasa con quienes ya están dentro.

---
*Las cifras (3 módulos, 2 a 6 ventanillas, 600 personas por hora en pico, un vuelo de 180
pasajeros, 1 a 5 minutos por persona, unos 390 metros) vienen del problema original; lo
demás es escala o complemento declarado arriba. Verifica la fuente vigente antes de
citarlas en tu entrega.*
