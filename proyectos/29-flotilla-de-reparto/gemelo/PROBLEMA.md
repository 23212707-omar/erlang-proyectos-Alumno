# #29 — Flotilla de reparto: gemelo digital con programación lógica

> Extensión del proyecto #29. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la flotilla: un proceso por unidad con su posición y su
carga, un despachador que asigna, un proceso por entrega que pasa de pendiente a en ruta,
entregada o fallida, y una prueba de caos en la que una unidad se calla y sus entregas se
reasignan. Esa simulación responde «¿qué está pasando con la flotilla?». El despachador
necesita algo más: «¿a qué unidad paso cada entrega, en qué orden, y por qué a ella?».

El gemelo digital es el **modelo lógico** de la flotilla: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque lo que hay que
resolver aquí no es hallar la ruta perfecta (el problema clásico de ruteo es NP-difícil y
no se busca el óptimo), sino repartir sin dejar entregas huérfanas ni duplicadas, respetar
capacidad y ventanas, justificar a quién se le falla y saber cuándo no se sabe.

## La flotilla que se clona

Una empresa local de reparto de la región fronteriza, reducida a 4 unidades, 14 entregas y
un mapa de 8 puntos unidos por tramos. El tiempo se cuenta en minutos desde el inicio de
la jornada.

| Parte | Contenido |
|---|---|
| Entidades | unidad (con su conductor), entrega, punto del mapa, tramo entre dos puntos |
| Estado por unidad | último punto reportado y su hora, estado de motor, capacidad de peso y de volumen, carga a bordo, minutos al volante, entregas asignadas en orden |
| Estado por entrega | punto de entrega, peso y volumen, ventana (por ejemplo «entre 2 y 4 pm»), normal o urgente, estado (pendiente, en ruta, entregada, fallida), unidad asignada |
| Estado por tramo | tiempo base y tiempo observado con tráfico |
| Eventos | llega una lectura de GPS, una unidad se avería o se calla, llega un reporte en lote, entra un pedido urgente, una entrega se entrega o falla, un tramo se vuelve lento |
| Decisiones | ¿a qué unidad pasa cada entrega y en qué orden?, ¿cabe?, ¿llega a su ventana?, ¿se reasigna ya o se espera?, ¿a quién se le falla? |

## Situaciones que tu gemelo debe razonar

Las cinco parten del problema original (unidad averiada con entregas pendientes, pedido
urgente, conductor sin señal, hora de llegada con tráfico variable, entrega fallida);
algunas añaden complementos derivados del foco «reasignar entregas con ventanas y
capacidad». En cada una, tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — La unidad averiada y sus entregas en el aire

- **Qué pasa.** A las 11 a. m. una unidad se avería con entregas pendientes (en el
  original, 40 de las 900 del día). Hay que pasarlas a otras unidades sin dejar ninguna
  huérfana ni duplicada. Las demás ya van con carga, rutas y ventanas prometidas. Un
  paquete huérfano es un cliente sin entrega; uno duplicado, dos unidades gastando una
  parada. Y los paquetes siguen dentro de la unidad averiada: nadie puede entregarlos
  hasta que alguien pase a recogerlos.
- **Qué datos hay.** Las entregas de la unidad averiada con su estado, ventana, peso y
  volumen; capacidad y carga de las demás; dónde quedó la averiada; los tramos con sus
  tiempos; los minutos al volante de cada conductor.
- **Qué debe deducir.** Cuáles de sus entregas siguen realmente pendientes, qué unidades
  pueden pasar a recogerlas, cuáles absorben su peso Y su volumen, cuáles lo hacen sin
  romper ventanas ya prometidas ni rebasar las horas máximas de manejo, y qué reparto
  cubre cada entrega exactamente una vez. Cada paso depende del anterior.
- **Qué debe contestar.** El reparto con su explicación; todos los repartos válidos si se
  piden; qué entregas ajenas hubo que tocar para hacer espacio (lo que no necesitaba
  cambiar no cambia: no se recalcula todo el día); y, si no existe ninguno, qué entregas
  quedan sin cubrir y qué restricción lo impide.
- **Por qué es lógica.** Exactamente una unidad por entrega, capacidad en dos medidas y
  ventanas son restricciones simultáneas sobre un reparto completo, y el resultado
  recorre una red de tramos.

### Situación 2 — El pedido urgente que retrasa a otros

- **Qué pasa.** A media jornada entra un pedido urgente. Varias unidades podrían tomarlo,
  pero cada una lleva clientes con ventanas ya prometidas, y meter el urgente en su ruta
  retrasa a los que siguen. Un cliente espera con prisa; otros esperan con una promesa.
  Los dos tienen razón y alguien se queda mal.
- **Qué datos hay.** Posición actual de cada unidad, su ruta pendiente con las ventanas,
  carga libre, tiempos de tramo y el plazo del pedido urgente.
- **Qué debe deducir.** Para cada unidad, cuánto retrasa el urgente a cada entrega que le
  sigue y si alguna se sale de su ventana; qué unidades lo toman sin romper ninguna
  promesa; y, si ninguna, a quién se le rompe y por cuánto. Nada de eso lo mide un dato.
- **Qué debe contestar.** La unidad elegida y el lugar del urgente en su ruta; si hay que
  fallarle a alguien, a quién y cuánto retraso; y qué tendría que cambiar para no fallarle
  a nadie. Lo intuitivo es dárselo a la unidad más cercana a su punto; es sospechoso
  porque lo que cuenta es lo que el desvío le hace a las entregas que siguen.
- **Por qué es lógica.** Es un dilema: la regla debe decidir y justificar a quién se le
  falla, y esa prioridad se declara una vez para todos los pedidos.

### Situación 3 — La unidad que se calló una hora

- **Qué pasa.** Un conductor pasa una hora sin señal por un hueco de cobertura y luego
  reporta todo junto. Mientras tanto, el despachador no sabe si la unidad se averió, si
  está en un hueco o si entrega con normalidad. Si reasigna y ella sí entregó, se
  duplican paquetes; si espera y se averió, los clientes pierden su ventana. Lo intuitivo
  es tratar el silencio como avería y reasignar todo, o esperar a que reporte; ambas son
  sospechosas, porque no todas sus entregas tienen el mismo veredicto.
- **Qué datos hay.** La última lectura y su hora, el estado de motor en esa lectura, la
  ruta asignada con sus ventanas, los tiempos de tramo y, cuando llega, el reporte en
  lote con la hora en que ocurrió cada cosa (no la hora en que llegó).
- **Qué debe deducir.** En qué puntos de su ruta pudo estar la unidad y qué entregas pudo
  haber cumplido, entrega por entrega; y qué veredictos cambian cuando el reporte corrige
  el pasado.
- **Qué debe contestar.** Tres respuestas por entrega: «se entregó», «no se entregó» y
  «no se sabe». Para las dudosas, qué dato las resolvería; qué se reasigna ya y qué se
  espera; y, tras el reporte, cuáles entregas quedaron duplicadas o huérfanas por una
  decisión ya tomada.
- **Por qué es lógica.** «No entregó» y «no sé si entregó» no son lo mismo, y un hecho que
  llega tarde cambia las conclusiones sin cambiar las reglas.

### Situación 4 — ¿Llega a su ventana con este tráfico?

- **Qué pasa.** Un cliente espera «entre 2 y 4 pm». La hora de llegada depende de los
  tramos que faltan, del tráfico, de las paradas anteriores (de 2 a 5 minutos cada una) y
  de las horas máximas del conductor. Lluvia o un cruce vuelven lento un tramo que
  comparten varias rutas a la vez. Una ventana perdida es una entrega fallida, más costo y
  un cliente molesto; un conductor sin horas es un riesgo en la calle.
- **Qué datos hay.** Tiempo base y velocidad observada de cada tramo, las paradas
  pendientes de cada unidad, la duración de una parada como intervalo, los minutos al
  volante y la ventana de cada entrega.
- **Qué debe deducir.** La llegada estimada a cada parada, encadenando tramos y paradas
  anteriores; qué rutas pasan por el tramo lento y qué entregas suyas quedan en riesgo; y
  si el conductor alcanza a terminar dentro de sus horas. «Llegará tarde» no lo mide
  nadie.
- **Qué debe contestar.** Por entrega, tres veredictos: llega en ventana de todos modos,
  llega tarde de todos modos, o depende de cuánto dure cada parada. Con la explicación de
  por qué tramo y por qué parada, y si hay una ruta alterna que lo cambie. Lo intuitivo es
  mirar cuántas paradas le quedan a la unidad; lo que cuenta es por dónde pasa.
- **Por qué es lógica.** La llegada nace de encadenar piezas sobre una red, y «¿qué rutas
  toca este tramo?» es una pregunta al revés sobre los mismos hechos.

### Situación 5 — La entrega fallida que sigue a bordo

- **Qué pasa.** Entre 5 y 15 % de las entregas fallan: cliente ausente, dirección mala. El
  paquete fallido no desaparece: sigue en la unidad, ocupando peso y volumen, y debe
  reprogramarse. La capacidad que una unidad parecía tener libre ya no lo es justo cuando
  hay que absorber una reasignación o un urgente. Si la dirección es mala, ni siquiera hay
  un punto del mapa al que ir.
- **Qué datos hay.** Los eventos de entrega fallida con su motivo, la carga a bordo, la
  capacidad de peso y de volumen, las rutas pendientes y la ventana nueva que el escenario
  ofrece para el reintento.
- **Qué debe deducir.** La capacidad libre real de cada unidad contando los fallidos a
  bordo; qué unidad pasa por el punto de un reintento sin romper ventanas; y cuándo una
  entrega no es ubicable, de modo que no se sabe a dónde mandarla.
- **Qué debe contestar.** Para cada fallida: reintento hoy con tal unidad y en tal lugar de
  su ruta, regreso al almacén, o «no ubicable» con lo que falta para ubicarla. Y qué
  decisiones de las situaciones 1 y 2 cambian por la carga que no estaba contada.
- **Por qué es lógica.** Lo que «sobra» en una unidad se deduce de lo que quedó dentro, no
  se mide; un solo hecho nuevo, la fallida, cambia veredictos en otras situaciones.

## Por qué no basta un script

Con `if unidad.averiada: reasignar_a_la_mas_cercana(unidad.entregas)` resuelves una
avería con datos perfectos y sin ventanas. Tu gemelo debe contestar, **con las mismas
reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿A qué unidad paso la entrega 9? | decisión |
| ¿Por qué a ella y no a la unidad 2? | explicación |
| ¿De cuántas formas puedo repartir las pendientes de la unidad 3? | todas las respuestas |
| ¿Qué tendría que cambiar para que el urgente no retrase a nadie? | la pregunta al revés |
| ¿Qué pasa si el tramo del puente sigue lento? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué significa «entrega asignada» en tus hechos y cómo pasa de una unidad a otra sin
   estar en las dos ni en ninguna?
2. ¿Cuándo conviene una solución buena y rápida sobre una perfecta y lenta? ¿Qué le pides
   a tu gemelo: un reparto válido o todos?
3. ¿Cómo distingue tu gemelo «no entregó» de «no sé si entregó»?
4. ¿Qué parte de la explicación le sirve al despachador y qué parte es ruido?
5. ¿Qué procesos de tu simulación en Erlang (la unidad, el despachador, la entrega)
   podrían alimentar a este gemelo con sus hechos?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la flotilla, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar lecturas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 4 unidades, 14 entregas y 8 puntos de mapa, contra las 15 unidades y
  900 entregas del escenario original. En esa escala no hace falta una lectura de GPS cada
  10 s: decides cuántas lecturas caben en tu escenario.
- El mapa, los tramos y sus tiempos, los pesos, volúmenes, capacidades, ventanas, el tope
  de horas de manejo y la ventana nueva de un reintento son datos inventados que defines
  tú. No son cifras de una empresa real.
- El «ahora» es un hecho del modelo, en minutos desde el inicio de la jornada, no el reloj
  del sistema. A qué hora empieza la jornada lo fijas tú.
- Quedan a decisión del estudiante: cuánto silencio vuelve dudosa a una unidad, cuántos
  minutos al volante son el máximo, cuánto retraso tolera una ventana (si alguno), cuánto
  cuesta fallarle a un cliente frente a otro y cuánto tarda recoger los paquetes de una
  unidad averiada.
- Los identificadores de los ejemplos («entrega 9», «unidad 2», «el puente») son
  ilustrativos.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Ventanas blandas con penalización y clientes con prioridad por contrato.
- Autonomía de combustible o batería y puntos de carga en la ruta.
- Transferir paquetes entre dos unidades a medio camino.
- Devoluciones y recolecciones junto con las entregas.
- Cierre de una calle o de un cruce que cambia varios tramos a la vez.

---
*Las cifras de dominio (15 unidades y 900 entregas, avería a las 11 a. m. con 40 entregas
pendientes, paradas de 2 a 5 minutos, 5-15 % de entregas fallidas, GPS cada 10 s y una hora
sin señal) vienen del problema original. Verifica la fuente vigente antes de citarlas en
tu entrega.*
