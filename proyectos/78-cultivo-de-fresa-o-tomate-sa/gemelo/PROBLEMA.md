# #78 — Cultivo de fresa o tomate (San Quintín): gemelo digital con programación lógica

> Extensión del proyecto #78. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la cosecha: cuadrillas que capturan cajas, lotes, un
registro que llega tarde y una caja que se captura dos veces. Esa simulación responde
«¿cuántas cajas van y de quién son?». El rancho necesita algo más: «¿qué caja cuenta,
a quién se le paga, qué hay que retirar y por qué?».

El gemelo digital es el **modelo lógico** de la cosecha: hechos que reflejan lo que se
capturó y reglas que reflejan cómo se decide con eso. Se escribe en Prolog porque aquí
no se suma: se decide quién es elegible para qué, se sigue una caja hasta el camión y
se sabe decir «no lo sé».

## El rancho que se clona

Un rancho de San Quintín en un día de cosecha de fresa, reducido a 4 lotes, 3 cuadrillas
de 5 jornaleros, 2 cámaras de preenfriado y 2 camiones, con unas cuantas decenas de cajas.

| Parte | Contenido |
|---|---|
| Entidades | rancho → lote → surco; cuadrilla → jornalero; caja (con etiqueta QR) → tarima → camión; cámara de preenfriado |
| Personas | el mayordomo de cada cuadrilla, los jornaleros y el comprador que recibe la fruta |
| Estado por caja | lote y surco de origen, quién la cortó, cuándo se cortó, cuándo se registró, tarima, cuándo entró al frío |
| Estado por tarima y camión | qué cajas lleva, a qué cámara entró y cuándo, en qué camión salió |
| Estado por lote | surcos que lo forman, cuadrillas que cosecharon en él, si está bajo sospecha |
| Eventos | se captura una caja, llega un registro atrasado, se arma o se mezcla una tarima, entra a la cámara, se carga un camión, se declara sospechoso un lote, se retira un lote |
| Decisiones | ¿cuenta esta caja y a quién se le acredita?, ¿de qué lote es esta tarima?, ¿qué hay que retirar y a quién avisar?, ¿se enfrió a tiempo?, ¿se paga? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original: cada una retoma su escenario, sus casos difíciles,
sus preguntas guía o sus datos del mundo real, y le añade el detalle que obliga a
razonar. En cada una, tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — La misma caja, dos veces

- **Qué pasa.** La etiqueta QR de una caja aparece capturada dos veces. Puede ser el
  mismo jornalero que escaneó dos veces, una cuadrilla que la registró en papel y otra en
  el dispositivo, o dos cuadrillas que reclaman la misma caja. Como el pago es por caja,
  contar de más cuesta dinero al rancho y contar de menos se lo quita al jornalero.
- **Qué datos hay.** Las capturas con quién, dónde, hora de corte y hora de registro. Ningún
  dato dice «duplicado»; y un mismo QR en dos surcos distintos no puede ser la misma caja.
- **Qué debe deducir.** Si las dos capturas son la misma caja o dos cajas con una etiqueta
  repetida, cuál captura es la que vale, y qué hacer cuando no alcanza la información.
- **Qué debe contestar.** Qué captura cuenta, a quién se le acredita, cuál se rechaza y
  por qué. Lo intuitivo es que gane la que llegó primero al sistema; revisa si es cierto
  cuando una de las dos viajó retrasada.
- **Por qué es lógica.** Es un desempate entre reclamos que se contradicen, y «no sé cuál
  es la buena» es una respuesta distinta de «las dos valen» y de «ninguna vale».

### Situación 2 — La tarima de varios lotes

- **Qué pasa.** En el apuro, cajas de distintos lotes se acomodan en una misma tarima. La
  tarima va a una cámara y luego a un camión como una sola cosa, pero el comprador
  exige saber el lote de cada caja. Si la unidad mínima de trazabilidad es la caja,
  agruparla no puede borrarla.
- **Qué datos hay.** Qué caja se puso en qué tarima y cuándo, qué tarima entró a qué cámara
  y se cargó en qué camión. Ninguna tarima trae «su lote»; algunas cajas no tienen tarima
  registrada.
- **Qué debe deducir.** De qué lotes es una tarima, de qué lote es una caja que solo se
  conoce por su tarima, y a qué tarimas y camiones llegó cada lote.
- **Qué debe contestar.** La procedencia de la tarima como lista de lotes con las cajas
  que lo sustentan, y las cajas cuyo recorrido queda como desconocido en vez de inventar
  un lote.
- **Por qué es lógica.** La trazabilidad es una relación que se compone (caja, tarima,
  camión) y debe poder leerse hacia adelante y hacia atrás con las mismas reglas.

### Situación 3 — El lote bajo sospecha

- **Qué pasa.** Un lote queda bajo sospecha de contaminación y hay que rastrearlo. En un
  brote se retira el lote exacto y no todo el producto: retirar de menos pone en riesgo
  a quien lo coma; retirar de más tira fruta sana y rompe la confianza del comprador. Parte
  de la fruta ya salió en camiones y parte de los registros no han llegado.
- **Qué datos hay.** Lote, surcos, cuadrillas, cajas, tarimas, cámaras, camiones y la hora
  en que se declaró la sospecha. Ningún dato dice «esta caja está tocada».
- **Qué debe deducir.** Qué surcos, cajas, tarimas y camiones están alcanzados por el lote,
  cuáles quedan «posiblemente alcanzados» por un eslabón que no se registró, y qué
  compradores hay que avisar.
- **Qué debe contestar.** La lista de lo que se retira y por qué cada pieza entra, lo que
  queda en duda y qué dato faltante lo resolvería. Y la consulta al revés: de una caja,
  de qué lote viene y qué otras piezas comparten su camino.
- **Por qué es lógica.** Es una cadena de cuatro o más eslabones (lote, surco, caja,
  tarima, camión) en la que cada paso se justifica y un eslabón perdido es «no sé», no «no».

### Situación 4 — ¿Se enfrió a tiempo?

- **Qué pasa.** La fresa se preenfría a ~1-4 °C pocas horas después del corte, y cada hora
  de demora reduce su vida de anaquel. Entre el corte y el frío hay un camino: la caja
  espera en el surco, viaja, se acomoda en una tarima y entra a una cámara. Una tarima
  mezcla cajas cortadas a horas distintas, y la cuadrilla que reportó tarde parece
  haber tardado mucho cuando quizá no fue así.
- **Qué datos hay.** Hora de corte y de registro de cada caja, hora de ingreso de la tarima
  a la cámara y lecturas de temperatura de la cámara. Ningún dato mide «tiempo de espera
  de la caja».
- **Qué debe deducir.** El tiempo que cada caja esperó antes de estar de verdad en el
  frío, si cumplió el límite, y a quién corresponde la demora (campo, traslado o cámara).
- **Qué debe contestar.** Por caja, «a tiempo», «fuera de límite» o «no se sabe», con las
  horas que lo sustentan. Lo intuitivo es medir desde que el registro llegó; la hora que
  importa es otra; y revisa si estar dentro de la cámara equivale a estar frío.
- **Por qué es lógica.** El límite no se aplica a un solo número: se deduce de varias horas
  y de un estado de la cámara, y cambia de dueño según el eslabón donde se perdió el tiempo.

### Situación 5 — Pagar lo que se cortó

- **Qué pasa.** Una cuadrilla trabajó en un lugar sin señal y sus registros llegan tres
  horas después. Al mismo tiempo, parte de lo que cortó puede ser duplicado, estar en un
  lote retenido o haberse enfriado fuera de límite. El jornalero cortó la fruta y su
  trabajo es real; el rancho no puede cobrar fruta que no se vende. Los dos tienen razón.
- **Qué datos hay.** Capturas, quién las hizo, hora de corte, hora de registro, estado del
  lote y resultado del enfriamiento. Ningún dato dice «esta caja se paga».
- **Qué debe deducir.** Si un registro tardío es aceptable o no, qué cajas de cada jornalero
  son pagables ya, cuáles quedan retenidas esperando un dato y cuáles se pagan o no según
  de quién fue la causa.
- **Qué debe contestar.** Por jornalero y por cuadrilla, qué se paga, qué se retiene y por
  qué, con la regla que decidió; y en el choque entre el jornalero y el rancho, a quién se
  le falla y quién absorbe la pérdida.
- **Por qué es lógica.** La elegibilidad depende de condiciones que se encadenan (registro
  válido, no duplicada, lote sin retiro, causa de la pérdida) y las prioridades se declaran
  una vez para todos los casos.

## Por qué no basta un script

Con `if qr in registradas: ignorar()` resuelves una caja con datos perfectos y una sola
cuadrilla. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Se paga la caja 17, y a quién? | decisión |
| ¿Por qué no se pagó? | explicación |
| ¿Qué cajas y camiones alcanza el lote sospechoso? | todas las respuestas |
| ¿Qué dato falta para pagar o retirar esta tarima? | la pregunta al revés |
| ¿Qué pasaría si se declara sospechoso otro lote? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Cuál es la unidad mínima de trazabilidad y qué hechos la mantienen al agrupar?
2. ¿Qué vuelve válido a un registro capturado tarde y sin conexión?
3. Cuando dos capturas se contradicen, ¿dónde queda escrito cuál gana?
4. ¿Cómo distingue tu gemelo «no está en el lote» de «no sé si está en el lote»?
5. ¿Qué parte de tu simulación en Erlang (captura de cajas, trazabilidad por lote, prueba de
   caos de la captura duplicada) podría alimentar a este gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la cosecha, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar capturas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 4 lotes, 3 cuadrillas de 5 jornaleros, 2 cámaras, 2 camiones y unas
  decenas de cajas, contra los 10 lotes, 12 cuadrillas de 30 personas y 5,000 cajas por
  jornada del escenario original.
- El «ahora» es un hecho del modelo, en minutos desde el inicio de la jornada, no el reloj
  del sistema, para que las respuestas se puedan repetir.
- Los surcos de cada lote, qué cuadrilla cosecha dónde y la forma de las tarimas son
  datos que tú defines en el escenario.
- El original dice «pocas horas» para el preenfriamiento y no da un límite exacto: el
  tiempo máximo entre corte y frío es decisión tuya y lo anotas como supuesto.
- Tampoco da cuánto retraso es aceptable para un registro tardío (solo ejemplifica tres
  horas), cuánto tiempo sin señal vuelve dudosa una captura, ni el orden de prioridad
  entre pagar al jornalero y proteger al rancho: los fijas tú.
- Los identificadores de los ejemplos (cajas, tarimas, camiones) son del ejercicio.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Pago por kilo contra pago por caja: qué cambia en la elegibilidad.
- Certificaciones y auditoría del comprador: qué evidencia hay que poder mostrar.
- Simulacro de retiro: cuánto tardaría en responderse a un lote sospechoso.
- Reclamo del comprador por una tarima y reparto de la pérdida.

---
*Las cifras son de referencia y vienen del problema original. Verifica la fuente vigente
antes de citarlas en tu entrega.*
