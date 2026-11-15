# #16 — Broker MQTT simple: gemelo digital con programación lógica

> Extensión del proyecto #16. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang construiste un broker: un proceso por conexión, un router de temas
con sus suscripciones y entrega con QoS 0 y 1. Esa simulación responde «¿llegó el
mensaje, y a cuántos?». Quien opera una red de sensores necesita algo más: «¿debía
llegarle a esa persona, qué hago si no puedo entregarlo, y qué sé de verdad cuando nadie
avisa?».

El gemelo digital es el **modelo lógico** del broker y de quienes lo usan: hechos que
reflejan su estado y reglas que reflejan quién puede ver qué, cuándo y con qué
prioridad. Se escribe en Prolog porque aquí no se calcula: se deduce quién recibe un
mensaje, se justifica una decisión y se sabe decir «no lo sé».

## La marina que se clona

La «Marina Punta Neblina», de Ensenada, **no existe: es un escenario planteado por esta
extensión**, no por el problema original. Su único sistema es un broker MQTT por el que
pasan los sensores de cada amarre. Se reduce a 2 muelles, 6 amarres y unos 10 clientes.

| Parte | Contenido |
|---|---|
| Entidades | muelles A y B con tres amarres cada uno (A1-A3, B1-B3; en cada muelle, contiguos de corrido); una pasarela por muelle que publica los sensores; clientes del broker (teléfonos, tableros, el sistema de facturación); mensajes, filtros de suscripción y sesiones |
| Temas | `marina/<muelle>/<amarre>/<variable>` (por ejemplo `marina/muelleA/A2/achique`) con las variables energia, agua y achique (bomba de sentina encendida o apagada); `marina/avisos/...` para alarmas y anuncios |
| Personas | el capitán de puerto (guardia por turnos, con un teléfono de guardia), las personas propietarias de A1, A2 y B2, un huésped en B1 por unas noches, un contratista de mantenimiento con trabajo en A2 y el sistema de facturación del muelle |
| Estado por cliente | su rol, a qué amarres tiene derecho y entre qué instantes, sus filtros, si su sesión es persistente, su keep-alive, qué tiene pendiente de entrega |
| Estado por amarre | lecturas de energía, agua y achique con su instante; mensajes retenidos; si hay alarma abierta y en qué etapa: nueva, avisada, confirmada, escalada o resuelta |
| Eventos | un cliente se conecta, se despide, cae o se reconecta; la pasarela publica una lectura (QoS 0 o 1); el broker retiene un mensaje o publica un testamento; alguien confirma una alarma; llega o vence una asignación |
| Decisiones | ¿a quién se entrega?, ¿puede suscribirse a este filtro?, ¿lo retenido se entrega?, ¿está vivo el muelle o solo callado?, ¿a quién se avisa y cuándo se escala?, ¿qué se conserva cuando la cola no alcanza? |
| Reglamento (inventado) | (a) cada persona ve los datos de los amarres que tiene asignados en ese instante; el capitán ve todos; facturación ve solo energía y agua; (b) el contratista tiene acceso mientras su orden de trabajo esté vigente y aprobada por quien es propietario; el huésped, durante su estancia; (c) lo que revele cuándo hay o no hay alguien a bordo no debe llegar a quien no tiene derecho sobre ese momento; (d) toda alarma de achique debe llegar a quien tiene el amarre y al capitán, y sin confirmación en 10 minutos se escala; (e) las embarcaciones contiguas tienen derecho a ser avisadas de un riesgo que pueda alcanzarlas; (f) cada pasarela anuncia que está viva cada 30 s; (g) cada cliente puede tener hasta 5 mensajes pendientes, y una alarma no puede perderse sin que el capitán se entere de que se perdió |

## Situaciones que tu gemelo debe razonar

Las cinco las plantea esta extensión. Todas retoman conceptos del problema original
(temas jerárquicos y comodines, retained, Last Will y keep-alive, QoS 1, sesiones
persistentes y el suscriptor lento); la 1 además la pide el foco del proyecto: la
coincidencia de temas con comodines. En cada una, tu gemelo debe decidir **y poder
explicar la decisión**.

### Situación 1 — ¿Quién oye este tema?

- **Qué pasa.** La pasarela del muelle A publica que la bomba de A2 se encendió. Esa
  tarde la persona de A1 pidió «enterarme de todo lo del muelle A»: su filtro cubre las
  bombas de A1, A2 y A3. El contratista de A2 tiene un filtro propio sobre todo A2, pero
  su orden de trabajo venció hace un rato. Facturación escucha energía de todos los
  amarres. Un huésped intenta suscribirse a todo el árbol de la marina.
- **Qué datos hay.** Los filtros de cada cliente (con y sin comodines), las asignaciones
  con sus instantes y los temas publicados. Ningún hecho dice «esta persona recibe esto».
- **Qué debe deducir.** Qué filtros coinciden con el tema; de ellos, cuáles pertenecen a
  quien aún tiene derecho sobre ese amarre en este instante; y qué filtros, aunque aún no
  hayan captado nada, podrían captar temas ajenos a su dueño.
- **Qué debe contestar.** Quién recibe el mensaje y quién no, con la razón en cada caso;
  qué hacer con el filtro que cubre propios y ajenos; y qué temas podría captar cada
  filtro.
- **Por qué es lógica.** Coincidir con un comodín es unificar estructuras, y recibir es
  coincidir *y* tener derecho. Si el gemelo se equivoca, un vecino ve datos que no son
  suyos o el dueño no se entera de que su barco se hunde.

### Situación 2 — Lo que dejó el huésped anterior

- **Qué pasa.** La pasarela solo publica cuando algo cambia, y el broker retiene el
  último valor de cada tema para quien se suscriba después. El huésped que ocupó B1 se
  fue ayer; hoy llega otro y se suscribe a todo B1. En el amarre quedaron retenidos tres
  mensajes: el último consumo de energía (que muestra cuándo estuvo vacío el barco), el
  estado del pedestal (con corriente o sin ella) y un achique cuyo instante falta porque
  la pasarela tenía el reloj mal.
- **Qué datos hay.** Los mensajes retenidos con su instante de publicación (uno sin él),
  el filtro del huésped nuevo y las estancias de B1.
- **Qué debe deducir.** Qué retenidos se produjeron antes de la llegada y cuáles después;
  si lo que describe a la persona se distingue de lo que describe la instalación; y cuál
  mensaje no se puede ubicar en el tiempo.
- **Qué debe contestar.** Por cada retenido: se entrega, no se entrega o no se sabe, con
  la razón; y qué tendría que pasar para que el que hoy se retiene pudiera entregarse.
- **Por qué es lógica.** Lo intuitivo es «coincide con el filtro y hoy tiene permiso, se
  entrega»; es justo lo sospechoso, porque el derecho vale desde la llegada y el dato es
  anterior. Quien lo recibiera sabría cuándo B1 estuvo sin nadie.

### Situación 3 — El muelle B guarda silencio

- **Qué pasa.** Es de madrugada. La persona de B2 pregunta si su bomba de achique está en
  calma. La pasarela B no ha mandado nada en un buen rato y su último achique decía
  «apagada». La pasarela A avisó hace unos minutos que se desconectaba por mantenimiento
  y se despidió. Y la lectura más reciente de B3 trae un valor que el sensor no puede
  dar.
- **Qué datos hay.** Eventos de conexión, despedida y caída; el instante del último
  paquete de cada pasarela y su keep-alive; los testamentos publicados; las lecturas con
  su instante; el rango físico de cada variable.
- **Qué debe deducir.** Si cada pasarela está viva, callada por aviso o caída; qué
  significa el último achique de B2 con un muelle sin reportar; y si la lectura imposible
  de B3 cuenta como dato.
- **Qué debe contestar.** Por amarre, tres respuestas distintas: «hay alarma», «no hay
  alarma» y «no lo sé»; y qué evidencia haría falta para salir de la duda.
- **Por qué es lógica.** «No hay alarma registrada» no es «no hay alarma». Lo obvio (si
  nada suena, el barco está bien) es lo peligroso: un muelle caído parece idéntico a uno
  tranquilo. Si el gemelo calla, alguien no se entera de una inundación; si grita de más,
  despierta al capitán por nada.

### Situación 4 — La bomba que no se apaga

- **Qué pasa.** En A2, la bomba de achique lleva encendida de corrido, y el pedestal de A2
  dejó de dar corriente: el barco sobrevive con su batería. La persona propietaria está
  de viaje y su teléfono no se conecta; el contratista de A2 no tiene autoridad para
  confirmar. La pasarela repitió la lectura tres veces porque no vio la confirmación de
  recibo. A los lados están A1 y A3; el capitán está en la otra punta del muelle B.
- **Qué datos hay.** Lecturas de achique y energía de A2 (con repeticiones), el estado de
  las sesiones, las confirmaciones, el plazo del reglamento, quiénes son contiguas y las
  asignaciones vigentes.
- **Qué debe deducir.** En cadena: la bomba está en marcha continua; sin corriente de
  tierra la batería se agota; si la bomba se detiene el barco puede hundirse; un barco que
  se hunde amenaza a las contiguas; y la alarma, sin confirmar, ya debe escalar. También,
  cuántas alarmas distintas hay (no tres) y en qué etapa están. Nada de eso lo mide
  un sensor.
- **Qué debe contestar.** A quién avisar ahora y qué contiene el aviso; cuándo se escala;
  y, cuando el reglamento choca consigo mismo (la privacidad de A2 contra el derecho de
  A1 y A3 a prevenirse), qué regla prevalece, a quién se le falla y qué le cuesta.
- **Por qué es lógica.** Las dos partes tienen razón: avisar a los vecinos expone a quien
  no autorizó nada; callar expone sus barcos. La prioridad se declara una vez, no se
  improvisa a las tres de la mañana, y la explicación debe poder defenderse ante ambos.

### Situación 5 — La cola del teléfono de guardia

- **Qué pasa.** El teléfono del capitán, con sesión persistente, pasó un rato sin señal
  durante una tormenta. Mientras tanto, el broker le fue guardando mensajes: lecturas de
  consumo que se repiten cada pocos segundos, dos alarmas de achique (una ya resuelta por
  su dueño), un aviso de viento y reintentos de entrega sin confirmar. La cola de cada
  cliente tiene tope y hay más mensajes que lugares; a otro cliente, el tablero de
  facturación, que lee lento, le pasa algo parecido.
- **Qué datos hay.** Los mensajes pendientes con su tema, QoS, instante e identificador;
  el tope; la sesión; los eventos de las alarmas y de la reconexión.
- **Qué debe deducir.** Qué mensajes ya no aportan nada porque otro más nuevo los
  reemplaza; cuáles son duplicados de un reintento; qué alarmas siguen abiertas; y, si aun
  así sobran mensajes, cuáles se sacrifican.
- **Qué debe contestar.** Qué queda en la cola y en qué orden se entrega, qué se descarta
  y por qué, qué se le avisa al capitán de lo perdido, y cómo se desempata cuando dos
  alarmas compiten por el último lugar.
- **Por qué es lógica.** Lo intuitivo es tirar lo más viejo; pero lo más viejo puede ser
  la única alarma abierta, y lo recién llegado una lectura que nadie necesita. Qué se
  pierde y qué se conserva sale de reglas de prioridad declaradas una vez.

## Por qué no basta un script

Con `if tema == "marina/muelleA/A2/achique": avisar(propietario_A2)` resuelves un tema
exacto, un destinatario y un mundo en que nadie calla ni cambia de lugar. Tu gemelo debe
contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿A quién se le entrega la alarma de la bomba de A2? | decisión |
| ¿Por qué el contratista ya no la recibe? | explicación |
| ¿Qué filtros captarían un mensaje del tema `marina/muelleA/A2/achique`? | todas las respuestas |
| ¿Qué tendría que ser cierto para que la persona de A1 pueda vigilar todo su muelle? | la pregunta al revés |
| ¿Qué pasaría si el contratista recibiera una prórroga de una hora? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir un cliente, sus filtros y un mensaje en un instante?
2. Un filtro con comodín puede captar temas que aún nadie publica: ¿cómo le preguntas a
   tu gemelo qué *podría* captar y qué *captó*?
3. Cuando la privacidad de una persona choca con la seguridad de otra, ¿dónde queda
   escrito cuál gana y a quién se le falla?
4. ¿Cómo distingue tu gemelo «no hay alarma» de «no sé si hay alarma»?
5. En Erlang el router hace coincidir temas y entrega a gran velocidad, y el broker
   protege su memoria de clientes lentos. ¿Qué de eso podría alimentar a este gemelo, y
   qué decide el gemelo que un router no puede?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la marina, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar eventos y lecturas
  simulados o graficar.

## Supuestos de esta extensión

- Inventado por esta extensión, no por el original: la «Marina Punta Neblina», sus
  muelles y amarres, las personas, los roles y el reglamento (a)-(g), incluidos el
  keep-alive de 30 s, el plazo de 10 minutos y el tope de 5 mensajes. Son datos del
  ejercicio, no hechos del mundo ni estadísticas.
- Del original viene la regla de que el broker desconecta a un cliente que no manda nada
  en 1.5 veces su keep-alive, y los conceptos de temas, QoS, retained, Last Will y sesión.
- Escala reducida: 2 muelles, 6 amarres y unos 10 clientes, contra los 3,000 clientes y
  10,000 mensajes por segundo del escenario original.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas se
  puedan repetir. Las lecturas y los reintentos entran como hechos, no se sortean.
- Tú defines y declaras como supuesto: los nombres exactos de las variables y la forma de
  escribir un comodín; si un filtro que cubre propios y ajenos se rechaza entero o se
  recorta; qué variables describen a la persona y cuáles a la instalación; cuánto tiempo
  seguido vuelve sospechosa a una bomba; qué dice el aviso a las contiguas; qué fuente
  pesa más si dos se contradicen; el desempate entre alarmas y qué regla gana en cada
  choque.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Permisos que cambian en caliente: qué pasa con los mensajes ya en cola cuando una
  asignación vence a medias.
- El teléfono de guardia que pasa de una persona a otra entre turnos.
- Un cliente malicioso que publica en un tema que no le toca.
- Quién responde cuando un aviso no se entregó y un barco sufre un daño.

---
*Las cifras de dominio (el 1.5 del keep-alive y los niveles de QoS) vienen del problema
original. El escenario, sus plazos, topes y reglamento son inventados: verifica la
fuente vigente de toda cifra antes de citarla.*
