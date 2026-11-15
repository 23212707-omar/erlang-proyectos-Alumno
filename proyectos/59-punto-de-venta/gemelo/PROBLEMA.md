# #59 — Punto de venta: gemelo digital con programación lógica

> Extensión del proyecto #59. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la tienda: cajas que cobran al mismo tiempo, ventas que
se abren, se pagan o se cancelan, y fallas inyectadas. Esa simulación responde «¿qué
está pasando en las cajas?». Quien administra la tienda necesita algo más: «¿esta venta
ya ocurrió, qué se le puede descontar, cuánto debe haber en la caja, y cómo lo
demuestro?».

El gemelo digital es el **modelo lógico** de la tienda: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque lo que hay que
resolver aquí no es sumar, sino deducir qué es elegible, qué es válido y qué no se puede
saber todavía, y dejar la justificación a la vista de quien audite.

## El punto de venta que se clona

Una tienda de Tijuana con una sucursal en la franja fronteriza y otra en el interior del
país, reducida a 2 cajas por sucursal, 2 turnos, unos 12 tickets y unos 10 productos.

| Parte | Contenido |
|---|---|
| Entidades | sucursal → caja → turno (con su cajero); ticket → partida; producto; promoción y cupón; gerente que autoriza |
| Estado por ticket | partidas (producto, cantidad, precio), descuentos aplicados y quién los capturó, tasa de IVA de cada partida, pagos por forma y por moneda, intentos de cobro con su respuesta (aprobado, rechazado o ninguna), estado del timbrado |
| Estado por turno | fondo inicial, retiros, efectivo contado al cierre (pesos y dólares), si el corte está abierto o cerrado, ventas que siguen en proceso |
| Estado del sistema | tipo de cambio con el instante en que se registró; vigencia confirmada del estímulo fiscal; inventario |
| Eventos | se abre una venta, se captura una partida o un descuento, se envía el cobro, responde o no la terminal, se imprime, se timbra o falla el timbrado, se cancela o devuelve, se cierra el turno |
| Decisiones | ¿ya ocurrió la venta?, ¿qué tasa lleva?, ¿qué descuento aplica y quién lo autoriza?, ¿se puede cancelar?, ¿cuánto efectivo debe haber?, ¿se puede cerrar el corte? |

## Situaciones que tu gemelo debe razonar

Cuatro salen del problema original (la 1, la 2, la 3 y la 5); la 4, los descuentos,
plantea algo que el original no menciona y que el foco del proyecto pide. En cada una,
tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — La venta que se quedó a medias

- **Qué pasa.** Una clienta paga con pago mixto: parte en efectivo y parte con tarjeta.
  A mitad del cobro la terminal bancaria deja de responder. El cajero reintenta y,
  por su lado, la caja reenvía el cobro por la red. La clienta jura que su banco ya le
  cargó; el ticket no muestra aprobación; hay fila y la mercancía sigue en el mostrador.
- **Qué datos hay.** Los intentos de cobro con su instante y su respuesta (o ninguna),
  la clave que lleva cada envío, el efectivo ya recibido, las partidas y el inventario
  apartado. Ningún dato dice «la venta ocurrió».
- **Qué debe deducir.** En qué punto está la venta: ocurrida y ya imposible de perder,
  no ocurrida, o imposible de saber todavía. Si dos envíos son un mismo cobro repetido
  o dos cobros distintos. Qué ocurre con la mercancía apartada y con el efectivo.
- **Qué debe contestar.** Una de tres respuestas y, si es la dudosa, qué hacer
  (retener, confirmar con el banco, entregar), a quién se le falla si el gemelo se
  equivoca (a la clienta cobrada sin llevarse nada o a la tienda que entrega sin cobro)
  y qué evidencia resolvería la duda.
- **Por qué es lógica.** «Sin respuesta» no es «rechazado», y que una venta ocurra es
  una conclusión de varios hechos y de una secuencia de estados, no un campo del ticket.

### Situación 2 — El ticket de ayer que se cancela hoy

- **Qué pasa.** Un cliente regresa con un ticket del turno anterior, pagado parte en
  dólares y parte con tarjeta, y pide cancelarlo. Ese turno ya cerró su corte y cuadró.
  El tipo de cambio de hoy no es el de ayer, y el comprobante fiscal puede estar
  timbrado o pendiente. Lo intuitivo es sospechoso: piensa qué se rompe si «se borra» la
  venta de ayer.
- **Qué datos hay.** El ticket original (partidas, tasas, pagos por moneda y el tipo de
  cambio de ese momento), el corte cerrado, el turno de hoy con su efectivo, quién pide
  y quién puede autorizar, el estado del timbrado y el inventario.
- **Qué debe deducir.** Si la cancelación procede y con qué autorización; en qué corte
  se anota el movimiento; cuánto se devuelve, en qué moneda y con qué tasa y qué tipo de
  cambio; qué pasa con el inventario y con el comprobante.
- **Qué debe contestar.** La decisión con la cadena completa de razones, desde el ticket
  hasta el corte que cambia; y qué sería distinto si el timbrado estuviera pendiente.
- **Por qué es lógica.** La respuesta es una cadena de deducciones sobre hechos que no se
  pueden alterar: lo ocurrido no se borra, se contrarresta, y eso es trazabilidad.

### Situación 3 — ¿Qué tasa lleva esta partida?

- **Qué pasa.** En la franja fronteriza el decreto de estímulo fiscal ha permitido 8 %
  en lugar del 16 % general; el propio original pide verificar su vigencia. Un ticket se
  abre antes de la medianoche y se paga después, justo cuando la vigencia podría
  cambiar. Además, redondear por partida o por total da centavos distintos.
- **Qué datos hay.** Zona de la sucursal, vigencia del estímulo y cuándo se confirmó
  por última vez, los eventos del ticket con su instante, las partidas ya con
  descuento, y los dos métodos de redondeo. Ningún dato dice «esta partida lleva 8 %».
- **Qué debe deducir.** La tasa de cada partida, sobre qué base se calcula, el total
  con cada método de redondeo y de dónde sale la diferencia de centavos; y si la tasa
  es cierta, inferida o dudosa.
- **Qué debe contestar.** El desglose del ticket, o «no lo sé» con qué habría que
  confirmar y quién pierde con cada error: el cliente cobrado de más o la tienda que
  debe la diferencia. El gemelo no escoge un lado sin decirlo.
- **Por qué es lógica.** La tasa no es un dato de la partida: depende del lugar, de
  cuándo «ocurrió» la venta y de qué tan firme es la vigencia, y la duda debe verse.

### Situación 4 — Una promoción, un cupón y un cajero con poca autoridad

- **Qué pasa.** Un producto tiene promoción de temporada; el cliente trae un cupón que
  una vez usado ya no sirve, y que otra caja está usando en este mismo instante. El
  cajero captura a mano un «descuento de cortesía». Algunas promociones piden cierta
  cantidad o cierto producto, y a cierto descuento solo un gerente puede llegar.
- **Qué datos hay.** Las partidas, las promociones con sus condiciones, los cupones con
  su vigencia y su uso, quién captura y con qué rol, y las autorizaciones registradas.
- **Qué debe deducir.** Qué descuentos son elegibles en cada partida, cuáles se estorban
  entre sí, cuál se aplica y cuál se descarta; si hace falta autorización y existe una
  vigente; qué base gravable queda; qué captura parece un error o un abuso.
- **Qué debe contestar.** Los descuentos aplicados y los descartados, cada uno con su
  razón; qué falta para que uno descartado aplique y quién puede dárselo; y a quién se
  le falla (al cliente que esperaba el descuento o a la tienda que perdería margen).
- **Por qué es lógica.** Elegibilidad, límite y desempate se declaran una vez y valen
  para todos los casos, también los que nadie previó; el orden en que se aplican cambia
  el total y debe quedar explicado.

### Situación 5 — El corte que no cuadra

- **Qué pasa.** Al cierre, la cajera cuenta pesos y dólares y la cuenta no coincide con
  lo esperado. Durante el turno hubo dólares con vuelto en pesos a distintos tipos de
  cambio, una devolución de un ticket anterior, un retiro, y una venta cuyo cobro sigue
  en proceso. Una diferencia pequeña es normal; una grande exige explicación.
- **Qué datos hay.** Fondo, ventas con sus pagos y vueltos por moneda, devoluciones,
  retiros, conteo al cierre, tipo de cambio de cada venta y ventas aún en proceso.
  Nadie guarda «efectivo esperado». Lo intuitivo es sospechoso: piensa en qué moneda y a
  qué tipo de cambio conviene comparar.
- **Qué debe deducir.** El efectivo esperado por moneda; qué parte de la diferencia
  explican los redondeos, la venta en proceso y los movimientos; qué queda sin
  explicar; y si el corte puede cerrarse ya o debe esperar.
- **Qué debe contestar.** «Cuadra», «no cuadra» o «no se sabe todavía»; en los dos
  últimos, la diferencia partida en causas, qué ventas pendientes la cambiarían y si
  el cajero puede irse. A quién se le falla: al cajero señalado sin motivo o a la
  tienda que cierra con un faltante sin explicar.
- **Por qué es lógica.** El invariante del corte se escribe una vez y de él se deduce el
  esperado; una venta en proceso vuelve la respuesta «no lo sé», no «no cuadra».

## Por qué no basta un script

Con `if contado != esperado: alerta()` revisas un corte sin ventas pendientes, en una
sola moneda y con un esperado que alguien ya calculó. Tu gemelo debe contestar, **con las
mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Se puede cerrar el corte de la caja 2? | decisión |
| ¿Por qué el cupón no se aplicó al ticket 7? | explicación |
| ¿Qué tickets del turno siguen en duda? | todas las respuestas |
| ¿Qué tendría que pasar para que proceda esa cancelación? | la pregunta al revés |
| ¿Qué pasaría si el cobro dudoso resulta rechazado? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir un ticket en un instante?
2. ¿En qué momento exacto una venta «ocurre» y ya no se puede perder, y qué hechos lo
   prueban sin que ningún campo lo diga?
3. ¿Qué invariante debe cumplir el corte, y cómo lo expresas sin guardar «efectivo
   esperado»?
4. Cuando dos descuentos se estorban, ¿dónde queda escrito cuál gana y quién puede
   romper la regla?
5. En Erlang cada venta era un proceso con sus estados y cada caja era independiente.
   ¿Qué de eso alimentaría a este gemelo, y qué decide el gemelo que un proceso no puede?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la tienda, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar tickets y fallas
  simulados o graficar.

## Supuestos de esta extensión

- Escala reducida: 2 sucursales, 2 cajas por sucursal, 2 turnos, unos 12 tickets y unos
  10 productos, contra las 4 cajas, 600 tickets al día y 800 productos del escenario
  original. La sucursal del interior, los roles (cajero, gerente) y los identificadores
  de los ejemplos («caja 2», «ticket 7») son del ejercicio.
- Promociones, cupones y topes de autorización de la situación 4 son inventados para el
  ejercicio: ni el original ni este documento los dan. Tú los defines y los declaras.
- El «ahora» es un hecho del modelo, en minutos desde un origen fijo, no el reloj del
  sistema. El tipo de cambio también entra como hecho con su instante; las reglas no
  sortean nada.
- Tú defines: cuánto silencio de la terminal hace dudoso un cobro, cuándo «ocurre» una
  venta, qué método de redondeo usas, qué tan vieja puede ser la confirmación del
  decreto, hasta cuándo un ticket se puede cancelar, qué diferencia de corte es
  «pequeña» y quién autoriza qué. El original no da ninguno de esos valores.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Factura pedida después de que el timbrado falló: qué datos faltan y hasta cuándo.
- Productos con tasa distinta o exentos dentro del mismo ticket.
- Cambio de cajero a media jornada: cuál corte absorbe cada movimiento.
- Comisión de la terminal y propinas dentro del efectivo esperado.
- Devolución parcial de un ticket con descuentos repartidos entre partidas.

---
*Las cifras de dominio (IVA de 16 % y de 8 %, CFDI 4.0, cajas, tickets y productos del
escenario) vienen del problema original; lo demás (promociones, cupones, roles,
sucursal del interior) es del ejercicio. Verifica la fuente vigente del decreto antes de
citarlo en tu entrega.*
