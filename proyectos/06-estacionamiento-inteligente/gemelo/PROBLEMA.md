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

Las cinco salen del problema original. En cada una, tu gemelo debe llegar a una decisión
**y poder explicarla**.

### Situación 1 — Dos conductores, un solo «mejor cajón»

- **Qué pasa.** Dos autos entran casi al mismo tiempo y los dos piden el cajón más
  conveniente. En un pico pueden llegar 300 autos en 20 minutos.
- **Qué datos hay.** Las solicitudes pendientes, los cajones disponibles y qué tan
  lejos queda cada cajón del acceso al que va cada conductor.
- **Qué debe deducir.** Un reparto en el que cada conductor recibe un cajón, ningún
  cajón se repite y nadie es enviado a uno reservado, dudoso o fuera de servicio.
- **Qué debe contestar.** La asignación completa; por qué cada quien recibió ese cajón
  y no el que quería; y, si hay varios repartos válidos, cuáles son.
- **Por qué es lógica.** No se busca el mejor cajón para uno, sino un acomodo que
  cumpla todas las condiciones a la vez. Es un problema de restricciones.

### Situación 2 — El cajón ocupado desde hace tres días

- **Qué pasa.** Un sensor reporta «ocupado» por 3 días seguidos. Los sensores tienen
  falsos positivos (motos, carritos, cambios de temperatura) y falsos negativos; en el
  escenario, el 5 % falla.
- **Qué datos hay.** El estado que reporta cada sensor y desde cuándo. Ningún dato dice
  «este sensor está descompuesto».
- **Qué debe deducir.** Si ese cajón está ocupado, libre o en duda.
- **Qué debe contestar.** Tres respuestas distintas: «ocupado», «libre» y «no lo sé»,
  con la evidencia. Un cajón en duda no se asigna ni se cuenta como libre.
- **Por qué es lógica.** «El sensor dice ocupado» y «el cajón está ocupado» son dos
  afirmaciones diferentes, y el gemelo debe razonar sobre la distancia entre ambas.

### Situación 3 — Las rampas dicen una cosa y los cajones otra

- **Qué pasa.** Contar entradas y salidas en las rampas acumula error: si falla 1 de
  cada 200 eventos, tras un día el conteo ya no es real. El conteo por cajón tampoco
  es perfecto.
- **Qué datos hay.** Eventos de rampa por nivel y el estado de los sensores de cajón.
  Nadie mide la ocupación verdadera.
- **Qué debe deducir.** En qué niveles los dos conteos coinciden, en cuáles no, de qué
  tamaño es la diferencia y qué cajones dudosos podrían explicarla.
- **Qué debe contestar.** La ocupación que el gemelo sostiene por nivel, de qué fuente
  salió y por qué descartó la otra.
- **Por qué es lógica.** La ocupación real no es un dato: es una conclusión que se
  obtiene confrontando dos fuentes que se contradicen.

### Situación 4 — El cajón reservado que alguien más ocupó

- **Qué pasa.** Una reserva aparta un cajón y expira a los 10 minutos. Mientras tanto,
  el sensor de ese cajón puede marcar «ocupado»: llegó el dueño de la reserva, o se
  metió otro auto.
- **Qué datos hay.** Las reservas con su hora de inicio, el estado del sensor y la hora
  actual.
- **Qué debe deducir.** Si la reserva sigue vigente, si ya expiró, y qué significa un
  cajón reservado que aparece ocupado.
- **Qué debe contestar.** Qué cajones quedan disponibles para otros, cuáles no y por
  qué; y qué hacer con el conductor cuya reserva fue invadida.
- **Por qué es lógica.** El mismo «ocupado» significa cosas distintas según el estado
  de la reserva, y dos reglas (respetar la reserva, creerle al sensor) chocan.

### Situación 5 — ¿Está saturada la zona?

- **Qué pasa.** Las tarifas dinámicas suben el precio cuando la ocupación pasa de
  alrededor del 85 %, para dejar libre 1 de cada 7 cajones. Pero un estacionamiento
  puede llenarse en 30 o 40 minutos, y parte de los cajones está reservada, en duda o
  fuera de servicio.
- **Qué datos hay.** El estado de cada cajón de la zona según las situaciones anteriores.
- **Qué debe deducir.** La ocupación de la zona cuando no todos los cajones tienen un
  estado claro: ¿un cajón reservado cuenta como ocupado?, ¿y uno en duda?
- **Qué debe contestar.** Si la tarifa sube y por qué; cuántos cajones faltan para
  cruzar el límite; y qué pasaría si llegan diez autos más.
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
