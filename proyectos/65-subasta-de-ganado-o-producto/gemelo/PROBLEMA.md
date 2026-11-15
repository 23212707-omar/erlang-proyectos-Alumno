# #65 — Subasta de ganado o productos: gemelo digital con programación lógica

> Extensión del proyecto #65. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang un proceso por lote pasaba de abierto a última llamada y a
adjudicado, y un reloj de cierre se reiniciaba con cada puja. Esa simulación responde
«¿se aplicó la regla de tiempo siempre igual?». Quien conduce la subasta necesita algo
más: «¿esta puja obliga a su postor, se vende el lote o no, y se lo puedo demostrar a
quien perdió?».

El gemelo digital es el **modelo lógico** de la subasta: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque lo difícil aquí no
es ser rápido, sino que cada puja y cada martillazo tengan una sola respuesta y una
explicación que aguante la queja de un ganadero.

## La subasta ganadera que se clona

Una subasta en vivo de becerros en el noroeste, con postores en la sala y otros conectados
desde su rancho, reducida a unos pocos lotes. Los lotes, los vendedores y las personas
son ejemplos ilustrativos del ejercicio.

| Parte | Contenido |
|---|---|
| Entidades | lotes de becerros con vendedor; animales con arete SINIIGA; postores en sala o remotos; un martillero; la báscula; los documentos de cada animal |
| Estado por lote | etapa (abierto, última llamada, adjudicado, retirado o sin venta), pujas recibidas, escalón vigente, llamadas del martillero, reserva del vendedor, peso declarado y peso en báscula |
| Estado por postor | modalidad (sala o remoto), retraso de su conexión, si está conectado, las pujas que ha hecho |
| Eventos | llega una puja; el martillero hace una llamada; cae o vuelve una conexión; el vendedor cambia su reserva u ordena retirar el lote; se pesa el lote; se reinicia el sistema |
| Decisiones | ¿vale esta puja?, ¿quién lleva el lote?, ¿lo obliga su puja?, ¿se adjudica, se retira o pasa sin venta?, ¿puede salir el lote del corral? |

## Situaciones que tu gemelo debe razonar

Cuatro salen del problema original (casos difíciles, escenario y datos del mundo real). La
tercera es derivada: usa el peso en báscula del original y el foco del proyecto, la
reserva y los empates. En cada una, tu gemelo debe decidir **y poder explicarlo**.

### Situación 1 — La mano levantada y el martillazo

- **Qué pasa.** En el lote 4 el martillero llega a «a las tres». En ese instante un postor
  en sala levanta la mano por el escalón vigente y llega la puja de un remoto cuya pantalla
  va atrasada: pujó por el escalón anterior. Otro remoto manda la suya 2 segundos después
  de adjudicado. Tres personas creen haber ganado; la sala y los remotos tienen razón a la
  vez, porque ven el precio con retrasos distintos.
- **Qué datos hay.** Cada puja con monto por kilo, instante de llegada, instante de
  emisión según el cliente (solo en remotas, y su reloj no es confiable), número de
  bitácora, el retraso de cada remoto, el escalón vigente y las llamadas.
- **Qué debe deducir.** En qué etapa estaba el lote cuando llegó cada puja, en qué orden se
  consideran las que empatan, cuáles valen a esa etapa y a ese escalón, y quién gana.
- **Qué debe contestar.** Ganador y precio, qué desempate lo decidió, a quién se le falló y
  por qué, y qué tendría que ser distinto (el retraso, el orden) para que ganara otro.
- **Por qué es lógica.** La autoridad del orden se declara una vez y sirve para decidir,
  para justificar ante el que perdió y para contestar «¿y si el retraso fuera otro?».

### Situación 2 — El postor que se quedó sin señal

- **Qué pasa.** Un remoto lleva la puja ganadora cuando su conexión cae. No se sabe si la
  puja entró antes de la caída ni si el martillero la vio. El segundo postor, en sala,
  pide el lote porque «el otro ya no estaba»; el remoto, al volver, jura que pujó. Aceptar
  una puja es un compromiso de compra: si lo obligan, paga miles de pesos por animales que
  quizá no quiso; si no, el vendedor pierde su mejor oferta y el lote vuelve a empezar.
- **Qué datos hay.** La bitácora con el recibo de cada puja, los eventos de conexión
  perdida y recuperada, el retraso medido y las confirmaciones (no siempre se sabe si
  llegaron).
- **Qué debe deducir.** En cadena: si la puja llegó antes de que se diera por caída la
  conexión; si por eso fue aceptada; si, aceptada, es un compromiso; si éste lo hace
  ganador al agotarse el reloj; y a quién pasa el lote si no.
- **Qué debe contestar.** «Lo obliga», «no lo obliga» o «no se sabe», con su consecuencia
  para el lote y la evidencia que decidiría entre ellas.
- **Por qué es lógica.** «No pujó» y «no sé si pujó» no son lo mismo, y cada paso se apoya
  en el anterior sin escribir un caso por postor.

### Situación 3 — Ganó la puja más alta y el lote no se vendió

- **Qué pasa.** Antes de abrir, la vendedora registró una reserva para el lote 2: el total
  mínimo en pesos que aceptará, que ningún postor conoce. Se puja por kilo, pero el total
  solo existe cuando la báscula pesa el lote. Lo intuitivo es «la puja más alta ganó, lote
  vendido»; es sospechoso porque ni el precio por kilo ni el peso declarado definen lo que
  se paga. Las lecturas de báscula no coinciden y en pleno remate la vendedora bajó su
  reserva. Vender por debajo de lo que aceptaba le cuesta a ella; anular una venta válida
  le cuesta al postor.
- **Qué datos hay.** Reserva con su instante de vigencia, pujas, peso declarado, lecturas de
  báscula con su instante y el rango plausible de un peso.
- **Qué debe deducir.** Qué lectura vale, el total a cada precio, si la reserva vigente al
  martillazo se cumple, no se cumple o no se sabe, y qué pasa con el lote. Un total igual a
  la reserva es frontera.
- **Qué debe contestar.** Si se adjudica, pasa sin venta o espera un peso confiable; qué
  precio por kilo habría bastado; una explicación completa para la auditoría y otra para el
  público, que no revele la reserva.
- **Por qué es lógica.** La reserva se mide contra algo que se deduce de varios datos, y
  «no la cumple» y «no sé si la cumple» llevan a decisiones distintas.

### Situación 4 — El lote retirado con una puja en pie

- **Qué pasa.** En el lote 5 el vendedor ordena retirarlo cuando ya hay un líder y el
  martillero dijo «a las dos». El líder sostiene que su puja es un compromiso de compra; el
  vendedor, que el lote es suyo hasta que se adjudica. Ambos tienen razón en algo. Además
  el sistema se reinició: la orden quedó en la bitácora, pero hay un hueco y no se sabe si
  fue antes o después de «a las tres».
- **Qué datos hay.** La orden de retiro (si consta quién y cuándo), las pujas, las
  llamadas y la bitácora con su hueco y el reinicio.
- **Qué debe deducir.** En cada historia compatible con la bitácora, en qué etapa quedó el
  lote, qué secuencias de etapas son posibles y cuáles no, y qué pasa con las pujas y con
  el orden de los lotes que faltan.
- **Qué debe contestar.** La etapa final en cada historia, a quién favorece y a quién le
  falla, y qué registro decidiría. Si solo cabe una historia, la decisión y su razón.
- **Por qué es lógica.** Se pregunta qué secuencias son posibles, no qué número es mayor;
  con un hueco hay que razonar historias, no suponer una.

### Situación 5 — El lote que no puede salir del corral

- **Qué pasa.** Un lote de becerros fue adjudicado y el comprador debe moverlo esa tarde.
  Cada animal exige arete SINIIGA, el lote certificados sanitarios y moverlos pide guía de
  tránsito. Un arete es ilegible, un certificado cubre a otro lote y otro no deja claro
  hasta cuándo vale. Si el camión sale mal documentado puede ser detenido en un retén; si
  no sale, el comprador pierde la tarde.
- **Qué datos hay.** Los animales del lote y los documentos de cada arete, con emisor y
  vigencia (a veces desconocida).
- **Qué debe deducir.** En cadena: qué animales están identificados, cuáles cubre un
  certificado vigente, si el lote cumple completo, si puede emitirse la guía y de ahí si el
  camión sale.
- **Qué debe contestar.** Qué puede hacerse hoy con el lote, qué no y qué falta, animal por
  animal. Si la vigencia no se lee, «no se sabe», nunca «sí» por omisión.
- **Por qué es lógica.** «Falta un papel» no es «falta todo»: la conclusión sobre el lote
  sale de lo que se sabe de cada animal.

## Por qué no basta un script

Con `if puja > precio_actual: aceptar()` resuelves una puja a la vez, sin empates, sin
reserva, sin conexiones caídas ni lotes retirados. Tu gemelo debe contestar, **con las
mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué hago con la puja del remoto en el martillazo del lote 4? | decisión |
| ¿Por qué se adjudicó el lote 4 a quien lo ganó y no al otro? | explicación |
| ¿Qué lotes no pueden salir hoy del corral? | todas las respuestas |
| ¿Qué precio por kilo habría cumplido la reserva del lote 2? | la pregunta al revés |
| ¿Qué pasaría si el retraso de ese remoto fuera el mayor posible? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Quién tiene la autoridad del orden de las pujas y dónde queda escrito el desempate?
2. ¿Qué hace tu gemelo con una puja recibida de un postor que se desconectó y cómo la
   distingue de «no pujó»?
3. ¿Cómo distingue tu gemelo «no cumple la reserva» de «no sé si la cumple»?
4. ¿Qué parte de la explicación puede ver el público y cuál solo el vendedor o el auditor?
5. En Erlang un proceso por lote cambiaba de etapa y un reloj lo cerraba. ¿Qué de eso
   podría alimentar a este gemelo, y qué decide el gemelo que un proceso no puede explicar?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la subasta, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar pujas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: unos 6 lotes, 8 postores (5 en sala y 3 remotos) y 1 martillero,
  contra los 150 lotes, 80 postores (60 en sala y 20 remotos) del escenario original.
- Son ejemplos del ejercicio, no hechos del mundo: los lotes, las personas y las
  cantidades que aparecen en ellos.
- El «ahora» es un hecho del modelo, en milisegundos, no el reloj del sistema, para que
  las respuestas se puedan repetir.
- Por decisión del ejercicio, la reserva se registra como total en pesos, no por kilo.
- Tú defines y declaras como supuesto: el tamaño del escalón; cómo lees la frontera
  («mayor» o «mayor o igual»); el desempate; cuánto retraso admites a un remoto y si
  cuenta su instante de emisión; cuánto silencio da por caída una conexión; qué lectura de
  báscula vale; en qué etapas se puede retirar un lote; y qué documentos pide cada paso y
  cuánto dura su vigencia. El original no da esas reglas ni esas cifras.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Venta de varios lotes juntos o por cabeza en lugar de por kilo en pie.
- Postores que pujan contra sí mismos o se ponen de acuerdo para bajar el precio.
- Crédito o depósito del postor y qué pasa si no paga lo que se comprometió.
- Merma del animal entre el corral y la báscula, y quién la absorbe.

---
*Las cifras (100-300 lotes por subasta, 1-3 minutos por lote, retraso de 1-3 segundos de un
remoto, ~200 kg por becerro, puja remota 2 segundos después de la adjudicación, 150 lotes,
80 postores de los que 60 están en sala y 20 son remotos, 1 martillero) son de referencia y
vienen del problema original. Verifica la fuente vigente antes de citarlas en tu entrega.*
