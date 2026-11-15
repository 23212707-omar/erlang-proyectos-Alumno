# #73 — Quiniela del Mundial: gemelo digital con programación lógica

> Extensión del proyecto #73. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la quiniela: miles de pronósticos que entran en los
últimos segundos, resultados en vivo, un gol anulado por el VAR y un ranking que se
recalcula para muchos usuarios. Esa simulación responde «¿aguanta el sistema?». Quien
organiza la quiniela necesita otra cosa: «¿cuántos puntos tiene cada quien, por qué, y
quién todavía puede ganar?».

El gemelo digital es el **modelo lógico** de la quiniela: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque lo que hay que
resolver aquí no es calcular rápido, sino deducir, justificar y descartar.

## La quiniela que se clona

Un torneo de eliminación directa reducido y dos quinielas privadas con reglamento propio.
Seis participantes repartidos entre ambas (algunos juegan en las dos).

| Parte | Contenido |
|---|---|
| Entidades | torneo → fase → partido → selección; quiniela → participante → pronóstico |
| Estado | partido: hora programada, inicio real, eventos, marcador; pronóstico: marcador y hora de recepción; quiniela: reglamento y desempates |
| Eventos | llega un pronóstico, inicio, gol, tiempo extra, penales, gol anulado por VAR, una fuente externa publica |
| Decisiones | ¿vale el pronóstico?, ¿cuántos puntos?, ¿quién va primero?, ¿quién aún puede ganar? |

## Situaciones que tu gemelo debe razonar

Cuatro salen del problema original (casos difíciles, escenario y datos del mundo real);
la quinta, «¿Todavía puede ganar?», se deduce de los bonos por fase del original y del
foco de la extensión. En cada una, tu gemelo debe llegar a una decisión **y poder
explicarla**.

### Situación 1 — El pronóstico que llegó con el silbatazo

- **Qué pasa.** Faltan segundos para que ruede el balón y entra la oleada de pronósticos.
  Uno llega justo en el límite: el teléfono de la participante marcó una hora, el
  servidor otra, y el partido pudo empezar antes o después de lo programado. Pasado el
  bloqueo nadie cambia su pronóstico.
- **Qué datos hay.** La hora programada, el inicio real si ya ocurrió y, por cada
  pronóstico, la hora que registró el servidor y la que declaró el aparato del
  participante (con relojes desfasados o ausente).
- **Qué debe deducir.** Si el pronóstico quedó dentro o fuera; qué hora de inicio y qué
  reloj son oficiales; y qué pasa cuando los datos no alcanzan para decidir.
- **Qué debe contestar.** Aceptado, rechazado o «no se sabe», con la razón y el dato que
  faltaría para decidir.
- **Por qué es lógica.** Hay dos horas de inicio y dos relojes que se contradicen, y la
  regla que elige debe quedar escrita una vez para todos los pronósticos. Alguien sale
  perjudicado: la persona con mala conexión o la quiniela, que no puede dar ventaja.
  Lo intuitivo es creerle a la hora que trae el pronóstico; revisa por qué es sospechoso
  cuando quien la declara es quien más gana con ella.

### Situación 2 — Mismo partido, dos quinielas, puntos distintos

- **Qué pasa.** Un partido de eliminación directa termina empatado en el tiempo
  reglamentario, hay tiempo extra y se define en penales. Ana y Beto juegan en la
  quiniela de la oficina y en la de la prepa, y cada reglamento entiende «el resultado»
  a su manera. Las reglas de puntos cambian entre quinielas.
- **Qué datos hay.** Los eventos del partido con su instante (goles, entretiempo, tiempo
  extra, penales), el pronóstico de cada uno y el reglamento de cada quiniela: puntos
  por marcador exacto, por acertar ganador o empate, y bonos por fase.
- **Qué debe deducir.** Cuántos puntos tiene cada participante en cada quiniela. Ningún
  dato dice «puntos»: salen de qué marcador cuenta en esa quiniela, qué clase de acierto
  fue, en qué fase se jugó el partido y qué bono corresponde.
- **Qué debe contestar.** Los puntos con su desglose, y por qué el mismo pronóstico vale
  distinto en dos quinielas.
- **Por qué es lógica.** Son cuatro o más deducciones encadenadas y el reglamento es un
  dato, no código. Lo intuitivo es que quien clavó el marcador con el que «terminó» el
  partido se lleva el premio mayor; verifica qué significa «terminó» en cada quiniela.

### Situación 3 — El gol que dejó de existir

- **Qué pasa.** Minutos después de un gol, el VAR lo anula. Entre uno y otro, el
  ranking se publicó y la quiniela de la oficina ya felicitó a su líder de la jornada.
  Una fuente externa ya trae el marcador corregido y otra no: los datos externos llegan
  con retraso y pueden ser inconsistentes.
- **Qué datos hay.** Los eventos del partido con su instante, lo que reportó cada fuente
  y cuándo, y el ranking publicado antes de la anulación.
- **Qué debe deducir.** El marcador vigente (o si aún no se puede afirmar), a quién le
  cambian los puntos y a quién la posición, y qué parte de lo publicado quedó mal.
- **Qué debe contestar.** El marcador vigente o «no se sabe», y los afectados con su antes
  y su después. En hipótesis: qué cambiaría si la anulación llegara tras el silbatazo
  final.
- **Por qué es lógica.** Es un dato dudoso y un dilema real: quien celebró y quien perdió
  el primer lugar por un gol inexistente tienen razón a la vez, y la regla debe decidir
  y justificar a quién se le falla. Lo intuitivo es que la corrección solo quita puntos
  a quien acertó el gol; comprueba si es cierto.

### Situación 4 — Tres empatados en el tercer lugar

- **Qué pasa.** Al cierre de la jornada, tres participantes tienen el mismo puntaje en
  tercer lugar y la quiniela reconoce hasta el tercero. Los empates deben resolverse con
  criterios claros; cada quiniela tiene los suyos y un orden para aplicarlos. Aún faltan
  partidos por jugarse.
- **Qué datos hay.** Puntos con su desglose, el momento en que se envió cada pronóstico,
  los criterios de desempate de cada quiniela y los partidos pendientes.
- **Qué debe deducir.** La posición de cada uno, qué criterio rompió el empate, y si el
  empate que queda es definitivo o provisional por los partidos que faltan.
- **Qué debe contestar.** Posiciones con el criterio decisivo de cada una; si agotados
  los criterios siguen empatados, decirlo en vez de inventar un orden.
- **Por qué es lógica.** Es una política: un orden de criterios declarado una vez. Los
  mismos tres quedan en lugares distintos en las dos quinielas y ambas son correctas.
  Lo intuitivo es que todo empate se rompe; revisa si es cierto y qué tan justo es
  desempatar por orden alfabético o por orden de registro.

### Situación 5 — ¿Todavía puede ganar?

- **Qué pasa.** Quedan las semifinales y la final. El líder lleva ventaja; la última
  lleva menos puntos, pero eligió como campeón a una selección que sigue viva. El
  máximo goleador aún no está definido. Alguien pregunta quién ya no puede ganar la
  quiniela y alguien más si le conviene seguir pronosticando.
- **Qué datos hay.** Puntos actuales, partidos pendientes, bonos por fase (campeón,
  goleador), pronósticos especiales, selecciones eliminadas y goles por jugador.
- **Qué debe deducir.** Cuántos puntos puede alcanzar aún cada participante, qué bonos ya
  son imposibles y cuáles no se pueden afirmar todavía, y quién sigue en la pelea.
- **Qué debe contestar.** Para cada participante, «puede», «ya no puede» o «depende», con
  la evidencia; y, al revés, qué tendría que pasar para que la última llegue a ganar.
- **Por qué es lógica.** Encadena selección eliminada, bono imposible, máximo alcanzable
  y comparación con el líder; y separa «el bono ya no existe» de «el bono aún no se
  decide». Lo intuitivo es que el primero va ganando seguro y la última está fuera.

## Por qué no basta un script

Con `if hora_del_telefono < hora_de_inicio: aceptar()` resuelves un pronóstico con relojes
perfectos. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué hago con el pronóstico de Ana en la semifinal? | decisión |
| ¿Por qué lo aceptaste (o no)? | explicación |
| ¿Quiénes aún pueden ganar la quiniela de la oficina? | todas las respuestas |
| ¿Qué tendría que pasar para que Beto llegue al primer lugar? | la pregunta al revés |
| ¿Qué pasaría si el VAR anula el último gol de la semifinal? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir un pronóstico y el momento en que llegó?
2. ¿Quién decide la hora oficial de bloqueo y con qué reloj, y dónde queda escrito?
3. ¿Cómo distingue tu gemelo «no ganó puntos» de «todavía no se sabe si los gana»?
4. ¿Dónde vive el reglamento de cada quiniela para que cambiarlo no obligue a tocar las
   reglas generales?
5. En tu simulación en Erlang, ¿qué recalculabas completo y qué de forma incremental, y
   qué dato de ella alimentaría a este gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la quiniela, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar pronósticos simulados
  o graficar el ranking.

## Supuestos de esta extensión

- Escala reducida: 6 participantes, 2 quinielas y un torneo de eliminación directa de 8
  selecciones y 7 partidos, contra los 5,000 participantes, 50 quinielas y 64 partidos
  del escenario original.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir.
- Los nombres (Ana, Beto), las selecciones, los marcadores y los partidos de los
  ejemplos son ilustrativos y del ejercicio, no resultados reales.
- Del original solo vienen 3 puntos por marcador exacto, 1 por acertar ganador o empate
  y «bonos por fases (campeón, goleador)». Los demás reglamentos de cada quiniela (qué
  marcador cuenta, valor de los bonos, criterios de desempate y su orden) los defines tú.
- La diferencia que toleras entre relojes y qué tan viejo debe ser un dato para dejar
  de creerle los defines tú: el original no da esas cifras.
- Los 2,000 pronósticos en 60 segundos y los límites de las APIs externas son de la
  parte de Erlang; aquí importa qué hacer con un pronóstico y con un dato dudoso.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Una quiniela que cambia su reglamento a medio torneo y debe decidir qué se recalcula.
- Fase de grupos con selecciones empatadas y sus propios criterios de desempate.
- Un participante que juega en varias quinielas con un solo envío de pronósticos.
- Una fuente externa que se retrasa o contradice a otra durante horas, no minutos.

---
*Las cifras de dominio son de referencia y vienen del problema original. Verifica la
fuente vigente antes de citarlas en tu entrega.*
