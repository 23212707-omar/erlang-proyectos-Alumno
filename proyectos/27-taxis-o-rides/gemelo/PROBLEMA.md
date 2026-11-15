# #27 — Taxis o rides: gemelo digital con programación lógica

> Extensión del proyecto #27. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la plataforma: conductores que reportan su posición,
solicitudes que entran, ofertas que alguien acepta o deja sin respuesta. Esa simulación
responde «¿qué está pasando en la flota?». Quien opera el servicio necesita algo más:
«¿a quién le ofrezco este viaje, y por qué a él y no a otro?».

El gemelo digital es el **modelo lógico** de la operación: hechos que reflejan su estado
y reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque lo que hay que
resolver aquí no es calcular rutas, sino emparejar bajo restricciones, justificar y
saber cuándo no se sabe.

## La plataforma de viajes que se clona

Una zona de Tijuana con un recinto de conciertos, reducida a 12 celdas hexagonales (como
las del índice H3 del original), 12 conductores y 8 solicitudes. El tiempo se cuenta en
segundos, porque los plazos del problema son de segundos.

| Parte | Contenido |
|---|---|
| Entidades | celda → conductor → viaje; solicitud de un pasajero; oferta de una solicitud a un conductor |
| Estado por conductor | celda y hora de su último reporte, estado (libre, asignado, en viaje), asientos, si su vehículo es accesible |
| Estado por solicitud | celda de origen, hora en que se pidió, asientos y accesibilidad que necesita, estado (esperando, ofrecida, asignada, cancelada) |
| Estado por celda | celdas vecinas, tiempo de viaje hacia cada vecina, solicitudes pendientes, nivel de tarifa |
| Eventos | llega una solicitud, llega una posición, un conductor acepta, rechaza o no responde, el pasajero cancela, un conductor deja de reportar, empieza el evento masivo |
| Decisiones | ¿a quién se ofrece?, ¿a quién se asigna?, ¿se reasigna?, ¿qué espera se muestra?, ¿sube la tarifa de la zona? |

## Situaciones que tu gemelo debe razonar

Las cinco parten del problema original (dos solicitudes que compiten, buscar candidatos
sin recorrer la flota, pérdida de conexión, rechazos y plazos, evento masivo); la 2 y la 5
añaden complementos que el original no trae (compatibilidad del vehículo, auditoría de
una espera), derivados del foco «emparejar con restricciones». En cada una, tu gemelo
debe llegar a una decisión **y poder explicarla**.

### Situación 1 — Dos pasajeros, un conductor cercano

- **Qué pasa.** Dos solicitudes entran casi juntas en la misma zona y el conductor libre
  más cercano a ambas es el mismo. Si se lo das a la primera, la segunda queda con una
  espera mucho mayor; si se lo das a la segunda, la primera se siente pasada por alto.
- **Qué datos hay.** Tiempo de cada conductor libre hacia cada solicitud, la hora en que
  se pidió cada una y el estado de cada conductor.
- **Qué debe deducir.** Qué conductor puede atender a cuál sin que ninguno quede
  asignado a dos pasajeros, y qué repartos completos existen.
- **Qué debe contestar.** El reparto, el criterio que lo decidió y a quién se le falla:
  cuánto más espera ese pasajero que en el reparto contrario. Todos los repartos válidos
  si se piden.
- **Por qué es lógica.** Cada solicitud tiene candidatos y cada conductor puede
  servir a uno solo: es asignación con restricciones, no «el más cercano a cada uno».

### Situación 2 — El cercano que no sirve

- **Qué pasa.** Llega una solicitud desde una celda de la orilla del área. Un pasajero
  pide un vehículo accesible y cuatro asientos. El conductor que parece más cerca está,
  en línea recta, a pocos metros, pero del otro lado de un canal con pocos puentes.
  Revisar a los 12 conductores uno por uno no escala: con miles, solo se revisa la celda
  y sus vecinas.
- **Qué datos hay.** Las celdas y su vecindad con el tiempo de viaje entre vecinas
  (que no es simétrico), la celda y la hora de reporte de cada conductor, y lo que
  necesita la solicitud y lo que ofrece cada vehículo.
- **Qué debe deducir.** Qué celdas hay que mirar y en qué orden, quiénes son candidatos
  de verdad (libres, con posición vigente, compatibles, con un tiempo de llegada
  razonable) y por qué cada uno de los demás no lo es.
- **Qué debe contestar.** La lista ordenada de candidatos con su tiempo estimado y, para
  el conductor «más cerca» que se descartó, la razón. Cuáles conductores ni se miraron.
- **Por qué es lógica.** El candidato sale de encadenar vecindad, estado, vigencia y
  compatibilidad; ningún dato dice «este sirve». Lo obvio (el más cerca en el mapa) puede
  estar mal.

### Situación 3 — El conductor que se calló

- **Qué pasa.** Un conductor asignado a un pasajero deja de reportar su posición. La
  aplicación del pasajero sigue diciendo «tu conductor va en camino». Puede que ya lo haya
  recogido y vaya en viaje sin señal, o que se haya quedado sin conexión antes de llegar.
- **Qué datos hay.** Su último reporte (celda y hora), si ese reporte estaba cerca del
  origen del pasajero, si llegó el evento «pasajero a bordo», lo que dice la aplicación del
  pasajero y el rango de tiempo entre reportes del original.
- **Qué debe deducir.** Si el conductor, con la evidencia que hay, sigue yendo por el
  pasajero, ya lo lleva, o no se puede saber.
- **Qué debe contestar.** Tres veredictos distintos: «reasignar al pasajero», «esperar:
  puede ir en viaje» y «no lo sé», con el dato que haría falta para decidir y el costo
  de equivocarse en cada dirección: un pasajero abandonado o dos coches por el mismo.
- **Por qué es lógica.** «No hay señal» no es «no está» ni «sigue ahí». El estado real
  del viaje no lo mide ningún dato: se deduce de varios y a veces no se puede.

### Situación 4 — Los segundos que se acaban

- **Qué pasa.** Una solicitud lleva varias ofertas: el primer conductor no respondió,
  el segundo rechazó, y mientras tanto el tercero aceptó otro viaje. El pasajero espera
  un plazo para ser asignado y cada conductor tiene un plazo para aceptar. Ofrecer a uno
  tras otro gasta tiempo; ofrecer a dos a la vez arriesga asignar dos coches.
- **Qué datos hay.** La lista de candidatos de la situación 2, la hora de cada oferta, su
  resultado, el momento actual y los plazos del original.
- **Qué debe deducir.** Qué candidatos siguen siendo válidos ahora, cuánto tiempo queda y
  si cabe otra oferta completa.
- **Qué debe contestar.** A quién se ofrece ahora, o que ya no cabe otra y el pasajero
  debe saberlo. Si propone ofertas simultáneas, qué restricción protege para no asignar
  doble. Siempre con la cronología que lo sustenta.
- **Por qué es lógica.** El tiempo restante, la lista viva de candidatos y la regla de
  «un conductor, un pasajero» se combinan; ninguna sola da la respuesta.

### Situación 5 — Concierto: la zona que se quedó sin conductores

- **Qué pasa.** Termina el evento y la demanda se concentra en una celda. Hay conductores
  libres en las vecinas, pero unos ya tienen ofertas pendientes, otros están lejos en
  tiempo y un pasajero cancela justo después de ser asignado, liberando a su conductor
  en medio de la zona. Un pasajero pregunta después por qué le tocó esperar tanto.
- **Qué datos hay.** Solicitudes pendientes por celda, conductores libres por celda, ofertas
  en curso, el nivel de tarifa y la historia de eventos con su hora.
- **Qué debe deducir.** Qué zonas tienen más demanda que oferta alcanzable (la oferta
  real: libres, vigentes, sin oferta pendiente y a un tiempo razonable), si procede
  subir la tarifa, y a quién va el conductor liberado por la cancelación.
- **Qué debe contestar.** Qué zonas están en déficit y por qué; qué pasaría si llegan diez
  conductores más a una vecina; y, mirando el «ahora» de entonces, por qué esa solicitud
  esperó lo que esperó.
- **Por qué es lógica.** El déficit no está en ningún sensor: se deduce de contar y
  descontar. Y la auditoría exige reconstruir la decisión con los hechos de aquel
  momento, no con los de hoy.

## Por qué no basta un script

Con `if hay_conductor_libre(zona): asignar_el_mas_cercano()` asignas un viaje con datos
perfectos y una sola solicitud. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿A quién le ofrezco la solicitud 3? | decisión |
| ¿Por qué a él y no al más cercano en el mapa? | explicación |
| ¿De cuántas formas puedo repartir estas dos solicitudes? | todas las respuestas |
| ¿Qué tendría que pasar para poder reasignar al pasajero del conductor callado? | la pregunta al revés |
| ¿Qué pasa si diez conductores se conectan en la celda vecina? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Optimizas por el conductor más cercano a cada pasajero o por la menor espera total?
   ¿Dónde queda escrito cuál manda y a quién se le falla?
2. ¿Quién es el dueño del estado de un conductor, y qué haces cuando dos fuentes dicen
   cosas distintas?
3. ¿Cómo distingue tu gemelo «no hay conductor» de «no sé si hay conductor»?
4. ¿Qué parte de la explicación le sirve al operador y qué parte es ruido?
5. ¿Qué proceso de tu simulación en Erlang (el conductor, el viaje, la zona) podría
   alimentar a este gemelo con sus hechos?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la plataforma, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar solicitudes simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 12 celdas, 12 conductores y 8 solicitudes, contra los 2,000
  conductores y las 100 solicitudes por minuto del escenario original.
- La vecindad entre celdas, el canal con pocos puentes, los tiempos de viaje entre
  vecinas (no simétricos), los asientos y la accesibilidad de cada vehículo son datos
  inventados que defines tú. No son cifras reales de Tijuana.
- El «ahora» es un hecho del modelo, en segundos, no el reloj del sistema.
- Quedan a decisión del estudiante: cuántas celdas de distancia se miran, qué tiempo de
  llegada es razonable, cuánto silencio vuelve dudosa la posición de un conductor, cuál
  es el plazo del pasajero entre 10 y 30 s, y qué cuenta como déficit de una zona.
- Los identificadores de los ejemplos («solicitud 3», «diez conductores más», «cuatro asientos») son
  ilustrativos.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Viaje compartido: dos pasajeros en el mismo coche con desvíos aceptables.
- Conductores que rechazan por el destino y cómo eso cambia su prioridad.
- Zonas donde no se puede recoger (garitas, aeropuerto) y puntos de ascenso alternos.
- Pasajero que no aparece en el punto de recogida y cuánto se le espera.
- Cancelaciones frecuentes de un mismo pasajero o conductor y cómo afectan la oferta.

---
*Las cifras de dominio (posición cada 4-5 s, plazo del pasajero de 10-30 s, plazo del
conductor de 10-15 s, cancelaciones de 5-15 %, 2,000 conductores, 100 solicitudes por
minuto, hexágonos H3 de resolución 8 de unos 0.74 km²) vienen del problema original.
Verifica la fuente vigente antes de citarlas en tu entrega.*
