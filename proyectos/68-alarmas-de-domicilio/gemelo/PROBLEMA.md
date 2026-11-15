# #68 — Alarmas de domicilio: gemelo digital con programación lógica

> Extensión del proyecto #68. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la central: un proceso por panel, un clasificador de
eventos y una máquina de estados por alarma que verifica y escala. Esa simulación
responde «¿qué eventos llegan y en qué estado está cada alarma?». El operador necesita
algo más, y en segundos: «¿esto es un robo, una falsa alarma o una falla técnica, qué
sigue, y por qué?». Se estima que entre 90 % y 98 % de las activaciones que se reportan
a la policía resultan falsas: cada decisión cuesta una patrulla de más o un robo sin atender.

El gemelo digital es el **modelo lógico** de la central: hechos que reflejan lo que han
reportado los paneles y reglas que reflejan cómo se decide con eso. Se escribe en Prolog
porque lo que hay que resolver aquí no es calcular, sino deducir, justificar y descartar.

## La central que se clona

Una central de monitoreo, reducida a 12 paneles de domicilio, 3 circuitos eléctricos y
3 operadores.

| Parte | Contenido |
|---|---|
| Entidades | central → cliente → panel → zona; operadores; el circuito eléctrico del que cuelga cada panel |
| Estado por panel | modo (desarmado, armado en casa, armado en ausencia), canal de reporte (línea telefónica, internet o celular), retardo de entrada configurado, último latido |
| Estado por zona | tipo (entrada, perímetro, movimiento, interior) y qué otras zonas cubren el mismo espacio |
| Estado por cliente | su protocolo (a quién llamar, en qué orden, cuánto esperar), su palabra clave y su palabra de coacción |
| Estado de la central | qué operador atiende qué alarma y cuáles esperan a alguien |
| Eventos | zona activada, desarme, latido, corte de energía, falla de batería, corte de comunicación, resultado de una llamada de verificación, despacho, cancelación |
| Decisiones | ¿robo, falsa alarma o señal técnica?, ¿siguiente paso del protocolo?, ¿escalar?, ¿a quién le toca?, ¿confiar en este dato? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original (sus casos difíciles, su escenario o sus datos del
mundo real); cada una añade un complemento sin cifras que se señala. En cada una, tu
gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — Dos zonas, una sola causa

- **Qué pasa.** Un panel armado en ausencia activa dos zonas en pocos minutos. La
  verificación cruzada pide dos zonas distintas, y eso suena a robo. Pero el original
  advierte del caso donde las dos las dispara la misma causa: la mascota que cruza la
  sala, una ventana abierta con viento. Si el gemelo se equivoca, un cliente recibe una
  patrulla y una multa de más, o una casa vacía recibe a un ladrón sin que nadie vaya.
- **Qué datos hay.** Las dos activaciones con su instante, el tipo de cada zona, qué
  zonas cubren el mismo espacio, el modo del panel y su historial de eventos. Ningún
  sensor mide «dos pruebas independientes».
- **Qué debe deducir.** Si hay dos pruebas o una sola causa contada dos veces, y por lo
  tanto si hay verificación cruzada.
- **Qué debe contestar.** Robo probable, sospecha o falsa alarma probable; el siguiente
  paso del protocolo; y qué evidencia nueva subiría la alarma a despacho.
- **Por qué es lógica.** Lo obvio («dos zonas, despacho») es lo sospechoso: la
  independencia se deduce de cómo se relacionan las zonas, no de contarlas.

### Situación 2 — El desarme que no llegó

- **Qué pasa.** El dueño entra y activa la zona de entrada; el panel le da un retardo
  de entrada, de 30 a 60 s, para desarmar antes de que suene. Pero el panel reporta por
  internet o celular y el desarme puede llegar tarde, fuera de orden o nunca. La central
  ve una zona de entrada y ningún desarme. Un intruso tampoco desarma. Cada falsa alarma
  repetida puede costarle una multa al cliente.
- **Qué datos hay.** Cada evento con el instante en que ocurrió en el panel y el
  instante en que llegó a la central, el retardo del panel, su modo, su canal y si
  después hubo otras zonas.
- **Qué debe deducir.** Dónde estaba el panel dentro de su retardo al ocurrir cada
  evento (por el instante del panel, no por el de llegada), y si el desarme faltante
  significa «no ocurrió» o «aún no lo sé».
- **Qué debe contestar.** Entrada normal, entrada sin desarme o «no se sabe todavía», y
  qué hecho tendría que llegar para decidir.
- **Por qué es lógica.** La misma señal significa algo distinto según el modo y el
  momento, y «no llegó» no equivale a «no pasó».

### Situación 3 — Cancelar cuando ya se despachó

- **Qué pasa.** La patrulla ya salió. Llama alguien y dice la palabra clave para
  cancelar: «fue un error». Pero el protocolo del cliente también tiene una palabra de
  coacción, para avisar sin que el agresor lo note, y quien llama puede dar una u otra,
  una incorrecta, o ser alguien que no figura entre los contactos. La policía está
  cansada de falsas alarmas; el cliente puede estar bajo amenaza.
- **Qué datos hay.** El protocolo del cliente, la bitácora con el instante del despacho,
  el resultado de la llamada de verificación y cualquier evento del panel posterior.
- **Qué debe deducir.** Si la cancelación es válida y a qué estados puede pasar la
  alarma desde «despachada» y a cuáles no.
- **Qué debe contestar.** La decisión (seguir, desviar, cancelar), la secuencia de
  estados que recorrió la alarma y por qué la otra opción quedó descartada. Ambas partes
  tienen razón; la regla debe decidir y justificar a quién se le falla.
- **Por qué es lógica.** Son secuencias válidas con distinto conocimiento en cada paso,
  y una palabra correcta puede no ser suficiente.

### Situación 4 — La tormenta: cortes de luz y una casa distinta

- **Qué pasa.** Una ola de tormenta causa cientos de cortes de energía en 20 min, con
  solo 3 operadores. Casi todo es la tormenta, pero una casa perdió la luz mientras sus
  vecinos de circuito siguen con ella: es el corte que no se explica. Además, una alarma
  crítica lleva más de la cuenta sin que ningún operador la tome.
- **Qué datos hay.** Los cortes con su instante, el circuito y el canal de cada panel,
  quiénes siguen reportando, qué atiende cada operador y desde cuándo espera cada alarma.
- **Qué debe deducir.** Qué cortes se explican por una causa común, cuál es aislado y
  cuáles son dudosos (un vecino callado puede no tener luz o solo no tener internet), y
  a quién escalar la alarma sin atender.
- **Qué debe contestar.** Qué merece primero la atención de una persona, con la razón; qué cortes se
  agrupan como una sola avería; y a quién pasa la alarma crítica y qué se deja esperando.
- **Por qué es lógica.** Aquí lo normal es lo menos interesante: lo sospechoso se
  deduce de la vecindad eléctrica, y los operadores son un recurso que no alcanza.

### Situación 5 — El panel que lleva 26 horas callado

- **Qué pasa.** Un panel debe mandar su latido al menos cada 24 h y lleva 26 sin
  hacerlo. Puede ser sabotaje, pero también una batería agotada tras un corte, un router
  apagado o la tormenta. Enviar una patrulla a una casa vacía cuesta; no enviarla puede
  dejar un robo en curso.
- **Qué datos hay.** El último latido, los eventos previos al silencio (corte de
  energía, batería baja, corte de comunicación) con su instante, el canal del panel y
  cómo están sus vecinos de circuito. Nada mide «sabotaje».
- **Qué debe deducir.** Qué causas explican el silencio y cuáles quedan descartadas por
  los eventos previos; cuándo la conclusión es «no se sabe».
- **Qué debe contestar.** Las causas posibles con su evidencia, el siguiente paso
  (llamar, esperar, enviar visita) y qué evidencia cambiaría la conclusión.
- **Por qué es lógica.** Es una cadena: un corte explica una batería baja, que explica
  un silencio. El silencio solo acusa de sabotaje cuando nada más lo explica.

## Por qué no basta un script

Con `if zonas_activas >= 2: despachar()` resuelves la casa del manual. Tu gemelo debe
contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué hago con el panel 7? | decisión |
| ¿Por qué no se despachó? | explicación |
| ¿Qué paneles están hoy en sospecha? | todas las respuestas |
| ¿Qué tendría que llegar para despachar al panel 7? | la pregunta al revés |
| ¿Y si el desarme del panel 7 hubiera llegado antes de vencer el retardo? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué evidencia eleva una alarma de «sospecha» a «despacho», y qué la deja en sospecha?
2. ¿Cómo distingue tu gemelo «el desarme no ocurrió» de «el desarme no ha llegado»?
3. Cuando la cancelación y la coacción chocan, ¿dónde queda escrito a quién se le falla?
4. ¿Qué parte de la explicación le sirve al operador, que tiene segundos, y cuál al
   cliente que impugna una multa?
5. En tu simulación en Erlang, un panel que deja de latir genera una alarma de falla de
   comunicación: ¿qué hechos de esa simulación alimentarían a este gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la central, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar eventos simulados o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 12 paneles, 3 circuitos y 3 operadores (los operadores son los del
  original), contra los 5,000 paneles y 800 eventos por hora del escenario original.
  La tormenta se reduce a cortes casi simultáneos en dos de los tres circuitos.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir. La unidad es el segundo; el retardo de cada panel va de 30 a 60 s.
- Los tipos de zona, los circuitos, los identificadores («panel 7») y quién cuelga de
  qué circuito son del ejercicio, no estadísticas.
- Los define el estudiante, porque el original no los da: cuántos minutos son «pocos»
  para la verificación cruzada, cuánto espera cada paso del protocolo, cuánta espera
  vuelve «a destiempo» una alarma crítica, qué orden de atención se da, qué cuenta como
  mismo circuito o espacio, y qué silencio, además de las 24 h, vuelve sospechoso a un panel.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Multas por falsas alarmas repetidas y qué cliente merece una visita técnica.
- Verificación con video o audio, y qué hacer cuando se contradice con la zona.
- Falla de la propia central: qué se sigue atendiendo y quién avisa a quién.
- Relevo de turno de operadores con alarmas a medias.

---
*Las cifras (90 % a 98 %, 30 a 60 s, 24 h, 26 h, 5,000 paneles, 800 eventos por hora,
3 operadores, 400 eventos en 20 min) son de referencia y vienen del problema original.
Verifica la fuente vigente antes de citarlas en tu entrega.*
