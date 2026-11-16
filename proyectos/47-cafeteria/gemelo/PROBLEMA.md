# #47 — Cafetería: gemelo digital con programación lógica

> Extensión del proyecto #47. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la cafetería: un proceso por pedido que pasa de recibido a
preparando, listo y entregado, una cocina con su cola y un estimador de tiempo. Esa
simulación responde «¿cuánto va a tardar?». Quien atiende la barra, y el alumno que tiene
media hora de descanso, necesitan algo más: «¿qué le prometo, a quién atiendo primero, qué
hago con lo que ya se pagó, y por qué?».

El gemelo digital es el **modelo lógico** de la cafetería: hechos que reflejan lo que hay
en cocina y en la fila, y reglas que reflejan cómo se decide en ella. Se escribe en Prolog
porque aquí no se calcula un promedio: se deduce qué se puede surtir, se justifica a
quién se le falla y se distingue «no hay» de «no sé si hay».

## La cafetería que se clona

Una cafetería escolar con descanso de 40 minutos, reducida a 3 estaciones de cocina, unos
8 productos, 2 combos y una docena de pedidos. Es una simulación planteada por el problema
original; lo que se añade (combos, conteos de existencias, avisos con estado) está
marcado en las situaciones.

| Parte | Contenido |
|---|---|
| Entidades | cafetería → estación de cocina → producto; combos formados por productos; clientes; pedidos con sus líneas |
| Estado por pedido | origen (anticipado o mostrador), líneas, medio y estado del pago, tiempo prometido, etapa (recibido, preparando, listo, entregado), aviso al cliente |
| Estado por estación y producto | cola de cada estación, tiempo de preparación (rango), existencias contadas y cuándo se contaron, pedidos que ya las tienen apartadas |
| Estado por cliente | cuánto le queda de su descanso, saldo según el monedero de la escuela |
| Eventos | llega un pedido; el pago se confirma o se rechaza; un producto se agota («86»); una estación se retrasa; se avisa al cliente; se recoge o no |
| Decisiones | ¿se acepta?, ¿qué se promete?, ¿quién pasa primero?, ¿qué se hace con lo pagado que no se puede surtir?, ¿qué se hace con lo que nadie recoge? |

## Situaciones que tu gemelo debe razonar

Cuatro parten del problema original; la quinta toma del original los medios de pago y le
suma un conflicto que el original no plantea. Los combos vienen del foco asignado al
proyecto y aparecen en varias situaciones. En cada una, tu gemelo debe llegar a una
decisión **y poder explicarla**.

### Situación 1 — El producto que está en el refri y ya no existe

- **Qué pasa.** El platillo más popular se agota a los 15 minutos, dice el original. Pero
  en la cocina aún quedan unidades físicas: todas apartadas para pedidos pagados que
  esperan turno. Entra un pedido con un combo que lleva ese platillo, y un pedido más
  viejo, también pagado, queda sin su platillo porque la última unidad se usó en otro
  anterior. Alguien contó las existencias hace un rato; nadie sabe cuánto ha cambiado.
- **Qué datos hay.** Conteos de existencias con el instante en que se hicieron, pedidos
  con sus líneas, qué productos forman cada combo, pagos con su medio y estado, y qué
  pedidos ya están en preparación. Ningún dato dice «disponible».
- **Qué debe deducir.** En cadena: cuántas unidades se pueden prometer de verdad, qué
  combos aún se completan, qué pedidos pagados ya no se surten completos, en qué orden se
  les falla y qué salidas admite cada uno.
- **Qué debe contestar.** Por pedido: se puede surtir, se puede surtir con un cambio, o no
  se puede; si el conteo es demasiado viejo para fiarse, «no se sabe» y qué recontar. Y
  si se debe seguir aceptando pedidos con ese producto. Lo intuitivo es «si hay una unidad
  en la cocina, hay producto»; es sospechoso porque esa unidad ya tiene dueño.
- **Por qué es lógica.** La disponibilidad no es un dato: se deduce de existencias,
  compromisos y composición de combos. Y pierde el alumno que pagó, o la cafetería.

### Situación 2 — La promesa de los cinco minutos

- **Qué pasa.** Un cliente pide un combo con café (1 min), torta (4-5 min) y comida
  caliente (6-10 min), que se preparan en estaciones distintas. La cocina se retrasa y las
  promesas ya hechas dejan de cumplirse: «si dices 5 min y tardas 12, pierdes confianza».
- **Qué datos hay.** Rango de preparación de cada producto, qué estación lo prepara, los
  pedidos que esperan en cada estación y en qué punto va cada uno, la promesa hecha a
  cada pedido y el descanso que le queda al cliente. Nada dice «cuándo estará listo».
- **Qué debe deducir.** Cuándo estaría completo cada pedido en el mejor y en el peor caso,
  contando que un combo no está listo hasta que lo esté su última parte; qué promesas ya
  son imposibles y cuáles están en riesgo.
- **Qué debe contestar.** Qué prometer a un pedido nuevo y por qué ese tiempo; qué pedidos
  hay que re-prometer ahora; y si la promesa cabe en el descanso del cliente: sí, no o
  «no se sabe». Lo intuitivo es dividir la fila entre la tasa de atención; eso describe al
  sistema entero, no a este pedido, que depende de las estaciones que usa.
- **Por qué es lógica.** El tiempo honesto sale de varios datos, uno por estación y por
  rango, y su respuesta natural no es un número sino «seguro, probable o posible».

### Situación 3 — Quién pasa primero

- **Qué pasa.** La estación de comida caliente se satura. Esperan un pedido anticipado que
  ya pasó su tiempo prometido, uno de mostrador cuyo cliente tiene el descanso por
  terminar, un pedido grande de varios combos y un café que se resolvería en un minuto.
  Hay otra estación con menos carga. Todos tienen derecho a algo; no todos lo reciben.
- **Qué datos hay.** Orden de llegada, origen del pedido, promesa hecha, descanso restante
  del cliente, tamaño y tiempo de preparación, carga de cada estación y qué productos
  puede preparar cada una.
- **Qué debe deducir.** Cuáles pedidos aún pueden salvar su promesa y cuáles ya no; qué
  componentes se pueden pasar a otra estación y cómo mueve eso las promesas de los demás.
- **Qué debe contestar.** El orden de atención, a quién se le rompe la promesa y por qué a
  él; y qué tendría que cambiar (una estación libre, un pedido cancelado) para que nadie
  quede fallado. Ni «por orden de llegada» ni «lo más rápido primero» bastan por sí solos.
- **Por qué es lógica.** Los criterios de desempate se declaran una vez, y el cliente que
  pregunta «¿por qué él y no yo?» recibe la misma explicación que el encargado de la barra.

### Situación 4 — El pedido que nadie recoge

- **Qué pasa.** Un pedido está listo y el cliente no aparece (caso difícil del original).
  Se mandó el aviso, pero no consta que llegara: el teléfono estaba sin señal. El
  descanso avanza, el pedido ocupa la barra y, mientras tanto, otro cliente espera ese
  mismo producto porque su pedido pagado quedó sin surtir (situación 1).
- **Qué datos hay.** Instante en que quedó listo, avisos con su estado (enviado,
  confirmado), medio de pago, descanso del cliente y los demás pedidos que esperan ese
  producto.
- **Qué debe deducir.** Si el cliente no recoge o simplemente no se enteró; si el pedido
  sigue siendo suyo; si su unidad puede asignarse a quien la espera.
- **Qué debe contestar.** Conservar, reasignar o dar por perdido, y qué se le debe al
  cliente según cómo pagó y si el aviso consta. Si no consta, «no se sabe». Lo intuitivo
  es «no vino, es abandono»; pero si el aviso nunca llegó, a quien se le falló fue a él.
- **Por qué es lógica.** «No recogió» y «no supo» no son lo mismo y ningún dato dice cuál
  ocurrió: se deduce de lo que sí consta, y lo que sobra aquí puede resolver otra falta.

### Situación 5 — El monedero que no se pone de acuerdo con la cocina

- **Qué pasa.** Los pagos son en efectivo, tarjeta o saldo del monedero escolar. Una
  alumna manda desde el teléfono dos pedidos casi a la vez, uno de ellos un combo para un
  amigo, y su saldo alcanza para uno solo. El monedero es de la escuela y confirma después;
  la cocina ya recibió los dos y empezó el primero. Otro cliente paga con tarjeta y el
  rechazo llega cuando su torta ya está lista.
- **Qué datos hay.** Pedidos con su medio de pago y su estado (pendiente, confirmado,
  rechazado) con su instante, el saldo según el monedero y cuándo se leyó, y en qué punto
  va cada pedido en cocina.
- **Qué debe deducir.** Qué pago respalda a qué pedido, cuáles pedidos quedan sin respaldo,
  y qué cuesta cada salida: parar lo no pagado, preparar a riesgo o retener hasta que el
  pago se confirme.
- **Qué debe contestar.** Por pedido: preparar, retener o cancelar, quién asume el costo
  (la cafetería si ya preparó, la clienta si pierde su turno) y, mientras el pago esté
  pendiente, «no se sabe» en lugar de adivinar.
- **Por qué es lógica.** Dos sistemas dicen cosas distintas (la cocina: «en preparación»;
  el monedero: «pendiente») y la regla decide a cuál creerle y cuánto riesgo tomar.

## Por qué no basta un script

Con `if existencias == 0: marcar_agotado()` resuelves un producto con un conteo perfecto.
Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué hago con el pedido 9? | decisión |
| ¿Por qué el pedido 9 pasa antes que el 7? | explicación |
| ¿Qué pedidos pagados no se pueden surtir completos? | todas las respuestas |
| ¿Qué tendría que pasar para que el combo del pedido 9 salga a tiempo? | la pregunta al revés |
| ¿Qué pasaría si la torta se agota ahora? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Cuál es la mejor estimación del tiempo de un pedido que recién entra? ¿Cuándo debe
   decir tu gemelo «no sé» en lugar de dar un número?
2. ¿Qué haces con un pedido cuando se acaba un ingrediente? ¿Dónde queda escrito qué
   cambios son admisibles y a quién se le devuelve qué?
3. Cuando dos pedidos compiten por el mismo turno, ¿dónde queda escrito quién gana y cómo
   se lo explicas al que pierde?
4. ¿Cómo distingue tu gemelo «no recogió» de «no se enteró»?
5. ¿Qué eventos de tu simulación en Erlang (etapas del pedido, cola de la cocina,
   estimador, productos agotados) podrían alimentar a este gemelo como hechos?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la cafetería, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar pedidos simulados o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 3 estaciones (como el original), unos 8 productos, 2 combos y una
  docena de pedidos, contra los 400 pedidos, 30 productos y 40 minutos del escenario
  original.
- El «ahora» es un hecho del modelo, en minutos, no el reloj del sistema. Los
  identificadores de los ejemplos («pedido 9», «pedido 7») son ilustrativos.
- Los combos y su composición, los conteos de existencias con su instante, los avisos con
  estado, el descanso restante de cada cliente y el saldo del monedero son complementos de
  esta extensión, no del original.
- Los define y verifica el estudiante, porque el original no los da: el tiempo exacto de
  cada producto dentro de su rango, cuánto margen lleva una promesa, qué cambios de
  componente se aceptan, el criterio de prioridad y el de desempate, qué tan viejo debe ser
  un conteo para no creerle, cuánto esperar antes de dar un pedido por no recogido y cuántos
  pedidos atiende a la vez una estación.

## Extensiones posibles

Fuera del problema original: investiga y cita tus fuentes antes de fijar cifras.

- Un ingrediente compartido entre varios productos que se acaba a media preparación.
- Alergias y restricciones alimentarias que vuelven inadmisible un cambio de componente.
- Pedidos de grupo con un solo pago y varios clientes que recogen por separado.
- Devoluciones y compensaciones cuando se rompe una promesa.

---
*Las cifras (descanso de 30 a 45 minutos, mostrador de 1 a 2 clientes por minuto, unos 10
clientes por minuto con 400 personas en 40 minutos, 60 personas con 10 por minuto y 6
minutos, café de 1 min, torta de 4-5 min, comida caliente de 6-10 min, 400 pedidos, 3
estaciones, 30 productos, producto popular agotado a los 15 minutos) son de referencia y
vienen del problema original. Verifica la fuente vigente antes de citarlas en tu entrega.*
