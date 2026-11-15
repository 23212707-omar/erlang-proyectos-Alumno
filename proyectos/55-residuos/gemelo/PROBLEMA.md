# #55 — Residuos: gemelo digital con programación lógica

> Extensión del proyecto #55. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la recolección: un proceso por contenedor que reporta su
nivel, camiones que salen, recolectan y descargan, y un planificador que arma rutas por
umbral. Esa simulación responde «¿qué está pasando en la calle?». El despachador necesita
algo más: «¿a quién mando, en qué orden, y a quién le voy a fallar hoy?».

El gemelo digital es el **modelo lógico** de la operación: hechos que reflejan su estado
y reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque lo que hay que
resolver aquí no es calcular una ruta perfecta, sino deducir, justificar y repartir lo
que no alcanza.

## La recolección que se clona

Un servicio municipal de limpia, reducido a 3 zonas con 4 contenedores cada una, 3
camiones y una red de calles que une los contenedores, el depósito y el relleno sanitario.

| Parte | Contenido |
|---|---|
| Entidades | zona → contenedor (con sitio: mercado, restaurante, residencial, escuela); camión; depósito; relleno sanitario; calles entre ellos |
| Estado por contenedor | nivel de llenado (0-100 %) con la hora de su lectura, último vaciado, aporte en toneladas al vaciarse |
| Estado por camión | capacidad (t), carga actual (t), viajes al relleno hechos, en servicio o descompuesto |
| Red | calles con su tiempo de recorrido en minutos; trayecto al relleno de 30 a 60 minutos |
| Eventos | llega una lectura, llueve, es lunes o festivo, un evento masivo satura una zona, un camión se descompone, se vacía un contenedor, se descarga en el relleno |
| Decisiones | ¿confío en esta lectura?, ¿qué contenedor entra hoy a ruta?, ¿qué camión lo toma y en qué orden?, ¿cuándo se descarga?, ¿a quién no se le llega? |

## Situaciones que tu gemelo debe razonar

Las cinco parten de casos, datos o preguntas del problema original; los detalles que esta
extensión añade (sitios, red, aportes, escuelas) se listan en «Supuestos». En cada una,
tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — El 100 % que no se puede creer

- **Qué pasa.** El sensor ultrasónico mide la distancia a la basura; si esta queda
  inclinada, hay humedad o llueve, miente. Un contenedor del mercado marca lleno cuando
  una hora antes marcaba poco, y llovió. Uno residencial lleva horas sin reportar. Mandar
  un camión a uno medio vacío gasta una parada y capacidad; no mandarlo a uno lleno es
  desborde, plagas y quejas.
- **Qué datos hay.** Lecturas con su hora, el rango físico del nivel, los eventos de
  lluvia, el sitio de cada contenedor y su último vaciado.
- **Qué debe deducir.** Qué lecturas son creíbles, dudosas o imposibles, y el nivel
  probable de un contenedor sin lectura creíble a partir de su último vaciado, su ritmo
  y sus vecinos del mismo tipo de sitio. Ningún sensor mide «probablemente lleno».
- **Qué debe contestar.** Tres respuestas distintas: «está lleno», «no está lleno» y «no
  lo sé». Para los dudosos, si conviene una parada de revisión y qué lectura lo
  confirmaría. Todo nivel que no sea una lectura creíble se marca como inferido.
- **Por qué es lógica.** «No está lleno» y «no puedo saber si está lleno» llevan a
  decisiones distintas, y la duda se razona con otros hechos, no se rellena con un
  promedio.

### Situación 2 — ¿Se llena antes de que vuelva el camión?

- **Qué pasa.** Un contenedor junto a un restaurante o un mercado se llena en un día; uno
  en zona residencial tarda una semana. Los lunes y después de un festivo hay más basura.
  Hoy solo hay camiones para algunos: hay que decidir quién no aguanta hasta la próxima
  visita posible, aunque hoy marque poco.
- **Qué datos hay.** Sitio, nivel creíble más reciente y su hora, último vaciado, los
  días especiales y cuándo podría volver un camión a cada zona.
- **Qué debe deducir.** Qué contenedores se llenarán antes de la próxima visita. Es una
  cadena: el sitio da el ritmo, el día especial lo acelera, el ritmo da la hora estimada
  de desborde, y esa hora se compara con la visita. Nadie mide «desbordará a las...».
- **Qué debe contestar.** Los contenedores en riesgo con su hora estimada y la razón;
  cuáles están a un solo hecho de entrar; y, al revés, qué visita salvaría a uno dado.
- **Por qué es lógica.** La urgencia no es el nivel: es lo que resulta de combinar sitio,
  calendario y horario. Lo intuitivo (mandar primero al más lleno) está en duda: uno al
  40 % junto a un mercado antes de un festivo puede ser más urgente que uno al 85 % en
  una colonia tranquila. El gemelo debe poder decir cuándo y por qué.

### Situación 3 — De paso al 60 %

- **Qué pasa.** La ruta de un camión pasa frente a un contenedor al 60 %. Recogerlo ahora
  evita un viaje futuro, pero ocupa capacidad del camión y alarga la jornada, y más
  adelante espera un contenedor crítico que quizá ya no quepa. Los vecinos del crítico y
  la eficiencia del servicio tienen razón a la vez.
- **Qué datos hay.** La ruta, los tiempos de calle, capacidad y carga del camión, el
  aporte de cada contenedor y el nivel y la hora estimada de cada uno.
- **Qué debe deducir.** Si el desvío es de verdad «de paso» (no cambia el destino de
  nadie) o si desplaza a otro contenedor, y cuánto le cuesta a ese otro.
- **Qué debe contestar.** Recoger o no, qué regla pesó más y a quién se le falla si se
  recoge; y qué tendría que cambiar (otro camión, más jornada, menos carga) para que
  alcance para ambos.
- **Por qué es lógica.** El conflicto se declara una vez y el mismo criterio vale para
  cualquier contenedor «de paso»; la explicación nombra al desplazado.

### Situación 4 — Camión lleno antes de terminar la ruta

- **Qué pasa.** A media ruta el camión alcanza su capacidad. Debe ir al relleno (30 a 60
  minutos por trayecto; entre uno y tres viajes por turno) y volver, y aún quedan
  contenedores urgentes. La jornada es de 8 horas y puede no alcanzar para todos.
- **Qué datos hay.** Red de calles y tiempos, capacidad, carga, viajes ya hechos,
  pendientes con su urgencia y lo que queda de jornada.
- **Qué debe deducir.** Qué paradas caben antes de tener que descargar, en qué momento
  conviene descargar (a veces antes de llenarse), y qué pendientes no caben en la
  jornada de ninguna manera. Es una cadena: carga acumulada, descarga forzosa, tiempo de
  viaje, hora de regreso, fin de jornada.
- **Qué debe contestar.** El plan completo (paradas por viaje, orden y momento de
  descarga) y las demás alternativas válidas; si no cabe todo, qué queda fuera y por qué
  eso; si no existe plan, el motivo.
- **Por qué es lógica.** Es asignar y ordenar bajo restricciones de capacidad y tiempo;
  un solo plan no basta, hay que poder preguntar por los otros.

### Situación 5 — Camión averiado con la zona saturada

- **Qué pasa.** Un evento masivo satura los contenedores de una zona. Ese mismo día un
  camión se descompone con la carga a la mitad. Sus paradas pendientes quedan huérfanas,
  los otros camiones ya tenían plan y jornada, y alguien se queda sin servicio hoy: la
  zona saturada (quejas, tiraderos clandestinos) o los contenedores de un mercado
  (plagas). Ambos reclaman con razón.
- **Qué datos hay.** Estado y carga de cada camión, paradas pendientes del averiado, los
  planes de los demás, la urgencia de cada contenedor y la jornada restante.
- **Qué debe deducir.** Qué paradas quedan huérfanas, a qué camión se pueden pasar sin
  romper capacidad ni jornada, y qué se desplaza en cascada (la avería recarga a un
  camión, ese deja fuera a unos contenedores, y esos se vuelven urgentes mañana).
- **Qué debe contestar.** El plan nuevo por camión; la lista de contenedores sin atender
  hoy, con la causa y a quién perjudica; y la hipótesis «¿y si se descompone el camión
  2 en vez del 1?».
- **Por qué es lógica.** Un evento externo cambia varias reglas a la vez y el efecto
  viaja por la red; la justificación de a quién se le falla es parte de la respuesta.

## Por qué no basta un script

Con `if nivel > umbral: mandar_camion()` resuelves un contenedor con sensor perfecto y un
camión infinito. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué hago con los contenedores del mercado hoy? | decisión |
| ¿Por qué se quedó fuera el de la escuela? | explicación |
| ¿Qué contenedores se desbordan antes de la próxima visita? | todas las respuestas |
| ¿Qué falta para que el camión 3 alcance a recoger el 7? | la pregunta al revés |
| ¿Qué pasaría si mañana es festivo? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco consultas
sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el programa.

## Preguntas guía

1. ¿Qué hechos necesitas para estimar el nivel de un contenedor sin lectura creíble?
2. ¿Cómo distingue tu gemelo «no se desborda» de «no sé si se desborda»?
3. Cuando el camión no alcanza, ¿dónde queda escrito a quién se le falla?
4. ¿Qué parte de la explicación le sirve al despachador y qué parte es ruido?
5. ¿Qué parte de tu simulación en Erlang (el proceso por contenedor, el planificador por
   umbral, el estado del camión, el contenedor sin reportar) podría alimentar a este
   gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la recolección, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar lecturas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 3 zonas, 12 contenedores y 3 camiones, contra los 300 contenedores y 5
  camiones del escenario original. Camiones de 10 t y jornada de 8 h, como el original.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir. La unidad es el minuto.
- Los sitios de cada contenedor (qué zona es de mercado, de restaurantes o residencial,
  dónde hay una escuela), el trazado de la red de calles, los tiempos de recorrido, el
  aporte en toneladas de cada contenedor y el tiempo de cada parada los defines tú.
  El original solo da el rango de 30 a 60 minutos al relleno y de 1 a 3 viajes por turno.
- Los identificadores de los ejemplos («contenedor 7», «camión 2», «el 40 % y el 85 %»)
  son ilustrativos.
- El original no da cuánto tiempo sin reportar vuelve sospechoso a un sensor, cuánto
  salto entre lecturas vuelve dudosa una, ni el ritmo exacto de cada sitio: son tus
  decisiones, y las anotas.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Ventanas de tráfico y horario de los operadores en cada zona.
- Horas extra contra un contenedor más: cuánto cuesta alargar la jornada.
- Camiones de distinto tamaño y contenedores que solo caben en algunos.
- Varios sitios de disposición y qué hacer si uno se cierra.
- Quejas de vecinos como señal adicional para dudar de un sensor.

---
*Las cifras (8 a 12 t, 1 a 3 viajes, 30 a 60 minutos, 300
contenedores, 5 camiones, 8 h) vienen del problema original y son órdenes de magnitud.
Verifica la fuente vigente antes de citarlas en tu entrega.*
