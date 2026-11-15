# #31 — Control de pista y rampa: gemelo digital con programación lógica

> Extensión del proyecto #31. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el aeropuerto: la pista y el secuenciador como procesos,
solicitudes de despegue y aterrizaje, una pista que se cierra con operaciones en cola.
Esa simulación responde «¿en qué orden salió todo?». La persona de la torre y la de la
rampa necesitan algo más: «¿a quién le toca la pista, a quién le fallo si no alcanza, y
por qué esta salida va a llegar tarde?».

El gemelo digital es el **modelo lógico** del aeropuerto: hechos que reflejan su estado
y reglas que reflejan cómo se decide en él. Se escribe en Prolog porque lo que hay que
resolver aquí no es calcular una hora, sino repartir una pista y unos equipos que no
alcanzan, justificar a quién se le falla y saber cuándo no se sabe.

## La pista y la rampa que se clonan

Un aeropuerto como el de Tijuana (TIJ), con una sola pista, reducido a una ventana de
unos 12 movimientos, 4 puertas y 1 tractor de remolque. El tiempo se cuenta en minutos
desde el inicio de la ventana. Las aeronaves son ligeras o pesadas (y, si lo necesitas,
intermedias); cada puerta atiende un avión con sus servicios de rampa.

| Parte | Contenido |
|---|---|
| Entidades | pista, vuelo (llegada o salida), puerta, servicio de rampa, equipo compartido |
| Estado por vuelo | categoría de estela, tipo, posición en la secuencia, hora objetivo de fin de rotación (TOBT) y de autorización de arranque (TSAT) |
| Estado por puerta | qué avión tiene y qué servicios ya terminaron o siguen pendientes |
| Estado por equipo | dónde está, si está ocupado y su último reporte |
| Eventos | un vuelo declara emergencia, una aeronave aparece o desaparece de la aproximación, un servicio termina, el tractor llega a una puerta, un operador declara su TOBT |
| Decisiones | ¿quién usa la pista y cuándo?, ¿en qué orden atiende el tractor los pushbacks?, ¿a qué vuelo se le falla?, ¿se libera una salida o hay que esperar? |

## Situaciones que tu gemelo debe razonar

Cuatro parten del problema original (la emergencia, la separación por estela y la
pregunta guía 2, el tractor compartido, el servicio de rampa retrasado); la quinta
plantea algo nuevo, derivado de los hitos A-CDM del original y del foco «secuenciar
movimientos con separación mínima y prioridad». En cada una, tu gemelo debe llegar a una
decisión **y poder explicarla**.

### Situación 1 — La emergencia que pasa a todos, menos a uno

- **Qué pasa.** Con la secuencia ya armada, un avión declara emergencia médica. Las
  emergencias pasan a todos, pero la pista no se puede liberar de un instante a otro: hay
  una aeronave que ya no puede cederle el turno, y si la emergencia es una aeronave pesada,
  quienes la sigan necesitan más separación que si fuera ligera. Cada minuto de ajuste lo
  pagan salidas con pasajeros esperando y llegadas con combustible contado.
- **Qué datos hay.** La secuencia vigente con sus horas, la categoría de cada aeronave, la
  separación entre cada par de categorías, qué vuelos ya están comprometidos y la
  emergencia con su tipo. Ningún dato dice «este es el primer hueco válido».
- **Qué debe deducir.** El primer lugar de la secuencia en el que la emergencia cabe sin
  violar ninguna separación, quién se desplaza, a quién desplaza eso en cadena y cuántos
  minutos pierde cada uno.
- **Qué debe contestar.** La nueva secuencia, el lugar de la emergencia, la lista de
  afectados con su retraso y la razón de por qué no iba un lugar antes. Lo intuitivo es
  ponerla al frente de la cola; es sospechoso porque eso puede violar una separación con
  quien ya está comprometido. Si no hay lugar válido, lo dice y señala el motivo.
- **Por qué es lógica.** Es una cadena: prioridad, compromiso, separación con el vecino
  nuevo y retraso de todos los que siguen. Las reglas son las mismas que armaron la
  secuencia original; solo cambia un hecho.

### Situación 2 — Pesada delante de ligera: el orden que cuesta menos

- **Qué pasa.** Llegan seguidas varias aeronaves, pesadas y ligeras. Si una pesada precede
  a una ligera hace falta más tiempo de estela que al revés, de modo que el orden en que
  llegaron no es el que menos tiempo pierde. Además, las llegadas tienen prioridad sobre
  las salidas, y una de las salidas es de un vuelo marcado como crítico por su operador.
  Quien opera la torre debe elegir entre minimizar las demoras totales o proteger a ese
  vuelo; quien pierde en cada caso tiene razones reales.
- **Qué datos hay.** Las llegadas y salidas en espera con su categoría, la separación por
  par de categorías, las prioridades, el vuelo crítico con su motivo y el «ahora».
- **Qué debe deducir.** Qué órdenes de la secuencia respetan todas las separaciones y
  prioridades, cuánto retraso acumula cada una y cuál le cuesta más a quién.
- **Qué debe contestar.** La secuencia elegida, la que se descartó, el costo para el vuelo
  crítico y para el resto, y por qué se le falló a quien se le falló. Lo intuitivo es
  respetar el orden de llegada; es sospechoso porque ese orden puede ser el de más
  retraso. También debe dar todas las secuencias válidas.
- **Por qué es lógica.** Es un dilema real: «mínimo total» y «proteger al crítico» son
  políticas distintas y la regla debe decir cuál manda, declarada una sola vez.

### Situación 3 — Un tractor, tres aviones

- **Qué pasa.** Tres aviones en tres puertas necesitan el único tractor al mismo tiempo,
  dos para pushback y uno para un remolque. El tractor está en una cuarta puerta y llegar a
  cada una consume tiempo. Cada pushback tiene su TSAT y después vienen el arranque y el
  rodaje (de 5 a 15 minutos en aeropuertos concurridos): llegar tarde pierde el turno de
  pista, y el siguiente turno puede no estar cerca.
- **Qué datos hay.** Dónde está el tractor, el tiempo de los tramos de la plataforma, la
  duración de cada maniobra, el TSAT de cada salida y qué vuelo viene detrás en la pista.
- **Qué debe deducir.** Qué órdenes de atención son posibles, a qué hora llega el tractor
  a cada avión en cada una y qué salidas pierden su turno de pista.
- **Qué debe contestar.** El orden de atención con las horas, a quién se le falla y qué
  costo trae, y los demás órdenes válidos. Lo intuitivo es atender primero a quien lo pidió
  primero; es sospechoso porque lo que importa es qué salida pierde su turno. Si ningún
  orden evita perder un turno, lo dice y señala el recurso que falta.
- **Por qué es lógica.** Tres peticiones por un recurso y una agenda con ventanas: el
  conflicto se resuelve declarando restricciones y dejando que el gemelo enumere.

### Situación 4 — El servicio que se atrasó y lo que arrastra

- **Qué pasa.** El catering de un avión llega tarde. Antes de culpar al catering: ese
  avión también espera combustible, que depende de la misma unidad que otra puerta usa, y
  la limpieza solo empieza cuando termina el equipaje. Si el fin de rotación se pasa de su
  TOBT, se pierde el TSAT, la salida se reubica en la secuencia, quienes la siguen se
  mueven y el pushback ocupa al tractor más tarde que lo previsto.
- **Qué datos hay.** Los servicios de cada puerta con su duración y qué depende de qué, los
  equipos compartidos, el TOBT y el TSAT, y los avisos de término de cada servicio.
- **Qué debe deducir.** Cuál es el servicio que de verdad fija la hora de salida del avión
  (ningún dato lo dice), qué pasa con el TSAT, qué otras salidas se mueven y si el tractor
  llega tarde a otra puerta.
- **Qué debe contestar.** El nuevo fin de rotación y su causa, la cadena de afectados
  hasta el último y, si el servicio atrasado no era el que decidía, que no cambia nada y
  por qué. Lo intuitivo es culpar al servicio que se atrasó; es sospechoso porque otro
  puede estar más cerca de ser el cuello de botella.
- **Por qué es lógica.** La causa de una demora no se lee en un reporte: se deduce de
  dependencias entre servicios y recursos compartidos, y la cadena sigue hasta la pista.

### Situación 5 — El avión que nadie ve y la hora que alguien declaró

- **Qué pasa.** Una salida espera su turno y la pista parece libre. Pero la última posición
  de una llegada en aproximación es vieja, y el operador de otra salida declaró un TOBT
  muy optimista para ganar turno, aunque la puerta no reporta el cierre. El sistema de
  rampa dice que el tractor está libre; su último reporte también es viejo. Liberar la
  pista sin estar seguro puede romper una separación; no liberarla retrasa a todos.
- **Qué datos hay.** Posiciones con su minuto, el rango físico de cada variable, los
  hitos que sí reportó cada puerta, el TOBT declarado, los reportes del tractor y el
  «ahora». El original no dice cuánto silencio vuelve dudoso un reporte.
- **Qué debe deducir.** Si la llegada está o no lo bastante cerca para que la salida no
  deba despegar, si el TOBT declarado es creíble y si el tractor está libre. Para cada
  uno: sí, no o no se sabe.
- **Qué debe contestar.** Una respuesta de tres valores por cada pregunta, marcada como
  inferencia cuando no es lectura, el dato que la resolvería (una confirmación por radio,
  el cierre de puerta) y la decisión que cada «no sé» deja pendiente. Lo intuitivo es
  tratar «no sé» como «libre»; es sospechoso porque ahí puede estar el riesgo.
- **Por qué es lógica.** «No hay conflicto» y «no sé si lo hay» no son lo mismo, y dos
  sistemas que no coinciden obligan a decidir en cuál se confía y a decirlo.

## Por qué no basta un script

Con `if separacion_cumplida: autorizar_despegue()` resuelves un despegue con datos
perfectos y un solo avión. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Quién usa la pista después de la emergencia? | decisión |
| ¿Por qué la pesada va antes que el vuelo crítico? | explicación |
| ¿Cuáles son todas las secuencias válidas para estos seis movimientos? | todas las respuestas |
| ¿Qué tendría que pasar para que el pushback de la puerta 2 no pierda su turno? | la pregunta al revés |
| ¿Qué pasa si el catering tarda diez minutos más? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué invariantes nunca pueden violarse aunque la secuencia cambie, y dónde quedan
   escritos para que valgan en todas las situaciones?
2. ¿Dónde declaras si pesa más minimizar demoras totales o proteger a un vuelo crítico?
3. ¿Cómo distingue tu gemelo «la pista está libre» de «no sé si lo está»?
4. ¿Qué parte de la explicación le sirve a la persona de la torre y qué parte es ruido?
5. ¿Qué procesos de tu simulación en Erlang (la pista, el secuenciador) podrían
   alimentar a este gemelo, y cuál es la fuente de verdad de la posición de un avión?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del aeropuerto, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar movimientos simulados o
  graficar.

## Supuestos de esta extensión

- Escala reducida: unos 12 movimientos, 4 puertas y 1 tractor, contra los 40 movimientos
  en 2 horas del escenario original. Los números de ejemplo («puerta 2», «seis
  movimientos», «diez minutos más») son ilustrativos.
- Las separaciones por estela entre categorías, los tiempos de los tramos de la
  plataforma, la duración de cada servicio, quién depende de quién, las categorías y qué
  hace «crítico» a un vuelo son datos inventados que defines tú; el original solo da
  que un movimiento ocupa de 1 a 2 minutos y que más estela exige más tiempo.
- El «ahora» es un hecho del modelo, en minutos, no el reloj del sistema.
- Quedan a decisión del estudiante: cuánto silencio vuelve dudosa una posición o un
  reporte de equipo, hasta qué punto una aeronave ya no puede cederle el turno a una
  emergencia, cómo pesas el retraso total frente al de un vuelo crítico y cuánta
  tolerancia das a un TOBT declarado.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Cierre o cambio de pista a media ventana y reprogramación de lo que estaba en cola.
- Viento, visibilidad o tormenta que cambia las separaciones de todos los pares.
- Más de un tractor y turnos de la cuadrilla de rampa.
- Un vuelo que llega con combustible mínimo sin declarar emergencia.
- Cargos por demora y qué aerolínea los asume.

---
*Las cifras de dominio (movimiento de 1 a 2 minutos, rodaje de 5 a 15 minutos, 40
movimientos en 2 horas, una emergencia y un tractor para 3 aviones) vienen del problema
original. Verifica la fuente vigente antes de citarlas en tu entrega.*
