# #19 — Observabilidad: gemelo digital con programación lógica

> Extensión del proyecto #19. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang instrumentaste una aplicación: métricas en `/metrics`, percentiles,
`logger` con metadata y `recon` para mirar la VM en caliente. Esa simulación responde
«¿qué veo?». Quien está de guardia a las 3 de la mañana necesita algo más: «¿esto es real,
a quién despierto y qué le digo?».

El gemelo digital es el **modelo lógico** de la plataforma y de su guardia: hechos que
reflejan lo medido y reglas que reflejan cómo se decide con ello. Se escribe en Prolog
porque aquí no se calcula: «fuga», «presupuesto de error» y «sana» no las mide ningún
sensor, se deducen de varios hechos, se justifican y se sabe decir «no lo sé».

## La plataforma que se clona

«Agua en Línea» es la plataforma digital del Organismo de Agua de Cañada Seca, un
municipio de Baja California. **No existe: es un escenario planteado por esta extensión**,
no por el problema original. Se reduce a 5 aplicaciones (como el original), una de ellas
en dos instancias, y a una noche de guardia dentro de un mes de operación.

| Parte | Contenido |
|---|---|
| Entidades | aplicaciones: pagos (recibos en línea por tarjeta, transferencia y tienda; instancias A y B), fugas (reportes ciudadanos), pozos (telemetría de pozos y tanques), avisos (SMS de cortes y tandeos) y citas (aclaraciones); el monitor; la pasarela de pagos y el proveedor de SMS, ambos externos |
| Personas | la ingeniera de guardia primaria, el ingeniero de guardia secundario, el operador de la sala de control (humano, de noche, sin acceso al código), la directora de operación (decide congelamientos) y la jefa de atención al ciudadano |
| Estado por aplicación | su objetivo de disponibilidad, de qué depende, qué instancias corren y lo que el monitor midió: memoria por tipo, cola de mensajes, procesos, latencia en p50, p95 y p99 por canal, errores |
| Estado del monitor | cuántas series guarda, qué etiquetas tiene cada métrica, cada cuánto raspa y qué raspados le faltan |
| Eventos | un raspado llega o falta; despliegue, reinicio o mantenimiento publicado; se dispara una alerta; se llama a alguien y acusa recibo o no; llega una petición, se cobra o se reintenta; una línea de log |
| Decisiones | ¿hay un problema real?, ¿se despierta a alguien o es pendiente de la mañana?, ¿a quién?, ¿está sana esta aplicación?, ¿qué pasó con esta petición? |
| Reglamento de guardia (inventado) | (a) solo se despierta por algo accionable que ya afecta, o afectará antes de las 6:00, a un ciudadano o a un objetivo de disponibilidad; lo demás es pendiente de la mañana; (b) hay guardia primaria y secundaria: sin acuse en 10 minutos se llama a la otra; (c) nadie recibe más de 2 llamadas por noche, salvo severidad máxima (riesgo para personas o bienes); (d) cada aplicación tiene un objetivo mensual, con su presupuesto de caída; agotado, se congelan sus cambios; (e) el mantenimiento publicado antes de empezar no gasta presupuesto; (f) el monitor tiene un tope de series y no puede consumir más que lo que vigila; (g) en producción solo se diagnostica en caliente sin pausar el nodo |

## Situaciones que tu gemelo debe razonar

Las cinco las plantea esta extensión; todas retoman casos y datos del problema original
(la fuga lenta, la cola que crece, el p99 sin cambio del promedio, la cardinalidad
accidental, correlacionar logs con peticiones). En cada una, tu gemelo debe decidir
**y poder explicar la decisión**.

### Situación 1 — ¿Fuga, o es día de pago?

- **Qué pasa.** Es el último día del descuento por pronto pago y de madrugada la memoria
  de pagos lleva horas subiendo. Alguien dice «es la carga, hoy todos pagan». Si es una
  fuga, la instancia se agotará y se reiniciará justo en la hora pico, con pagos a medias
  y gente que pierde el descuento. Si es carga, despertar a alguien es fatiga de alertas.
- **Qué datos hay.** Memoria por tipo (procesos, binarios, tablas) de las dos
  instancias, peticiones por minuto, número de procesos, reinicios previos, memoria libre
  del nodo y un despliegue hecho en una sola instancia hace un par de días.
- **Qué debe deducir.** Si la subida se explica por la carga o sobrevive a ella; en qué
  instancia está y de qué tipo de memoria es; y si se agota antes de que abra la
  ventanilla. Ninguna métrica dice «fuga».
- **Qué debe contestar.** Despertar o dejar pendiente de la mañana, la razón, hasta qué
  momento se puede esperar y qué observación en caliente, permitida por el reglamento,
  separaría las hipótesis.
- **Por qué es lógica.** «Fuga» es una conclusión que sale de comparar instancias,
  cargas y tipos de memoria. Lo intuitivo es culpar a la instancia con más memoria: es
  sospechoso, y el gemelo debe poder mostrar quién la tiene y quién crece.

### Situación 2 — El p99 que el promedio no ve

- **Qué pasa.** Es quincena y el tablero de la directora muestra la latencia promedio de
  pagos, normal. Pero desde hace horas el p99 del canal de tarjeta se disparó: una de
  cada cien peticiones agota el tiempo de espera, la gente reintenta y algunos pagan dos
  veces. Pagos tiene un objetivo de 99.9 %, unos 43 minutos de caída al mes, y ya se
  gastó parte.
- **Qué datos hay.** Percentiles por canal, errores por espera agotada, los incidentes
  del mes con su duración y los mantenimientos, publicados o no, y cuándo se publicaron.
- **Qué debe deducir.** Qué canal sufre; si cuenta como caída aunque el servicio esté
  «vivo»; cuánto presupuesto queda tras sumar los incidentes y descontar lo que el
  reglamento perdona; y si al ritmo actual se agota antes de fin de mes.
- **Qué debe contestar.** Si el objetivo se está incumpliendo, de qué canal es la culpa,
  cuánto presupuesto queda, y si corresponde despertar a alguien, congelar los cambios o
  esperar. Y qué cambiaría si el mantenimiento de la semana pasada se hubiera publicado
  un día antes.
- **Por qué es lógica.** El presupuesto no lo mide nadie: se concluye de varios hechos.
  El promedio sano sugiere que todo está bien; justo ahí está el error.

### Situación 3 — Dos alarmas y una sola guardia

- **Qué pasa.** A las 3:10 suenan dos alertas. En pozos, la cola de mensajes del proceso
  que recibe la telemetría crece sin parar: la sala de control está decidiendo con
  lecturas atrasadas y el tanque «Lomas» se llena; si desborda, hay casas bajas
  inundadas. En pagos, la instancia que se está agotando se reiniciará antes del
  amanecer del último día del descuento. La ingeniera ya recibió dos llamadas esta noche
  y el ingeniero secundario no ha acusado recibo en 12 minutos. Ambas partes tienen razón.
- **Qué datos hay.** Las alertas con su hora, la cola y la edad de la última lectura del
  tanque, su nivel y qué bombas estaban encendidas, las llamadas con sus acuses, los
  turnos y el reglamento.
- **Qué debe deducir.** El nivel probable del tanque ahora, a partir de una lectura vieja
  y de lo que ocurre alrededor; si hay severidad máxima o solo se sospecha; quién puede
  ser llamado sin romper el reglamento; y quién queda sin atención.
- **Qué debe contestar.** A quién llamar y por cuál alerta, cuál espera y qué le cuesta,
  qué regla cedió y por qué; y qué tendría que ser cierto para poder atender las dos.
- **Por qué es lógica.** El daño seguro y chico (pagos) choca con el daño incierto y
  grave (desborde), y «no sé el nivel» no es «el nivel está bien». La prioridad entre
  reglas se declara una vez, no se improvisa a las 3 de la mañana.

### Situación 4 — El tablero en verde que no ve nada

- **Qué pasa.** A las 23:40 se desplegó fugas con una etiqueta nueva en una métrica: el
  identificador del ciudadano que reporta. Cada reporte crea una serie nueva. El monitor
  llegó a su tope, dejó de guardar series y, para no ahogarse, empezó a saltarse raspados
  de todas las aplicaciones. A las 2:00 el tablero está verde y no ha sonado ninguna
  alerta. Pero el proveedor de SMS lleva rato fallando, y a las 6:00 hay un corte
  programado que debe avisarse a una colonia con una clínica.
- **Qué datos hay.** Raspados con su instante (cada 15 s), huecos, cuántas series hay
  por métrica y cuántos valores tiene cada etiqueta, el tope del monitor, los
  despliegues y las alertas que sí se evaluaron.
- **Qué debe deducir.** En cadena: se agregó la etiqueta, luego las series crecieron
  con cada reporte, luego el monitor topó, luego dejó de raspar, luego hay huecos, luego
  el verde no prueba nada. También: qué etiqueta fue la causa; qué huecos son del monitor
  y cuáles de una aplicación; y qué alertas no pudieron evaluarse.
- **Qué debe contestar.** Por aplicación: sana, no sana o no se sabe; la etiqueta que
  debe retirarse; qué alertas «no sonaron» y cuáles «no pudieron sonar»; y qué dato
  resolvería la duda de avisos.
- **Por qué es lógica.** «No hay alertas» no es «no hay problemas». Lo intuitivo (verde =
  sano) es justo lo incorrecto, y un hueco compartido por todas las aplicaciones apunta
  al monitor, no a ellas.

### Situación 5 — ¿Se cobró o no se cobró?

- **Qué pasa.** Por la mañana una vecina reclama que le cobraron la tarjeta pero su recibo
  sigue vencido y le avisaron de corte. La pasarela dice «aprobado». En los logs de
  pagos algunas líneas traen el identificador de la petición y otras no (procesos que no
  heredaron la metadata de `logger`). Una de las instancias se reinició esa noche y dejó
  un hueco de logs. Hay dinero en juego, una sanción posible por un corte indebido y la
  confianza de la vecina.
- **Qué datos hay.** Líneas de log con instancia, instante, nivel e identificador (o sin
  él); los reinicios; los reintentos de la vecina; el reporte de la pasarela, con su
  propio reloj; y qué instantes son físicamente imposibles.
- **Qué debe deducir.** A qué petición pertenecen las líneas sin identificador por su
  instancia, su cercanía y el orden causal (aprobar antes de aplicar); si el cobro
  quedó aplicado al recibo; si hubo doble cobro por el reintento; y si la hipótesis
  «el reinicio mató el proceso entre aprobar y aplicar» queda confirmada, refutada o sin
  evidencia.
- **Qué debe contestar.** Tres respuestas distintas: «sí», «no» y «no lo sé»; la primera
  línea que rompe la historia; y qué dato haría falta para salir de la duda. Y qué
  pasaría si el reinicio hubiera ocurrido un minuto antes.
- **Por qué es lógica.** «No hay registro de que se aplicó» no es «no se aplicó», y dos
  fuentes que se contradicen no se promedian: se razona qué historia es posible.

## Por qué no basta un script

Con `if memoria > 80: despertar_guardia()` resuelves una instancia que no depende de
la carga, un monitor que nunca falla y una sola alerta a la vez. Tu gemelo debe
contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿A quién despierto por la alerta de pozos? | decisión |
| ¿Por qué no por la de pagos? | explicación |
| ¿Cuáles aplicaciones están sanas ahora: sí, no o no sé? | todas las respuestas |
| ¿Qué tendría que ser cierto para que pagos no se reinicie antes de abrir? | la pregunta al revés |
| ¿Qué pasaría si el objetivo de pagos fuera 99.99 %? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir una aplicación y su pasado reciente, sabiendo que
   lo medido no es lo que pasa?
2. «Fuga», «presupuesto» y «sana» no las mide nadie. ¿De qué hechos las deduces?
3. Cuando dos alertas reclaman a la misma persona, ¿dónde queda escrito quién espera?
4. ¿Cómo distingue tu gemelo «no hay errores» de «no sé si hay errores»?
5. En Erlang expusiste métricas, usaste `recon` y leíste logs. ¿Qué de eso alimentaría
   a este gemelo, y qué decide el gemelo que un tablero no puede?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la plataforma, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar lecturas y logs
  simulados o graficar.

## Supuestos de esta extensión

- Inventado por esta extensión, no por el original: «Agua en Línea», el organismo, las
  aplicaciones y sus dependencias, las personas, el tanque «Lomas», los canales de pago,
  el descuento por pronto pago y el reglamento (a)-(g), con sus números (6:00, 10
  minutos, 2 llamadas por noche) y los de los ejemplos (12 minutos sin acuse). Son datos
  del ejercicio, no hechos del mundo.
- Escala reducida: 5 aplicaciones con unas pocas métricas cada una, contra las 20 a 50 del
  original; una noche dentro de un mes de operación.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir. Las fallas y los desfases de reloj no se sortean: entran como hechos.
- Tú defines y declaras como supuesto: desde qué ritmo de subida una memoria es fuga; qué
  tan atrás en el tiempo una lectura deja de servir; cuántos raspados seguidos faltantes
  vuelven dudosa a una aplicación; el tope de series; cuándo una petición lenta cuenta
  como caída; qué desfase de reloj impide ordenar dos hechos; el nivel de desborde del
  tanque; y qué regla gana en cada choque.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Alertas por velocidad de consumo del presupuesto en varias ventanas de tiempo.
- Trazas de una petición a través de varias aplicaciones para ubicar el tramo lento.
- Rotación de guardias con descansos obligatorios y quién cubre a quién.
- Un segundo monitor que vigile al primero, y qué pasa si ambos fallan.

---
*Las cifras de dominio (raspado cada 15 s, percentiles, 99.9 % y 99.99 %, 5 aplicaciones)
vienen del problema original. El escenario y su reglamento son inventados: verifica la
fuente vigente de toda cifra antes de citarla.*
