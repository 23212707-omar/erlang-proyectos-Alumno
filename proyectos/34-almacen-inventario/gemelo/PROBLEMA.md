# #34 — Almacén / inventario: gemelo digital con programación lógica

> Extensión del proyecto #34. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el almacén: procesos que llevan las existencias por
ubicación, operadores con escáner que mueven mercancía al mismo tiempo y un verificador
de mínimos que avisa cuando algo escasea. Esa simulación responde «¿cuánto hay y
cuánto se movió?». El jefe de almacén necesita algo más: «¿qué prometo, de qué lote
sale, cuándo pido y, si algo sale mal, a dónde fue?».

El gemelo digital es el **modelo lógico** del almacén: hechos que reflejan su estado y
reglas que reflejan cómo se decide en él. Se escribe en Prolog porque lo difícil aquí
no es sumar entradas y restar salidas, sino decidir a quién se le cumple cuando no
alcanza, rastrear una cadena de lotes y saber qué parte del saldo es de fiar.

## El almacén que se clona

El centro de distribución de una maquiladora de Tijuana que surte a un cliente médico y
a uno automotriz, reducido a 6 números de parte, 4 ubicaciones y 3 operadores. El tiempo
se cuenta en minutos. Las cinco situaciones salen del problema original; lo que se añade
son precisiones para poder razonarlas.

| Parte | Contenido |
|---|---|
| Entidades | almacén → ubicación → lote → número de parte; operador con escáner; cliente y pedido; orden de compra al proveedor |
| Estado por parte | política de salida (FIFO o FEFO), demanda diaria, días de entrega, inventario de seguridad |
| Estado por lote | parte, minuto de recepción, caducidad (si la hay), estado (disponible, cuarentena, defectuoso), lotes de los que proviene |
| Estado por ubicación | existencia por lote según el sistema y último conteo físico |
| Eventos | entrada, salida, traspaso, ajuste, conteo, pedido nuevo, llega una orden, se declara un defecto, el escáner reintenta |
| Decisiones | ¿cuánto puedo prometer?, ¿pido ya?, ¿a quién reservo y de qué lote?, ¿qué lotes retengo o retiro?, ¿confío en este saldo? |

## Situaciones que tu gemelo debe razonar

Las cinco parten del problema original: la 1 y la 3 de sus datos del mundo real (punto de
reorden y políticas FIFO/FEFO), la 2 y la 4 de su «escenario a simular», la 5 de sus
«casos difíciles». Lo que añade esta extensión (existencia retenida, vida mínima exigida
por el cliente, lotes que se mezclan) es complemento derivado. En cada una, tu gemelo
debe llegar a una decisión **y poder explicarla**.

### Situación 1 — Hay de sobra y hay que pedir

- **Qué pasa.** Una parte del cliente automotriz muestra en el estante más de su punto de
  reorden (el original lo ejemplifica: 50 piezas por día × 6 días de entrega + 100 de
  seguridad = 400). Pero parte de ese material pertenece a un lote que acaba de pasar a
  cuarentena por una queja de calidad, otra parte ya está apartada para pedidos
  confirmados, y la orden al proveedor que debía llegar no tiene fecha confirmada. Si el
  almacén no pide hoy, la línea del cliente se detiene dentro del plazo de entrega.
- **Qué datos hay.** Movimientos por lote, estado de cada lote, pedidos confirmados,
  órdenes en camino, y demanda diaria, días de entrega e inventario de seguridad de la
  parte. Ningún dato dice «cuánto puedo prometer».
- **Qué debe deducir.** Cuánto material es realmente utilizable, y con eso si la parte
  ya está en su punto de reorden o por debajo, contando lo que viene en camino y lo que
  de ello es seguro.
- **Qué debe contestar.** Si hay que pedir ya, por qué (con la cadena: defecto →
  cuarentena → no utilizable → debajo del punto), y qué tendría que pasar para no pedir.
  Con la orden sin fecha, la respuesta no puede ser un «sí» o «no» tranquilo: tiene que
  decir en qué dependen de ella.
- **Por qué es lógica.** Lo obvio (estante contra punto de reorden) está mal; la
  respuesta sale de encadenar tres o más hechos, y «lo que viene en camino» puede ser
  cierto, falso o desconocido.

### Situación 2 — Las últimas 30 piezas

- **Qué pasa.** Quedan 30 piezas utilizables de una parte y, en el mismo minuto, entran
  dos pedidos. El del cliente automotriz es por 30 y su línea está detenida esperando;
  no acepta entregas parciales. El del cliente médico es por 20, se capturó un minuto
  antes, es para reponer material de una clínica y sí acepta parcial. Nadie debe recibir
  una pieza ya prometida a otro, y a quien no se cumpla hay que poder decirle por qué.
- **Qué datos hay.** Existencia utilizable, ambos pedidos con su minuto de captura y si
  aceptan parcial, el sector de cada cliente y las reservas ya hechas.
- **Qué debe deducir.** Qué reservas pueden coexistir sin prometer lo mismo dos veces y
  qué reparto resulta de las prioridades y los desempates.
- **Qué debe contestar.** A quién se reserva qué, a quién se le falla y con qué
  justificación. La misma pregunta, con el pedido médico por 30, o con 10 piezas más
  en cuarentena, debe cambiar la respuesta de forma explicable.
- **Por qué es lógica.** Ambos tienen razón: uno llegó primero, el otro tiene la línea
  parada. Las prioridades y los desempates se escriben una vez, y si todo empata debe
  haber igualmente una respuesta que explique que fue desempate.

### Situación 3 — El lote que llegó después sale primero

- **Qué pasa.** Un adhesivo químico (política FEFO) tiene tres lotes. El A se recibió
  primero y caduca tarde. El B se recibió después y caduca antes. El C se recibió al
  final y su etiqueta de caducidad se rompió: no hay fecha capturada. El cliente médico
  exige que el material llegue con cierta vida restante; el automotriz no. Un lote
  caducado en manos de un cliente es devolución y sanción; uno que se vence en el
  estante es dinero tirado.
- **Qué datos hay.** Política de la parte, minuto de recepción y caducidad de cada lote,
  su estado y la vida restante que cada cliente exige (si exige alguna).
- **Qué debe deducir.** Qué lotes son elegibles para cada pedido y en qué orden salen.
- **Qué debe contestar.** De qué lote surte cada cliente y por qué. El C no es ni
  elegible ni inelegible: «no se sabe», y el gemelo debe decir qué dato lo cambiaría. Si
  fuera una parte FIFO con los mismos lotes, la respuesta sería otra, y la explicación
  debe mostrar por qué.
- **Por qué es lógica.** La misma regla de salida significa cosas distintas según la
  parte y el cliente. Y «el que caduca primero sale primero» no siempre es lo correcto.

### Situación 4 — Un lote defectuoso: ¿a dónde fue?

- **Qué pasa.** Se declara defectuoso un lote de materia prima. Parte se usó en el
  ensamble de dos lotes de producto terminado, parte se subdividió en otro lote con otro
  número, y una porción se traspasó entre ubicaciones. De los lotes derivados, unos ya
  se enviaron al cliente médico y al automotriz y otros siguen en estante. Un traspaso
  de esa porción no tiene escaneo de llegada. Si se omite un cliente, el defecto llega
  a un paciente o a un vehículo.
- **Qué datos hay.** Movimientos con lote, cantidad, ubicación y minuto; qué lotes
  entran en la composición de cuáles otros; envíos a clientes; y el minuto de la
  declaración del defecto.
- **Qué debe deducir.** Todos los lotes afectados, aunque lleven otro número, dónde
  está hoy cada uno (ubicación o cliente) y cuáles se enviaron después de la declaración.
- **Qué debe contestar.** Qué retener, a qué clientes avisar y qué cantidad puede estar
  en riesgo. La pregunta al revés también: dado el reclamo de un cliente por un lote
  terminado, de qué materias viene. La porción traspasada sin escaneo es «no se sabe»,
  no «en la ubicación de origen» ni «usada».
- **Por qué es lógica.** Es recorrer relaciones entre entidades hacia adelante y hacia
  atrás, a través de cadenas de largo variable. Buscar solo el número del lote
  declarado deja fuera lo que realmente importa.

### Situación 5 — El saldo que no cuadra

- **Qué pasa.** Un conteo físico encuentra 12 piezas donde el sistema dice 40 (el
  original usa justo este contraste). En el historial hay dos salidas iguales, del mismo
  operador, de la misma parte y lote, en minutos casi seguidos: pueden ser un reintento
  del escáner o dos tarimas reales. Además, el mismo día hubo un traspaso que se
  capturó solo de un lado. La línea del cliente espera con los saldos que ve el
  sistema, y auditoría quiere que la historia no se borre.
- **Qué datos hay.** El saldo derivado de los movimientos, el conteo con su minuto, los
  movimientos de esa parte y ubicación (con operador y minuto) y los traspasos.
- **Qué debe deducir.** Qué parte de la diferencia explican los posibles duplicados y el
  traspaso a medias, y qué parte queda sin explicación.
- **Qué debe contestar.** El ajuste que procede, justificado, sin borrar ningún
  movimiento (se compensa); qué saldo habría tenido la parte en un minuto pasado, con y
  sin el duplicado. Lo que ninguna evidencia explica es «no se sabe», no «merma».
- **Por qué es lógica.** El saldo no se guarda, se deduce del historial; así se puede
  preguntar por cualquier minuto pasado o por «qué pasaría si este movimiento no
  hubiera existido».

## Por qué no basta un script

Con `if existencia < punto_reorden: pedir()` resuelves una parte con saldos perfectos.
Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿De qué lote surto el pedido 7? | decisión |
| ¿Por qué no del lote B si caduca antes? | explicación |
| ¿Qué lotes alcanzó el defecto del lote M1? | todas las respuestas |
| ¿Qué tendría que llegar para no pedir la parte 3? | la pregunta al revés |
| ¿Qué saldo tendría la parte 5 si el segundo escaneo no hubiera existido? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir un lote en un instante, y cuáles se deducen de
   los movimientos en lugar de guardarse?
2. Cuando dos pedidos se disputan lo último, ¿dónde queda escrito quién gana y qué se
   le dice a quien pierde?
3. ¿Cómo distingue tu gemelo «el lote no se ha vencido» de «no sé cuándo se vence»?
4. ¿Qué parte de una cadena de trazabilidad le sirve al jefe de almacén y qué parte es
   ruido para él?
5. En tu simulación en Erlang, ¿qué impedía que muchas salidas simultáneas del mismo
   artículo dejaran el saldo negativo, y qué le toca decidir al gemelo que ese mecanismo no decide?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del almacén, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar movimientos simulados
  o graficar.

## Supuestos de esta extensión

- Escala reducida: 6 números de parte, 4 ubicaciones y 3 operadores, contra los 5,000
  números de parte, 8 operadores y 2,000 movimientos por turno del original. Tú generas
  los datos.
- El «ahora» es un hecho del modelo, en minutos desde el inicio de tu ventana, no el
  reloj del sistema, para que las respuestas se puedan repetir.
- Lo siguiente es decisión tuya y debe quedar escrito como supuesto: qué prioridad tiene
  cada tipo de cliente y cómo se desempata; cuánto tiempo entre dos movimientos iguales
  los vuelve sospechosos de reintento; cuánta vida restante exige el cliente médico; qué
  pasa con un lote perecedero sin caducidad capturada; qué cuenta como «seguro» en una
  orden en camino; cuáles son la demanda, los días de entrega y la seguridad de cada
  parte; y quién autoriza un ajuste.
- Las cantidades de los ejemplos (450 piezas, pedidos de 30 y de 20, el saldo en
  cuarentena) y los identificadores («lote B», «parte 3», «pedido 7») son ilustrativos.
  Los dos clientes y la clínica son inventados.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Conteos cíclicos con frecuencia distinta según la clase ABC de la parte.
- Dos ubicaciones y un solo operador disponible para surtir pedidos urgentes.
- Retiro de producto: costo y orden de aviso a clientes según el riesgo.
- Un proveedor que entrega tarde y obliga a recalcular el punto de reorden.
- Sustituto de una parte agotada aprobado por el cliente.

---
*Las cifras de dominio (FIFO y FEFO, punto de reorden = demanda diaria × tiempo de
entrega + inventario de seguridad con el ejemplo de 400, 5,000 números de parte, 8
operadores, 2,000 movimientos por turno, las últimas 30 piezas, el 40 contra 12 del
conteo) vienen del problema original. Los demás números (la escala de 6 partes, 4
ubicaciones y 3 operadores, y los ejemplos) son de esta extensión. Verifica la fuente
vigente antes de citarlas en tu entrega.*
