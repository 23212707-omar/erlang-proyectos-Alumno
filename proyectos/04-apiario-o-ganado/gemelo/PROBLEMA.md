# #4 — Apiario o ganado: gemelo digital con programación lógica

> Extensión del proyecto #4. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste los dispositivos: un proceso por colmena y un detector
de «dejó de reportar». Esa simulación responde «¿quién calló?». El apicultor necesita
algo más: «¿qué le pasó a esa colmena, qué hago, y por qué?». Callar puede ser falta de
cobertura, batería agotada o robo, y cada causa pide una acción distinta.

El gemelo digital es el **modelo lógico** del apiario: hechos que reflejan su estado y
reglas que reflejan cómo se decide en él. Se escribe en Prolog porque lo que hay que
resolver aquí no es calcular, sino deducir, justificar y descartar.

## El apiario que se clona

Un dueño con 3 apiarios de 3 colmenas (el original da a elegir apiario o ganado; aquí
se toma el apiario).

| Parte | Contenido |
|---|---|
| Entidades | dueño → apiario → colmena; un enlace de radio por apiario; un técnico |
| Estado por colmena | peso (kg), temperatura de la cría (°C), movimiento (acelerómetro), batería, dentro o fuera del cerco |
| Estado por apiario | qué colmenas reportaron y cuándo; si hay una orden de traslado vigente |
| Eventos | llega una lectura (con hora de dispositivo y hora de llegada), una colmena calla, llega una ráfaga al volver la cobertura, el dueño anota visita, cosecha o traslado, se envía o retira un aviso |
| Decisiones | ¿qué le pasó a esta colmena?, ¿se avisa ya, se resume o se espera?, ¿se cree esta lectura?, ¿a qué apiario va el técnico? |

## Situaciones que tu gemelo debe razonar

Las situaciones 1 a 4 salen del problema original (su escenario, sus datos del mundo
real, sus casos difíciles y su pregunta guía 1). La 5 plantea algo nuevo: un solo técnico
para dos urgencias, a partir de la pregunta guía 2 del original. En cada una, tu gemelo
debe llegar a una decisión **y poder explicarla**.

### Situación 1 — La colmena 5 dejó de reportar

- **Qué pasa.** Por la mañana, la colmena 5 del apiario Norte lleva horas sin reportar,
  igual que la 4 y la 6 de ese apiario. En el Sur, la 7 calla mientras sus vecinas 8 y 9
  siguen reportando. El dueño no quiere avisos de un robo que no existe, ni enterarse
  tarde de uno que sí.
- **Qué datos hay.** Hora de la última lectura de cada colmena, la batería que decía,
  quién más reportó en el mismo apiario y cuándo, y el «ahora». Ningún dato dice
  «perdida».
- **Qué debe deducir.** Por colmena callada: si lo más probable es falta de cobertura,
  dispositivo agotado o colmena perdida, o si aún no se puede saber. Lo «obvio» (la que
  calla es la que falla) está mal para las del Norte.
- **Qué debe contestar.** Un estado por colmena con razones, y qué dato cambiaría la
  conclusión si llegara.
- **Por qué es lógica.** Callar solo significa algo frente a lo que hacen las demás;
  «sin dato» no es «sin colmena».

### Situación 2 — La ráfaga que cambia el pasado

- **Qué pasa.** A las 3 de la madrugada el gemelo avisó que la colmena 2 llevaba horas
  muda. A media mañana vuelve la cobertura y llegan de golpe las lecturas guardadas,
  algunas fuera de orden y cada una con la hora de su dispositivo. Muestran que la 2
  estuvo bien toda la noche, y una de ellas trae una hora que aún no ha ocurrido.
- **Qué datos hay.** De cada lectura, su hora de dispositivo y de llegada; los avisos
  enviados y cuándo; el «ahora».
- **Qué debe deducir.** El estado de la colmena ordenado por la hora del dispositivo y no
  por la de llegada; qué lecturas son imposibles; y si el aviso de las 3 estaba
  justificado con lo que se sabía entonces y lo estaría con lo que se sabe ahora.
- **Qué debe contestar.** Estado actual, aviso confirmado o retirado, las dos versiones
  («entonces» y «ahora») con su evidencia, y las lecturas descartadas con su motivo.
- **Por qué es lógica.** Mismos hechos, dos momentos, conclusiones distintas sin
  contradicción: rendición de cuentas.

### Situación 3 — Se movió de madrugada

- **Qué pasa.** A las 4, tres colmenas del Sur (7, 8 y 9) salen de su cerco y el
  acelerómetro marca movimiento. El robo de colmenas es un delito común en zonas rurales.
  Pero el día anterior el dueño registró una orden de traslado, con su ventana de horas,
  que nombra a la 7 y la 9. La 9 salió antes de que empezara esa ventana.
- **Qué datos hay.** Posición respecto del cerco y movimiento, con su hora de
  dispositivo y de llegada (todo llegó tarde, en ráfaga); la orden con su ventana.
- **Qué debe deducir.** Qué salidas explica una orden vigente, cuáles no, y cuáles
  quedan en el punto intermedio donde la orden existe pero no coincide con lo ocurrido.
- **Qué debe contestar.** Por colmena: traslado autorizado, posible robo o «no se sabe»,
  con la razón y qué dato falta (¿se capturó mal la ventana?).
- **Por qué es lógica.** Lo que dice el sistema (la orden) y lo que pasa (el sensor)
  pueden no coincidir. Salir del cerco significa cosas distintas según lo autorizado.

### Situación 4 — Pesa menos, ¿y eso qué es?

- **Qué pasa.** En plena entrada de néctar, cuando una colmena puede ganar de 1 a 5 kg
  por día, el peso de la colmena 3 cae. Según el original, un peso que cae sin causa
  indica enjambrazón, robo o saqueo. Pero hay explicaciones inocentes: el dueño cosechó,
  o la báscula tiene batería baja y miente.
- **Qué datos hay.** Serie de peso, temperatura de la cría (sana ronda 34-35 °C),
  movimiento, batería de la báscula, bitácora de visitas y cosechas, y lo que hicieron
  las demás colmenas del apiario ese día.
- **Qué debe deducir.** Qué explicaciones siguen vivas y cuáles se descartan. La causa
  nunca se mide: se deduce combinando señales, y cada explicación deja huellas distintas
  en los demás sensores. Averiguar cuáles es parte de tu trabajo.
- **Qué debe contestar.** La explicación que sobrevive y las descartadas con su motivo;
  si el peso no es creíble, «no lo sé», nunca una alerta por un dato corrupto.
- **Por qué es lógica.** Es encadenar descartes (lectura creíble, el resto del apiario
  no cayó, sin movimiento, la cría cambió después) hasta que queda una causa.

### Situación 5 — Dos urgencias y un solo técnico

- **Qué pasa.** Esa tarde hay dos avisos graves. En el Sur, la colmena 8 sigue sin
  explicación tras salir de su cerco. En el Norte, la temperatura de cría de la 2 lleva
  horas por debajo de lo sano: según el original, una caída sostenida indica pérdida de
  la reina o colonia débil. El técnico solo llega a un apiario hoy. Hay además avisos
  menores (baterías bajas, silencios aislados) que el dueño no quiere uno por uno.
- **Qué datos hay.** Los avisos vigentes con su tipo y evidencia, el apiario de cada uno,
  dónde está el técnico y el «ahora».
- **Qué debe deducir.** Cuáles avisos son urgentes y cuáles se resumen, a qué apiario
  va el técnico y qué queda sin atender.
- **Qué debe contestar.** El orden de atención, la alerta diferida con su razón, el costo
  declarado de esa decisión y qué tendría que pasar para que el orden cambiara.
- **Por qué es lógica.** Ambas partes tienen razón: atender el robo puede costar la
  colonia y viceversa. La prioridad se declara una vez y justifica a quién se le falla.

## Por qué no basta un script

Con `if ahora - ultima_lectura > LIMITE: alerta("colmena perdida")` detectas un silencio
sin contexto. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué hago con la colmena 5? | decisión |
| ¿Por qué? | explicación |
| ¿Qué colmenas están hoy en riesgo de pérdida? | todas las respuestas |
| ¿Qué tendría que llegar para creer que la 5 solo estaba sin cobertura? | la pregunta al revés |
| ¿Qué pasaría si el Norte pierde el enlace toda la noche? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio: es el programa.

## Preguntas guía

1. ¿Cómo representas una colmena «perdida» frente a una solo «sin cobertura»? (Es la
   pregunta guía 1 del problema original.)
2. ¿Qué dos horas guardas de cada lectura, y qué consulta se vuelve imposible sin ellas?
3. ¿Cómo distingue tu gemelo «no hay robo» de «no sé si hay robo»?
4. Cuando dos avisos se disputan al técnico, ¿dónde queda escrito cuál gana y a quién se
   le explica?
5. ¿Qué parte de tu simulación en Erlang (el proceso por dispositivo, el detector de
   silencio con timers) podría alimentar a este gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del apiario, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar lecturas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 3 apiarios y 9 colmenas, contra los 6 apiarios y 60 colmenas del
  original. Cada apiario comparte un enlace de radio y cada colmena reporta lecturas y
  posición respecto del cerco; el original menciona báscula, sensores, acelerómetro y
  cerco virtual, pero no esa organización.
- Órdenes de traslado, bitácora de visitas y cosechas y técnico único: datos de esta
  extensión, no del original.
- El «ahora» es un hecho del modelo, en minutos, no el reloj del sistema, para que las
  respuestas se puedan repetir. La situación 2 pide consultar con dos «ahora» distintos.
- Tú defines, con fuente cuando sea posible: cuánto silencio es sospechoso, qué es una
  caída «sostenida», qué batería es baja, qué huella deja cada explicación del peso y el
  criterio de prioridad de la situación 5. Ninguno viene del original.

## Extensiones posibles

Para quien quiera ir más lejos. No vienen del problema original: investiga y cita tus
fuentes antes de fijar cifras.

- El escenario de ganado: celo y fiebre por temperatura y actividad de un collar.
- La ruta del técnico: en qué orden visita los apiarios para cambiar baterías.
- Una denuncia por robo: reconstruir qué sabía el gemelo, y cuándo, como evidencia.

---
*Las cifras (34-35 °C, 1-5 kg por día, 60 colmenas en 6 apiarios) son de referencia y
vienen del problema original; lo demás es escala del ejercicio, no estadística. Verifica
la fuente vigente antes de citarlas en tu entrega.*
