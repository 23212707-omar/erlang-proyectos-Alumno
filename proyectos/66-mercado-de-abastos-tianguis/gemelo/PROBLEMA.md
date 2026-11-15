# #66 — Mercado de abastos / tianguis: gemelo digital con programación lógica

> Extensión del proyecto #66. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el mercado: un proceso por locatario con su catálogo, un
proceso por pedido, un asignador de repartidores, fallas inyectadas. Esa simulación
responde «¿qué está pasando con cada pedido?». El mercado necesita algo más: «¿a quién le
tocó el último tomate, quién lleva cada pedido, y por qué esa respuesta y no otra?».

El gemelo digital es el **modelo lógico** del mercado: hechos que reflejan su estado
(existencias, precios, pedidos, repartidores) y reglas que reflejan cómo se casa a cada
cliente con sus locatarios y su repartidor. Se escribe en Prolog porque lo que hay que
resolver aquí no es contar pedidos, sino repartir lo escaso sin contradicciones,
justificar a quién se le falla y saber decir «no lo sé».

## El mercado que se clona

Un mercado techado de Tijuana en una mañana de pedidos (7 a 11 a. m.), reducido a 6
locatarios en 3 pasillos, 3 repartidores (moto o bicicleta) y unos 10 pedidos.

| Parte | Contenido |
|---|---|
| Entidades | mercado → pasillo → locatario → producto y lote; clientes; pedidos; repartidores |
| Estado por locatario | existencia por producto, precio vigente (por kilo, caja o manojo), lotes con su día de llegada |
| Estado por pedido | líneas (a qué locatario, qué producto, cuánto, a qué precio lo vio el cliente), medio de pago (efectivo o transferencia), si acepta entrega parcial, qué ya se recogió |
| Estado por repartidor | vehículo, a qué pedidos está asignado, en qué punto va |
| Eventos | llega un pedido, un locatario cambia un precio o avisa que se agotó, un pedido queda listo en un puesto, el repartidor recoge o se retrasa, el cliente paga |
| Decisiones | ¿a qué pedido le alcanza?, ¿qué repartidor lo lleva y en qué orden pasa?, ¿se entrega incompleto o se cancela?, ¿a qué precio se cobra?, ¿qué lote se surte? |

## Situaciones que tu gemelo debe razonar

Cuatro de las cinco salen del problema original (la 1, la 2, la 3 y la 4). La quinta
parte de sus datos del mundo real sobre perecederos y plantea algo nuevo. En cada una,
tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — Más pedidos de tomate que tomate

- **Qué pasa.** Un locatario se queda sin tomate cuando varios pedidos lo incluyen (12 en
  el escenario original; aquí unos pocos). Cada pedido trae además líneas de otros
  puestos. Una clienta ya pagó por transferencia; otro paga en efectivo al recibir; a
  uno de los pedidos ya le recogieron lo de otros puestos.
- **Qué datos hay.** Existencia del locatario, líneas de cada pedido, cuándo llegó cada
  uno, medio de pago, estado de recogida y qué repartidor lo tiene. Ningún dato dice a
  quién le toca.
- **Qué debe deducir.** A qué pedidos les alcanza el tomate, cuáles quedan sin él y qué
  consecuencia tiene eso en los demás puestos de cada pedido afectado.
- **Qué debe contestar.** El reparto completo y la razón por pedido. Dos partes tienen
  razón (quien llegó antes, quien ya pagó, quien quedaría completo): la regla debe decidir
  y decir a quién se le falla. Si hay varios repartos válidos, cuáles son.
- **Por qué es lógica.** No se pregunta «¿hay tomate?», sino cómo repartir lo que hay
  entre exigencias que chocan. Es un problema de restricciones.

### Situación 2 — El pedido de cuatro puestos al que le falta una pieza

- **Qué pasa.** Una cliente pidió a cuatro locatarios. El repartidor ya recogió en tres;
  el cuarto avisa que su producto ya no está. El original lo plantea como caso difícil:
  ¿se entrega incompleto o se cancela? Y quién responde por lo que falta.
- **Qué datos hay.** Las cuatro líneas y su estado, si la cliente aceptó entrega parcial,
  qué se pagó y cómo (transferencia o efectivo), cuáles productos son perecederos y la
  distancia que falta hasta la cliente.
- **Qué debe deducir.** En qué estado queda el pedido, qué pasa con lo ya recogido, qué
  se cobra o se devuelve y a cargo de quién queda lo que sobra. Una cadena: línea
  faltante, pedido incompleto, aceptación de la cliente, destino de lo recogido, ajuste
  del cobro.
- **Qué debe contestar.** El veredicto del pedido, la cadena que lo sostiene y qué tendría
  que ser distinto para que el veredicto cambiara.
- **Por qué es lógica.** Cada paso depende del anterior y cambia según pago, perecibilidad
  y preferencia: es encadenar deducciones, no mirar un campo.

### Situación 3 — El repartidor retrasado y los pasillos que se pisan

- **Qué pasa.** Un repartidor se retrasa con un pedido de cuatro locatarios (escenario
  original). Otros dos pedidos pasan por los mismos pasillos: las rutas se solapan. El
  original pregunta cómo evitar que un repartidor espere 30 minutos en un puesto.
- **Qué datos hay.** Repartidores y su vehículo, pedidos con sus puestos y pasillos,
  minutos de camino entre puntos, cuándo estará listo cada pedido en cada puesto y el
  retraso ya acumulado.
- **Qué debe deducir.** Qué pedido lleva cada repartidor, en qué orden pasa por los
  puestos, dónde le tocaría esperar y cuánto, y si el retraso obliga a reasignar.
- **Qué debe contestar.** La asignación y el orden de paradas completos, la espera por
  parada y por qué no otro orden. Lo intuitivo es empezar por el puesto más cercano; es
  sospechoso porque ese orden puede ser el que más espera produce y el que deja los
  perecederos al final del viaje.
- **Por qué es lógica.** Se acomodan pedidos, repartidores y paradas a la vez, sobre un
  mapa de pasillos: restricciones y recorrido, no una distancia mínima.

### Situación 4 — El precio que vio la cliente y el que pagó

- **Qué pasa.** El original plantea un cambio de precio entre que la cliente ve el
  producto y que paga. Los locatarios ajustan precios varias veces en la mañana, la
  conectividad del mercado es mala y a veces capturan el cambio desde su puesto con
  retraso. La cliente pagó una parte por transferencia y otra queda en efectivo.
- **Qué datos hay.** Precio que se le mostró y a qué hora, historial de precios del
  puesto con el minuto en que se hizo el cambio y el minuto en que el sistema lo supo,
  y el minuto y medio del pago.
- **Qué debe deducir.** Qué precio estaba vigente cuando la cliente vio y cuando pagó; si
  el cambio llegó al sistema antes o después; y cuándo ese orden no se puede establecer.
- **Qué debe contestar.** Cuánto corresponde cobrar y quién absorbe la diferencia
  (cliente, locatario o nadie), o «no se sabe» con lo que haría falta saber. Aquí el
  sistema y el puesto no se ponen de acuerdo, y ambos pueden tener razón.
- **Por qué es lógica.** «Lo que dice el sistema» y «lo que pasó en el puesto» son dos
  afirmaciones distintas; el gemelo razona sobre la distancia entre ellas.

### Situación 5 — La fresa que nadie sabe cuántos días tiene

- **Qué pasa.** Es la situación nueva de esta extensión. Los perecederos duran poco (hojas
  verdes 2-3 días, fresa 3-5) y hacia la tarde se rebaja para vaciar. Un locatario tiene
  dos lotes de fresa de días distintos y un tercero sin día de llegada capturado, y
  llegan pedidos cuyos viajes tardan distinto.
- **Qué datos hay.** Producto, lote, día de llegada (a veces faltante), pedidos pendientes
  y cuánto tardaría cada uno en llegar.
- **Qué debe deducir.** La frescura que le quedaría a cada lote al llegar con la cliente
  (nadie la mide), qué lote puede surtir qué pedido sin llegar pasado, y qué lote
  conviene rebajar hoy.
- **Qué debe contestar.** El reparto de lotes a pedidos con su razón. Lo intuitivo es dar
  primero el lote más viejo para que no se pierda; es sospechoso porque un viaje largo
  puede entregarlo vencido. Para el lote sin día, «no se sabe» y qué dato lo resolvería.
- **Por qué es lógica.** La frescura no es un dato: se concluye de varias cosas, y la
  duda debe distinguirse de «sí» y de «no».

## Por qué no basta un script

Con `if existencia[tomate] > 0: surtir(pedido)` surtes un pedido con el catálogo perfecto
y nadie más pidiendo. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué repartidor lleva el pedido 7 y por dónde pasa? | decisión |
| ¿Por qué al pedido 7 sí le tocó tomate y al 9 no? | explicación |
| ¿De cuántas formas puedo repartir los tomates entre los cuatro pedidos? | todas las respuestas |
| ¿Qué tendría que pasar para que el pedido 9 salga completo? | la pregunta al revés |
| ¿Qué pasa si el repartidor 2 se retrasa 20 minutos más? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Quién responde si un producto del pedido ya no está, y dónde queda escrito?
2. ¿Cómo evitas que un repartidor espere 30 minutos en un puesto?
3. ¿Cómo distingue tu gemelo «el precio no cambió» de «no sé si cambió antes del pago»?
4. ¿Qué parte de la explicación le sirve a cada quien, y cuál es ruido?
5. En Erlang cada locatario y cada pedido son procesos. ¿Qué de eso podría alimentar a
   este gemelo, y qué decide el gemelo que un proceso aislado no puede?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del mercado, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra el reparto y
  la ruta con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar pedidos o graficar.

## Supuestos de esta extensión

- Escala reducida: 6 locatarios, 3 pasillos, 3 repartidores y unos 10 pedidos, contra los
  100 locatarios, 20 repartidores y 300 pedidos del escenario original. En la situación 1
  son unos pocos pedidos de tomate, no 12.
- El «ahora» es un hecho del modelo (minutos desde las 7:00), no el reloj del sistema, para
  que las respuestas se puedan repetir.
- Los puestos, productos, clientes, minutos de camino y de preparación y los días de
  llegada de los lotes son datos del ejercicio que defines tú. Los números de los
  ejemplos («pedido 7», «20 minutos más») son ilustrativos.
- Tú decides, y lo declaras como supuesto (el original no da esas cifras ni reglas): cómo
  se ordenan pedidos que compiten por lo escaso, si un pedido parcial se entrega o se
  cancela y cómo se ajusta el cobro, cuánto retraso obliga a reasignar, cuánto vale un
  precio visto, cuándo es dudosa una captura de precio y cuándo se rebaja un lote.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Sustituir un producto agotado por otro, con permiso de la cliente.
- Capacidad de carga y alcance de una moto frente a una bicicleta.
- Un puesto que cierra antes de tiempo o un pasillo bloqueado.
- Rebajas de la tarde como política declarada, y auditoría de por qué se cobró cada pedido.

---
*Las cifras vienen del problema original: vida de hojas verdes (2-3 días) y fresa (3-5),
100 locatarios, 20 repartidores, 300 pedidos de 7 a 11 a. m., 12 pedidos con tomate, pedido
de 4 locatarios y espera de 30 minutos. Todo lo demás es escala reducida o dato del
ejercicio. Verifica la fuente vigente antes de citarlas.*
