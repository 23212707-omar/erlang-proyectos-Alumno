# #71 — Protección civil: gemelo digital con programación lógica

> Extensión del proyecto #71. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la respuesta a un evento: un proceso por albergue con su
capacidad y su ocupación, un inventario de suministros, el estado del evento y un
asignador de damnificados. Esa simulación responde «¿cuántas personas hay y qué queda?».
Quien coordina necesita algo más: «¿a dónde mando a esta familia, qué insumo mueve y a
quién le falla mi decisión?».

El gemelo digital es el **modelo lógico** de la red de albergues: hechos que reflejan su
estado (personas, espacio, insumos, qué se sabe y de cuándo) y reglas que reflejan cómo
se decide en una crisis. Se escribe en Prolog porque lo que hay que resolver aquí no es
sumar existencias, sino repartir lo escaso entre albergues, justificar a quién se le
falla y saber decir «no lo sé» cuando la información es vieja o falta.

## La red de albergues que se clona

Los albergues de una ciudad de Baja California tras un deslave o una lluvia torrencial,
reducidos a 4 albergues, unas 12 familias y unos 8 insumos.

| Parte | Contenido |
|---|---|
| Entidades | evento → albergue → familia → persona; insumos; rutas entre albergues |
| Estado por albergue | espacio techado, sanitarios, atención médica (sí o no), existencia por insumo con el instante del último conteo, si tiene conexión |
| Estado por persona | familia, condición (adulto mayor, embarazada, medicación continua, bebé, ninguna), dónde consta y desde cuándo |
| Eventos | llega un grupo, una persona entra o sale, se transfiere un insumo, una donación llega, un albergue pierde o recupera la conexión, se sincroniza |
| Decisiones | ¿a qué albergue va cada familia?, ¿dónde está esta persona?, ¿qué insumo se mueve y de dónde a dónde?, ¿cuánto dura lo que hay?, ¿qué versión de un albergue es la que vale? |

## Situaciones que tu gemelo debe razonar

Cuatro de las cinco salen del problema original (la 1, la 2, la 3 y la 4). La quinta
parte de sus datos del mundo real sobre necesidades especiales y plantea algo nuevo. En
cada una, tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — El autobús que no cabe

- **Qué pasa.** Tras un deslave, un grupo grande llega de golpe a un albergue ya a media
  capacidad (el original plantea 200 personas de repente). Otros tienen lugar, pero cada
  familia quiere seguir junta. Si el reparto falla, hay gente afuera o sin sanitario.
- **Qué datos hay.** Espacio techado, sanitarios y agua de cada albergue; quién ya está;
  las familias que llegan. Estándares del original: unos 3.5 m² techados y 15 litros de
  agua al día por persona, y un sanitario por 20 personas.
- **Qué debe deducir.** Cuántas personas más admite cada albergue ahora, y qué reparto de
  familias respeta a la vez lo que cada albergue puede sostener.
- **Qué debe contestar.** Un reparto completo y todos los demás que sean válidos; qué
  familias se separan si no hay otra forma; y, por cada albergue que no recibe a una
  familia, qué se acabaría primero (espacio, sanitarios o agua).
- **Por qué es lógica.** Ningún albergue tiene un cupo escrito: el cupo es consecuencia
  de varias restricciones a la vez y cambia con cada persona que entra. Lo obvio, mandar
  a todos al que tiene más metros libres, puede mandarlos al que se queda sin sanitarios
  primero.

### Situación 2 — ¿Dónde está doña Lupita?

- **Qué pasa.** Un familiar llama buscando a una señora. Hay un registro en un albergue y
  otro, con el nombre escrito distinto y otra edad, en un segundo albergue. Son registros
  en papel, algunos capturados horas después. Si es la misma, el sistema la cuenta y le
  aparta agua dos veces.
- **Qué datos hay.** Registros con nombre, edad, familia declarada, albergue e instante;
  entradas y salidas; el instante en que cada dato llegó.
- **Qué debe deducir.** Si dos registros son la misma persona, dos personas distintas o
  no se sabe; y dónde está ahora, según lo último que consta (entrada, salida, traslado),
  distinguiendo cuándo ocurrió algo de cuándo se anotó.
- **Qué debe contestar.** Dónde está y con qué evidencia. Si no se puede saber, «no lo
  sé» con lo que haría falta confirmar y con quién. Y el conteo de personas del evento,
  sin contar dos veces a quien es la misma ni una sola a quienes son dos.
- **Por qué es lógica.** Quién es quién se infiere de evidencia parcial; decir «está en el
  albergue A» sin saber manda a la familia a un lugar vacío, y fusionar mal dos registros
  borra a una persona.

### Situación 3 — El agua que sobra aquí y falta allá

- **Qué pasa.** Un albergue tiene mucha agua en litros, pero hoy el doble de gente que
  ayer. Otro tiene poca, pero casi vacío. El reabasto tarda y coordinación quiere mover
  agua de «el que más tiene» a «el que menos tiene». Parte de la bodega son donaciones
  que no son lo esencial, como la ropa que sobra.
- **Qué datos hay.** Existencia con el instante del conteo, personas presentes, consumo
  por persona con sus cambios, traslado entre albergues y cuándo se espera el reabasto.
- **Qué debe deducir.** Cuántos días de agua (y de otros esenciales) le quedan a cada
  albergue, quién se queda sin ella antes del reabasto, y si una transferencia deja peor
  a alguien, donante incluido, mientras la carga viaja.
- **Qué debe contestar.** Qué mover, cuánto y de dónde a dónde; qué albergue queda en
  riesgo y en cuántas horas; o que no hay forma de cubrir a todos, con las alternativas.
  Aquí dos partes tienen razón (el que ya está en crisis y el donante que entraría en la
  suya): la regla decide y dice a quién se le falla y por qué.
- **Por qué es lógica.** Los días de agua no están en ningún sensor: se encadenan
  personas presentes, consumo, existencia y tiempo. Quien tiene más litros no es quien
  tiene más días.

### Situación 4 — Seis horas sin conexión

- **Qué pasa.** Un albergue pierde la conexión seis horas. Sigue recibiendo gente y
  consumiendo, mientras la central, que lo ve como estaba, le sigue asignando familias.
  Al volver la señal hay dos versiones del mismo albergue.
- **Qué datos hay.** El último conteo con su instante, los eventos de desconexión y
  sincronización, lo registrado localmente y lo que la central decidió mientras tanto.
- **Qué debe deducir.** Durante el apagón, qué se puede afirmar del albergue (no su
  ocupación exacta, sino lo que pudo haber pasado). Al reconectar, qué versión de cada
  hecho es la que vale y qué asignaciones de la central resultan inválidas.
- **Qué debe contestar.** Durante el apagón, ¿se le manda más gente?: sí, no o no se sabe,
  con el motivo. Al volver, el estado reconciliado, los hechos en conflicto y por qué
  prevalece uno. Lo intuitivo, «gana la versión más reciente», es sospechoso: cada
  versión tiene hechos que la otra nunca vio.
- **Por qué es lógica.** Reconciliar es razonar sobre qué hechos son compatibles entre sí;
  un albergue sin noticias no tiene ocupación cero, tiene ocupación desconocida.

### Situación 5 — El último lugar con médico

- **Qué pasa.** Solo un albergue tiene atención médica y le queda un lugar. Piden entrar
  una embarazada y un adulto mayor con medicación continua; a otro adulto mayor no se le
  capturó si toma medicación. La medicina de alguien se acaba antes del reabasto y nada
  lo marca como urgencia.
- **Qué datos hay.** Condiciones declaradas (o ausentes), insumo que necesita cada
  persona, su existencia, atención de cada albergue y tiempos de traslado.
- **Qué debe deducir.** Quién necesita estar en un albergue con atención, quién puede ir
  a otro si su insumo viaja con ella, y para quién la medicina no dura hasta el reabasto.
- **Qué debe contestar.** La asignación y el orden de atención, con la razón de cada uno;
  a quién se le falla el último lugar y por qué; y, de la condición no capturada, «no se
  sabe, hay que preguntar», nunca un sí ni un no por omisión.
- **Por qué es lógica.** Es elegibilidad con límites y desempate: la decisión solo vale si
  puede justificarse ante quien se queda fuera.

## Por qué no basta un script

Con `if ocupacion < capacidad: asignar(familia, albergue)` resuelves un albergue con una
capacidad escrita y datos al día. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿A dónde va la familia Ríos? | decisión |
| ¿Por qué no al albergue Norte? | explicación |
| ¿En qué albergues cabe hoy esa familia completa? | todas las respuestas |
| ¿Qué tendría que cambiar para que quepa en Norte? | la pregunta al revés |
| ¿Qué pasaría si llegan cincuenta personas más al Sur, o si el reabasto se retrasa? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir un albergue en un instante, y cuáles de ellos
   pueden estar viejos?
2. ¿Qué información tiene que seguir disponible sin internet, y qué hace tu gemelo con la
   que ya no puede confirmar?
3. Cuando dos versiones de un albergue se contradicen, ¿dónde queda escrito cuál hecho
   vale?
4. ¿Cómo distingue tu gemelo «no cabe» de «no sé si cabe»?
5. ¿Qué parte de tu simulación en Erlang (el asignador, la prueba de albergue lleno o la
   de albergue sin conexión) podría alimentar a este gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la red de albergues, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar llegadas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 4 albergues, unas 12 familias y unos 8 insumos, contra los 5 albergues,
  1,200 personas en 72 h y 40 insumos del escenario original. El grupo que llega de golpe
  se fija en proporción a esa escala.
- El «ahora» es un hecho del modelo (horas desde que abre el evento), no el reloj del
  sistema, para que las respuestas se puedan repetir.
- Los nombres y las cantidades de los ejemplos son inventados para el ejercicio.
- Tú defines el espacio, los sanitarios, las existencias y los traslados de cada albergue;
  cuándo llega el reabasto; cuántas horas de agua deben quedar para decir que «alcanza»;
  qué tan parecidos deben ser dos nombres para sospechar que son uno; y desde cuándo un
  dato es viejo.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Traslado de damnificados entre albergues y puntos de reunión por rutas posibles.
- Reabasto: a quién se le pide qué primero y desde dónde.
- Riesgo sanitario por hacinamiento o falta de sanitarios.
- Cierre de un albergue (una escuela que debe reabrir) y a dónde van sus personas.

---
*Las cifras son de referencia y vienen del problema original. Verifica la fuente vigente
antes de citarlas en tu entrega.*
