# #74 — Radio o streaming: gemelo digital con programación lógica

> Extensión del proyecto #74. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la radio: cientos de oyentes con el mismo audio, una
cola que cambia por votos, una ráfaga de votos desde pocas cuentas y un archivo que se
corrompe. Esa simulación responde «¿aguanta y sigue sonando?». Quien opera la radio
necesita otra cosa: «¿qué suena después, por qué, y a quién le fallo con esa decisión?».

El gemelo digital es el **modelo lógico** de la radio: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque lo que hay que
resolver aquí no es transmitir rápido, sino deducir, justificar y descartar.

## La radio que se clona

Una radio en línea colaborativa, reducida a 10 canciones en el catálogo, 5 votantes y 8
oyentes conectados. La comunidad propone y vota; la radio decide qué suena y responde
por lo que emite.

| Parte | Contenido |
|---|---|
| Entidades | catálogo → canción → licencia; cuenta (de una persona que no ves); cola → propuesta → votos; oyente |
| Estado | canción: duración, licencia, estado del archivo; cuenta: señales observables (dispositivo, red, hora de alta); cola: quién propuso qué y con cuántos votos; emisión: qué suena, desde cuándo y qué sigue; oyente: retraso medido, si se midió |
| Eventos | llega un voto, se propone una canción, empieza o termina una canción, se daña un archivo, un oyente se conecta, se atrasa o reconecta |
| Decisiones | ¿cuenta este voto y cuánto vale?, ¿puede sonar esta canción?, ¿cuál es la siguiente?, ¿qué suena si no hay nada que ponga? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original (escenario, casos difíciles, datos del mundo real
y preguntas guía); los detalles que las completan son de esta extensión. En cada una, tu
gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — Tres cuentas, cien votos

- **Qué pasa.** En diez segundos entra una avalancha de votos por la misma canción, y
  todos vienen de tres cuentas. Otra canción reúne votos de varias cuentas distintas.
  Dos de las tres cuentas se conectan desde el mismo aparato; la tercera, desde la misma
  red que un amigo que vota por su cuenta.
- **Qué datos hay.** Los votos con su instante y su cuenta, y las señales observables de
  cada cuenta (dispositivo, red, hora de alta). Ningún dato dice «misma persona».
- **Qué debe deducir.** Qué cuentas son probablemente la misma persona y con qué
  evidencia, cuánto vale el voto de cada cuenta, y qué canción gana según personas y no
  según votos crudos.
- **Qué debe contestar.** Voto por voto: cuenta, no cuenta o «no se sabe» (sospecha, no
  prueba), con su peso y la razón; y qué cambiaría si una cuenta fuera de otra persona.
- **Por qué es lógica.** «Persona» es algo que nadie mide: se deduce de varias señales
  que casi nunca prueban nada por sí solas. Hay un dilema real: la radio no puede dejar
  que alguien con varias cuentas decida, pero tampoco castigar a dos hermanos que
  comparten red y aparato. Lo intuitivo es que gana la canción con más votos; revisa por
  qué es sospechoso, y revisa también si descartar toda cuenta sospechosa es justo.

### Situación 2 — El voto que llegó con el último acorde

- **Qué pasa.** Para no dejar silencio, la radio debe decidir la siguiente canción antes
  de que termine la actual (el audio sale en segmentos de 2 a 10 segundos). Un voto
  llega justo en esa frontera. Quien lo emitió tiene mala red y oye con retraso: para él,
  la canción aún no acababa cuando votó. Pierde el tema que apoyaba, por segundos.
- **Qué datos hay.** El fin de la canción, el cierre de la decisión de la siguiente, el
  instante en que el servidor recibió el voto, la hora que declaró el aparato y el
  retraso medido del oyente (o su ausencia).
- **Qué debe deducir.** Si el voto entró antes o después del cierre, con qué reloj, y qué
  pasa con un voto tardío: ¿se pierde o pasa a la siguiente ronda?
- **Qué debe contestar.** «Entró», «no entró» o «no se sabe» (retraso sin medir), con la
  razón y el dato que faltaría para decidir.
- **Por qué es lógica.** Dos relojes y dos versiones de «ahora» se contradicen, y la regla
  que elige debe quedar escrita una vez para todos los votos. Alguien sale perjudicado: el
  oyente de mala red o la radio, que no puede reabrir una decisión ya tomada. Lo intuitivo
  es que si votó antes de que acabara la canción, su voto cuenta; compruébalo.

### Situación 3 — La más votada no puede sonar

- **Qué pasa.** Una canción lidera la cola con holgura, pero nadie sabe con certeza bajo
  qué licencia se puede difundir. Se emite música con licencia; las sociedades de gestión
  cobran derechos de ejecución pública y muchas radios usan solo música libre (Creative
  Commons). La radio de este ejercicio se compromete con sus patrocinadores a no emitir
  nada que no esté claramente cubierto. Si se equivoca, paga ella; si se niega, la
  comunidad se queda sin su canción.
- **Qué datos hay.** Por canción, su licencia (libre, de una sociedad de gestión o sin
  dato), sus votos y qué tipos de licencia puede emitir la radio.
- **Qué debe deducir.** Qué canciones son elegibles para sonar. Ningún dato dice
  «elegible»: sale de la licencia, de lo que la radio puede emitir y de si el dato de la
  licencia es confiable. Y de ahí, cuál es la primera de la cola que sí puede sonar.
- **Qué debe contestar.** Para cada canción: «puede sonar», «no puede» o «no se sabe»
  (licencia sin dato), con la razón; y cuál es la siguiente de verdad.
- **Por qué es lógica.** Encadena licencia, permiso de la radio, elegibilidad y posición
  efectiva en la cola, y separa «no se puede» de «no sé si se puede». Hay un dilema real:
  la comunidad y la radio tienen razón a la vez. Lo intuitivo es que manda el voto;
  revisa quién más tiene que dar su permiso.

### Situación 4 — La cola que alguien quiere llenar

- **Qué pasa.** Un votante aprendió a saturar la cola: propone muchas canciones y las
  vota todas; otros dos proponen una cada uno. Hace falta limitar y ponderar. Además, dos
  canciones empatan en el primer lugar mientras siguen llegando votos.
- **Qué datos hay.** Quién propuso cada canción y cuándo, los votos válidos con su peso y
  lo que ya sonó.
- **Qué debe deducir.** El orden de reproducción: qué entra a la cola y qué espera, qué
  criterio rompió cada empate, y si el que queda es definitivo o provisional porque aún
  se vota.
- **Qué debe contestar.** La cola ordenada con el criterio decisivo de cada posición; si
  agotados los criterios siguen empatadas, decirlo en vez de inventar un orden.
- **Por qué es lógica.** Es una política: límites y criterios declarados una vez. Dos
  partes tienen razón: quien propuso lo más votado y quien lleva tiempo esperando turno.
  Lo intuitivo es que la de más votos va primero; revisa qué pasa si todas las de arriba
  son del mismo proponente, y qué tan justo es desempatar por orden de llegada.

### Situación 5 — Cola vacía, archivo roto: ¿qué suena?

- **Qué pasa.** A media canción el archivo se corrompe. En la cola solo quedan canciones
  que no pueden sonar (una sin licencia clara, otra reportada como dañada por un solo
  oyente). Si hay silencio, los oyentes se van y la radio pierde audiencia.
- **Qué datos hay.** Los eventos de la emisión con su instante, el estado de cada archivo
  y licencia, la cola y el catálogo de respaldo.
- **Qué debe deducir.** Si la cola está realmente vacía (no es lo mismo que no tener
  canciones), si el archivo está dañado o solo falló una lectura, qué se emite en su
  lugar y qué pasa con la canción cortada y sus votos.
- **Qué debe contestar.** Qué suena ahora, qué suena después y por qué, y qué dato daría
  la certeza que falta («dañado» o «no se sabe»).
- **Por qué es lógica.** Encadena archivo dañado, no elegible, cola efectiva vacía y
  respaldo permitido, sin dejar silencio. Lo intuitivo es que, con canciones en la cola,
  la cola no está vacía; revisa si es cierto.

## Por qué no basta un script

Con `siguiente = max(cola, key=lambda c: c.votos)` resuelves una cola donde cada voto es
de una persona distinta y toda canción puede sonar. Tu gemelo debe contestar, **con las
mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué suena después de esta canción? | decisión |
| ¿Por qué no sonó la más votada? | explicación |
| ¿Qué canciones podrían sonar ahora? | todas las respuestas |
| ¿Qué tendría que pasar para que mi canción suba al primer lugar? | la pregunta al revés |
| ¿Qué pasaría si dos de esas tres cuentas son la misma persona? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir un voto en el instante en que llegó, y qué sabes
   (y qué no) de quién lo emitió?
2. ¿Qué evidencia basta para decir que dos cuentas son la misma persona, y qué hace tu
   gemelo cuando solo hay sospecha?
3. ¿Cómo distingue tu gemelo «no puede sonar» de «no sé si puede sonar»?
4. Cuando la más votada no es elegible o dos canciones empatan, ¿dónde queda escrito
   cuál criterio manda?
5. En tu simulación en Erlang, ¿cómo lograste que todos escucharan lo mismo en el mismo
   momento, y qué dato de ella (el retraso de un oyente, el fin de una canción)
   alimentaría a este gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la radio, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar ráfagas de votos
  simulados o graficar la cola.

## Supuestos de esta extensión

- Escala reducida: 10 canciones, 5 votantes y 8 oyentes, contra las 200 canciones, 80
  votantes activos y 500 oyentes del escenario original. La ráfaga de la situación 1 se
  reduce a lo que quepa en pantalla: basta con que haya muchos más votos que personas.
- El «ahora» es un hecho del modelo, en segundos desde el inicio de la emisión, no el
  reloj del sistema, para que las respuestas se puedan repetir.
- Los títulos, las cuentas y los nombres de los ejemplos son ilustrativos y del ejercicio.
- Del original solo vienen: los segmentos de 2 a 10 segundos, la ráfaga de votos desde
  tres cuentas, el voto de alguien con cinco cuentas, y la distinción entre música libre
  (Creative Commons) y música con derechos de ejecución pública.
- Defines tú, porque el original no da la cifra ni la regla: qué señales vuelven
  sospechosa a una cuenta y cuánto vale su voto, cuánto antes del fin de una canción se
  cierra la decisión, cuánto retraso de un oyente es creíble, qué licencias puede emitir
  la radio, cuántas canciones en cola puede tener un proponente, cómo se desempata y qué
  suena de respaldo.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Licencias Creative Commons con restricciones distintas (uso comercial, obra derivada).
- Una cuota de música local o de artistas independientes que compita con los votos.
- Votos que caducan: el gusto de ayer no manda hoy.

---
*Las cifras de dominio son de referencia y vienen del problema original. Verifica la
fuente vigente antes de citarlas en tu entrega.*
