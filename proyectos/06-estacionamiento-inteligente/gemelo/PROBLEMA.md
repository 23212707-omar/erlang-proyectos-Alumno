# #6 — Estacionamiento inteligente: gemelo digital con programación lógica

> Extensión del proyecto #6. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el estacionamiento: cajones como procesos, autos que
llegan, sensores que fallan. Esa simulación responde «¿qué está pasando?». El operador
y el conductor necesitan algo más: «¿a qué cajón va cada auto, y por qué a ese?».

El gemelo digital es el **modelo lógico** del estacionamiento: hechos que reflejan su
estado y reglas que reflejan cómo se asigna y en qué dato se confía. Se escribe en
Prolog porque lo que hay que resolver aquí no es contar, sino acomodar sin
contradicciones, justificar y saber decir «no lo sé».

## El estacionamiento que se clona

Un estacionamiento de centro comercial, reducido a 2 niveles, 2 zonas por nivel y 5
cajones por zona: 20 cajones y 2 rampas con barrera.

| Parte | Contenido |
|---|---|
| Entidades | nivel → zona → cajón; rampas entre niveles; accesos peatonales; conductores |
| Estado por cajón | lo que dice su sensor (libre u ocupado) y desde cuándo; si está reservado y por quién; si está fuera de servicio |
| Estado por nivel | entradas y salidas contadas en las rampas |
| Eventos | llega un auto y pide cajón, se hace o expira una reserva, un sensor cambia, un auto cruza una rampa |
| Decisiones | ¿qué cajón le toca a cada conductor?, ¿este cajón está realmente ocupado?, ¿a qué conteo le creo?, ¿la zona está saturada? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original: sus casos difíciles, su escenario y sus datos.
Las personas (la operadora, los conductores, el gerente de la plaza) las pone esta
extensión para que se vea quién pierde cuando el gemelo se equivoca. En cada una, tu
gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — Dos conductores, un solo «mejor cajón»

- **Qué pasa.** Dos autos entran casi al mismo tiempo y los dos piden el cajón más
  conveniente. En un pico pueden llegar 300 autos en 20 minutos. Si el gemelo manda a
  los dos al mismo cajón, uno llega, lo encuentra ocupado y vuelve a dar vueltas: justo
  el tiempo y el combustible perdidos que el sistema debía evitar. Lo intuitivo es dar a
  cada quien su mejor cajón, uno por uno, conforme llegan.
- **Qué datos hay.** Las solicitudes pendientes, los cajones disponibles y qué tan
  conveniente es cada cajón para cada conductor (según el acceso que busca).
- **Qué debe deducir.** Un acomodo completo en el que nadie comparte cajón, ningún cajón
  reservado, dudoso o fuera de servicio se entrega, y todos los que caben reciben lugar.
- **Qué debe contestar.** El reparto completo; quién no obtuvo su preferido y por qué;
  las demás formas válidas de repartir; y, si atender primero al que llegó primero deja
  a alguien sin lugar que sí cabía, decirlo.
- **Por qué es lógica.** No se busca el mejor cajón para uno, sino un acomodo que
  cumpla todas las condiciones a la vez. Es un problema de restricciones.

### Situación 2 — El cajón ocupado desde hace tres días

- **Qué pasa.** Un sensor reporta «ocupado» por 3 días seguidos. Los sensores tienen
  falsos positivos (motos, carritos, cambios de temperatura) y falsos negativos; en el
  escenario, el 5 % falla. Si la operadora lo da por libre y hay un auto abandonado,
  manda a un conductor a un cajón lleno; si lo da por ocupado y el sensor está pegado,
  la plaza pierde un cajón en pleno pico y nadie lo nota.
- **Qué datos hay.** El estado del sensor con la hora desde la que no cambia, los
  eventos de rampa del nivel, si hubo reserva en ese cajón y el estado de los cajones
  vecinos. Ningún dato dice «sensor descompuesto».
- **Qué debe deducir.** Si el cajón está ocupado, libre o no se sabe, cruzando lo que
  dice su sensor con lo que las otras fuentes permiten o contradicen.
- **Qué debe contestar.** Tres respuestas distintas: «ocupado», «libre» y «no lo sé»,
  con la evidencia; si el cajón se puede asignar mientras dura la duda; y qué
  observación la resolvería.
- **Por qué es lógica.** «El sensor dice ocupado» y «el cajón está ocupado» son dos
  afirmaciones diferentes, y el gemelo debe razonar sobre la distancia entre ambas.

### Situación 3 — Las rampas dicen una cosa y los cajones otra

- **Qué pasa.** Contar entradas y salidas en las rampas acumula error: si falla 1 de
  cada 200 eventos, tras un día el conteo ya no es real. El conteo por cajón tampoco
  es perfecto. El tablero de la entrada anuncia «lugares disponibles» con uno de los dos
  números: si miente hacia arriba, el nivel se llena de autos dando vueltas; si miente
  hacia abajo, los autos se van y la plaza pierde clientes. Lo intuitivo es creerle
  siempre al conteo por cajón, porque «ve» cada lugar.
- **Qué datos hay.** Eventos de rampa por nivel y el estado de los sensores de cajón,
  con los que ya quedaron en duda. Nadie mide la ocupación verdadera.
- **Qué debe deducir.** En cadena: de qué tamaño es la diferencia en cada nivel, luego
  si los cajones dudosos de ese nivel alcanzan a explicarla, luego cuál de las dos
  fuentes es la que se desvió, y por último qué número se puede publicar.
- **Qué debe contestar.** La ocupación que el gemelo sostiene por nivel, de qué fuente
  salió y por qué descartó la otra; y en qué nivel la fuente correcta es la rampa aunque
  los cajones parezcan más precisos.
- **Por qué es lógica.** La ocupación real no es un dato: es una conclusión que se
  obtiene confrontando dos fuentes que se contradicen.

### Situación 4 — El cajón reservado que alguien más ocupó

- **Qué pasa.** Una reserva aparta un cajón y expira a los 10 minutos. Antes de que
  expire, el sensor marca «ocupado»: llegó el dueño de la reserva, o se metió otro auto.
  El conductor con reserva llega y reclama su lugar; el que se metió dice que nada le
  avisó que estaba apartado. Los dos tienen razón en algo, y en la zona no sobra lugar.
- **Qué datos hay.** Las reservas con su hora de inicio y su conductor, el estado del
  sensor con su hora, los eventos de rampa del nivel y la hora actual.
- **Qué debe deducir.** Si la reserva seguía vigente cuando el cajón se ocupó; si quien
  lo ocupó pudo ser el dueño de la reserva; y qué cajón queda para el que se quede sin
  lugar.
- **Qué debe contestar.** Qué cajones quedan disponibles para otros, cuáles no y por
  qué; a quién se le falla, qué regla lo decidió y qué se le ofrece a cambio; y cuándo
  la respuesta es «no se sabe quién lo ocupó».
- **Por qué es lógica.** El mismo «ocupado» significa cosas distintas según el estado
  de la reserva, y dos reglas (respetar la reserva, creerle al sensor) chocan.

### Situación 5 — ¿Está saturada la zona?

- **Qué pasa.** Las tarifas dinámicas suben el precio cuando la ocupación pasa de
  alrededor del 85 %, para dejar libre 1 de cada 7 cajones. Pero un estacionamiento
  puede llenarse en 30 o 40 minutos, y parte de los cajones está reservada, en duda o
  fuera de servicio. Subir la tarifa con un número inflado le cobra de más a quien
  entra; no subirla a tiempo deja la zona sin un solo lugar. El gerente de la plaza
  tendrá que explicar cada cobro.
- **Qué datos hay.** El estado de cada cajón de la zona según las situaciones anteriores.
- **Qué debe deducir.** La ocupación de la zona cuando no todos los cajones tienen un
  estado claro: ¿un cajón reservado cuenta como ocupado?, ¿y uno en duda?
- **Qué debe contestar.** Si la tarifa sube y por qué; cuántos cajones faltan para
  cruzar el límite; qué pasaría si llegan diez autos más; y si la decisión cambia según
  cómo se cuenten los dudosos, decirlo en vez de escoger en silencio.
- **Por qué es lógica.** El porcentaje depende de una política sobre qué cuenta, y esa
  política debe estar declarada, no enterrada en una resta.

## Por qué no basta un script

Con `if not ocupado[cajon]: asignar(cajon)` acomodas un auto con sensores perfectos y
sin nadie más pidiendo lugar. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿A qué cajón mando a este conductor? | decisión |
| ¿Por qué a ese y no al de al lado? | explicación |
| ¿De cuántas formas puedo acomodar a los tres autos que esperan? | todas las respuestas |
| ¿Qué tendría que pasar para que el cajón 12 se pueda asignar? | la pregunta al revés |
| ¿Qué pasa si llegan diez autos más a la zona A? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir un cajón en un instante?
2. ¿Qué significa «más conveniente», y dónde queda escrito?
3. ¿Quién es la fuente de verdad, las rampas o los cajones, y cuándo cambia la respuesta?
4. ¿Cómo distingue tu gemelo «el cajón está libre» de «no sé si está libre»?
5. En Erlang cada cajón es un proceso con estados. ¿Qué de eso podría alimentar a este
   gemelo, y qué decide el gemelo que el proceso no puede?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del estacionamiento, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la
  asignación con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar llegadas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 2 niveles, 20 cajones y 2 rampas, contra los 3 niveles, 600 cajones
  y 6 rampas del escenario original.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir.
- Tú defines qué es «más conveniente», cuánto tiempo ocupado vuelve sospechoso a un
  sensor y qué estados cuentan para la ocupación. Decláralo como supuesto.
- La operadora, los conductores y el gerente de la plaza son personas del ejercicio, no
  del problema original. Tú decides a quién se le falla en la reserva invadida y qué se
  le ofrece; decláralo.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Cajones con uso restringido (accesibilidad, carga eléctrica, motocicletas).
- Guiar por la ruta más corta dentro del estacionamiento, no solo al cajón más cercano.
- Cierre de una rampa o de un nivel: a dónde se desvían los autos que ya iban en camino.
- Auditoría de cobros: demostrar por qué se aplicó cada tarifa.

---
*Las cifras son de referencia y vienen del problema original. Verifica la fuente vigente
antes de citarlas en tu entrega.*
