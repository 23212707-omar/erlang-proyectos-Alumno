# #30 — Bicicletas o scooters compartidos: gemelo digital con programación lógica

> Extensión del proyecto #30. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el sistema: estaciones y unidades como procesos,
desbloqueos y cierres de viaje, fallas inyectadas. Esa simulación responde «¿cuántas
bicicletas hay en cada estación?». La persona de despacho necesita algo más: «¿a qué
estación mando el camión, de cuál saco bicicletas y a quién le fallo si no alcanza?».

El gemelo digital es el **modelo lógico** del sistema: hechos que reflejan su estado y
reglas que reflejan cómo se decide en él. Se escribe en Prolog porque lo que hay que
resolver aquí no es calcular un óptimo, sino repartir recursos que no alcanzan,
justificar a quién se le falla y saber cuándo no se sabe.

## El sistema que se clona

Un sistema de bicicletas y scooters compartidos de una ciudad con universidad, reducido a
8 estaciones en 3 zonas (barrio, centro y campus), unas 60 bicicletas, 4 scooters y 2
camiones de rebalanceo. El tiempo se cuenta en minutos desde el inicio de la ventana de
prueba. Los camiones recorren una red de tramos con tiempos conocidos.

| Parte | Contenido |
|---|---|
| Entidades | estación (con anclajes), bicicleta, scooter, camión de rebalanceo, usuario, viaje, zona |
| Estado por estación | bicicletas disponibles, anclajes libres, hora del último reporte, zona |
| Estado por unidad | en estación, en uso, en mantenimiento; en el scooter, batería y posición |
| Estado por camión | dónde está, cuántas bicicletas lleva, qué ruta sigue |
| Flujos | cada zona se vacía o se llena según la franja del día (mañana y tarde) |
| Eventos | un usuario pide desbloquear, se abre o se cierra un viaje, un anclaje reporta una bicicleta, una estación deja de comunicar, un scooter reporta |
| Decisiones | ¿qué estación atiende un camión y con cuántas bicicletas?, ¿quién recibe la unidad?, ¿hasta cuándo se cobra un viaje?, ¿se manda a verificar una estación callada? |

## Situaciones que tu gemelo debe razonar

Las cinco parten del problema original (estaciones por vaciarse, camión de 20 a 40
bicicletas, dos usuarios por la última bicicleta, viaje abierto por pérdida de señal,
estación sin comunicación); algunas añaden complementos derivados del foco «Rebalanceo
entre estaciones». En cada una, tu gemelo debe llegar a una decisión **y poder
explicarla**.

### Situación 1 — La estación que se vacía antes de que llegue el camión

- **Qué pasa.** Por la mañana la gente viaja hacia la universidad: el barrio se vacía y
  el campus se llena. Quien llega a una estación sin bicicletas se va; quien llega a una
  llena no puede devolver la suya. El camión sale hacia una estación, pero el recorrido
  consume tiempo: si llega cuando la estación ya se vació, el viaje se pagó en vano.
- **Qué datos hay.** Bicicletas y anclajes libres de cada estación con la hora del
  reporte, el sentido del flujo de cada zona en cada franja, los tiempos entre estaciones
  y dónde está cada camión. Ningún dato dice «se vaciará».
- **Qué debe deducir.** Qué estaciones se quedarán sin bicicletas o sin anclajes dentro
  de 30 minutos, y para cada una si un camión llega antes o después de que ocurra.
- **Qué debe contestar.** La lista de estaciones en riesgo, el tipo de riesgo y cuándo,
  qué camión llega a tiempo y cuál llegaría tarde. Si ningún camión llega a tiempo, lo
  dice y da el motivo.
- **Por qué es lógica.** El riesgo no está en una lectura: sale de encadenar franja,
  flujo, bicicletas esperadas y tiempo de llegada del camión.

### Situación 2 — Un camión, dos estaciones y una que parece sobrar

- **Qué pasa.** Se acerca la tarde. Dos estaciones del campus se vaciarán y solo un camión
  está libre; el otro sigue en otra zona. La del campus norte atiende a más usuarios pero
  queda lejos; la del campus sur está a un tramo corto. El camión necesita bicicletas de
  algún lado: la estación de oficinas se llenó en la mañana y parece el origen obvio,
  pero la marea de la tarde también la vaciará. Las dos estaciones tienen razón; el
  camión solo cabe en una a tiempo.
- **Qué datos hay.** Bicicletas de cada estación, la marea de cada zona, la capacidad del
  camión, los anclajes libres del destino y los tiempos de los tramos.
- **Qué debe deducir.** Qué estaciones pueden ceder bicicletas sin quedar ellas mismas en
  riesgo, qué reparto cabe en el camión y en los anclajes del destino, y en qué orden se
  recorren las paradas.
- **Qué debe contestar.** El plan (origen, destino, cantidad y orden), la estación a la
  que se le falla y por qué, y todos los demás planes válidos. Lo intuitivo es sacar de la
  estación más llena; es sospechoso porque esa misma marea la vaciará. Si no existe plan,
  lo dice y señala el recurso que falta.
- **Por qué es lógica.** Es un dilema con restricciones: capacidad, tiempo y anclajes a la
  vez, y la regla debe decidir y justificar a quién se le falla.

### Situación 3 — Dos manos sobre la última bicicleta

- **Qué pasa.** Dos usuarios piden desbloquear la última bicicleta de una estación casi
  al mismo tiempo. Uno de ellos mandó la orden dos veces porque su red falló y la
  reintentó. La estación marcaba dos bicicletas disponibles, pero una está en
  mantenimiento. Si se cuenta el reintento como otro usuario, se cobra doble a quien solo
  reintentó; si se confunden dos usuarios con un reintento, alguien pierde su viaje.
- **Qué datos hay.** Las órdenes de desbloqueo con usuario, unidad y minuto; el estado de
  cada unidad de la estación; las estaciones vecinas y su distancia.
- **Qué debe deducir.** Cuántas bicicletas hay realmente libres, cuáles órdenes son el
  mismo intento repetido y cuáles compiten por la misma unidad.
- **Qué debe contestar.** Quién recibe la bicicleta, quién se queda sin ella y por qué,
  cuántos viajes y cobros se abren (nunca uno por cada orden repetida) y, para quien
  quedó fuera, la estación vecina más cercana que sí tiene una unidad libre.
- **Por qué es lógica.** Hay exclusión mutua entre órdenes y hay que distinguir identidad:
  «dos mensajes» no es lo mismo que «dos personas».

### Situación 4 — El viaje que nadie cerró

- **Qué pasa.** Se perdió la señal al cerrar dos viajes. En el primero, una bicicleta
  aparece anclada en una estación desde hace rato, pero el viaje sigue abierto y el reloj
  cobra por minuto; el usuario reclama. En el segundo, un scooter con viaje abierto lleva
  mucho sin reportar, su última batería era baja y su última posición estaba cerca del
  límite de la zona permitida. Un scooter dura entre 3 y 6 horas de uso.
- **Qué datos hay.** Eventos de desbloqueo y cierre, los reportes de los anclajes, la
  última lectura del scooter (batería, posición, minuto), la zona permitida y el «ahora».
- **Qué debe deducir.** Cuándo terminó en realidad cada viaje, hasta cuándo se cobra, y
  qué estado probable tiene el scooter: en uso, agotado, fuera de zona o perdido. Ningún
  dato dice «el viaje terminó» ni «el scooter está abandonado».
- **Qué debe contestar.** Para cada viaje, «terminó en tal momento», «sigue abierto» o
  «no se sabe», con qué dato o inspección resolvería la duda, y el tiempo que se cobra.
  Lo intuitivo es cobrar hasta el «ahora» mientras el viaje siga abierto; es sospechoso
  porque otro dato del sistema puede contradecirlo.
- **Por qué es lógica.** Lo que ordena el sistema («viaje abierto») y lo que sucede (el
  anclaje, la batería) se contradicen; hay que decidir cuál pesa y decirlo.

### Situación 5 — La estación que se calló una hora

- **Qué pasa.** Una estación deja de comunicar durante una hora. El feed sigue mostrando
  su último estado, que ya no es de fiar. Mientras tanto la marea de su zona sigue
  empujando bicicletas, y la app sí registró desbloqueos allí por otro canal. Hay dos
  camiones y varias estaciones en riesgo: mandar uno a ver qué pasa le quita el servicio
  a otra.
- **Qué datos hay.** El último reporte de la estación con su hora, la marea de su zona,
  los desbloqueos que la app registró, el estado de las estaciones que sí comunican y la
  ubicación de los camiones.
- **Qué debe deducir.** Entre qué extremos pudo moverse la cantidad de bicicletas de la
  estación y si, con ese margen, puede haberse vaciado o llenado.
- **Qué debe contestar.** «Hay bicicletas», «no hay» o «no se sabe», marcado como
  inferencia y no como lectura; con la duda, si conviene mandar un camión a verificar y
  cuál, y qué cambia si la comunicación vuelve pronto.
- **Por qué es lógica.** «Sin reporte» no es «vacía» ni «igual que antes»: el gemelo debe
  razonar con lo que sí sabe y no tratar un silencio como un cero.

## Por qué no basta un script

Con `if bicis < minimo: mandar_camion()` resuelves una estación con datos perfectos y un
solo camión. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿A qué estación mando el camión 1 y con cuántas bicicletas? | decisión |
| ¿Por qué el campus norte y no el sur? | explicación |
| ¿De cuántas formas puedo repartir esta tarde las bicicletas del camión? | todas las respuestas |
| ¿Qué tendría que pasar para que el camión llegue a tiempo a la estación del barrio? | la pregunta al revés |
| ¿Qué pasa si la estación callada vuelve a comunicar en diez minutos? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué información necesitas para predecir que una estación se quedará vacía en 30
   minutos?
2. ¿Cómo dices que una bicicleta no puede estar en dos viajes ni una orden contarse dos
   veces?
3. ¿Cómo distingue tu gemelo «la estación está vacía» de «no sé cuántas bicicletas tiene»?
4. ¿Qué parte de la explicación le sirve a quien despacha los camiones y qué parte es
   ruido?
5. ¿Cuál es la fuente de verdad de si una bicicleta está en uso, y qué procesos de tu
   simulación en Erlang (la estación, la unidad) podrían alimentar a este gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del sistema, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar viajes simulados o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 8 estaciones, unas 60 bicicletas, 4 scooters y 2 camiones, contra las
  40 estaciones, 400 bicicletas y 1,000 viajes al día del escenario original.
- La capacidad de los camiones puede ser la del original (de 20 a 40 bicicletas) o una
  menor, si la declaras; el número de anclajes de cada estación, los tiempos entre
  estaciones, las franjas de la marea, la zona permitida del scooter y la batería de cada
  unidad son datos inventados que defines tú.
- El «ahora» es un hecho del modelo, en minutos, no el reloj del sistema.
- Quedan a decisión del estudiante: cuánto tiempo sin reporte vuelve dudosa a una
  estación o a un scooter, cuánto margen pides antes de llamar «en riesgo» a una
  estación, cómo reconoces un reintento de red y cuánto vale fallarle a un usuario frente
  a otro.
- Los identificadores de los ejemplos («camión 1», «campus norte», «estación del barrio»)
  son ilustrativos.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Camión que se descompone a medio recorrido con bicicletas a bordo.
- Evento masivo (concierto, partido) que cambia la marea de varias zonas a la vez.
- Cuadrilla que recoge scooters para cargarlos, con turnos y baterías de reemplazo.
- Incentivos al usuario para devolver la bicicleta en una estación menos llena.
- Lluvia o calor que reduce los viajes de toda una zona.

---
*Las cifras de dominio (30 minutos de anticipación, camión de 20 a 40 bicicletas, scooter
de 3 a 6 horas de uso, una hora sin comunicación, 40 estaciones, 400 bicicletas y 1,000
viajes al día) vienen del problema original. Verifica la fuente vigente antes de citarlas
en tu entrega.*
