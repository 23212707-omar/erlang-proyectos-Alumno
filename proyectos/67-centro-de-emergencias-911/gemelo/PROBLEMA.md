# #67 — Centro de emergencias 911: gemelo digital con programación lógica

> Extensión del proyecto #67. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el centro de emergencias: un proceso por incidente que
pasa de recibido a cerrado, un proceso por unidad con su posición y su estado, un
selector de la unidad más cercana, fallas inyectadas. Esa simulación responde «¿qué está
pasando con cada incidente?». El centro necesita algo más: «¿a quién mando, a quién le
quito una unidad, a quién le fallo, y por qué esa respuesta y no otra?».

El gemelo digital es el **modelo lógico** del centro: hechos que reflejan su estado
(unidades, incidentes, llamadas, calles) y reglas que reflejan cómo se despacha. Se
escribe en Prolog porque lo que hay que resolver aquí no es contar llamadas, sino repartir
lo escaso sin contradicciones, justificar a quién se le falla y saber decir «no lo sé».

## El centro que se clona

El centro de despacho de una ciudad de frontera, un turno de 8 horas, reducido a 8
unidades de 4 tipos (ambulancia, patrulla, bomberos, protección civil), 4 zonas con unos
10 puntos de la red de calles y unos 5 incidentes abiertos al mismo tiempo.

| Parte | Contenido |
|---|---|
| Entidades | centro → zona → punto de la red; unidades (de 4 tipos); llamadas; incidentes |
| Estado por unidad | tipo, estado (disponible, despachada, en camino, en escena, trasladando, fuera de servicio), últimos reportes de posición con su instante |
| Estado por incidente | tipo, lugar, prioridad (1, 2 o 3), qué unidades pide y cuáles tiene asignadas |
| Estado por llamada | quién y desde dónde llama, qué reporta, cuándo, a qué incidente se atribuye |
| La red | tramos entre puntos con su tiempo de viaje; algunos cruzan un cañón o la garita |
| Eventos | entra una llamada, se clasifica un incidente, se despacha, una unidad avanza o se queda sin contacto, llega, traslada, se libera |
| Decisiones | ¿qué unidad va?, ¿a quién se le quita?, ¿esta llamada es otro incidente?, ¿confío en que la unidad avanza? |

## Situaciones que tu gemelo debe razonar

Cuatro de las cinco salen del problema original (la 1, la 2, la 3 y la 4). La quinta
parte de la crisis (sismo, evento masivo) que el original menciona y plantea algo nuevo. En cada una, tu gemelo debe llegar
a una decisión **y poder explicarla**.

### Situación 1 — Todas las ambulancias ocupadas y entra una prioridad 1

- **Qué pasa.** Entra un incidente de riesgo inminente de vida y ninguna ambulancia está
  disponible: una va en camino a un incidente de prioridad 3, otra está en escena de uno
  de prioridad 2 y otra va trasladando a un paciente. Una unidad ocupada solo se retira
  por una orden de prioridad superior, y retirarla deja a alguien sin atención.
- **Qué datos hay.** Estado de cada ambulancia, prioridad del incidente que atiende, su
  posición, los tiempos de viaje hasta el nuevo incidente y las demás unidades libres.
- **Qué debe deducir.** Cuáles ambulancias se pueden retirar y cuáles no, cuál conviene
  retirar y qué pasa con el incidente que se queda sin ella.
- **Qué debe contestar.** La unidad elegida, a quién se le falla y por qué, dónde queda el
  incidente desatendido y qué tendría que cambiar para no retirar a nadie. Dos partes
  tienen razón; la regla decide y justifica. Lo intuitivo es retirar la más cercana
  al nuevo incidente: desconfía de eso y razona con el estado de cada una.
- **Por qué es lógica.** La prioridad, el estado y el tiempo de viaje se combinan; no hay
  un número que baste. Y lo desplazado no se descarta: vuelve a quedar pendiente.

### Situación 2 — La unidad más cercana no es la más cercana

- **Qué pasa.** Una ambulancia está a 1 km del incidente, pero al otro lado de un cañón;
  otra está a 3 km por una vía directa. Una tercera va trasladando y quedará libre
  antes que la primera llegue. Además, un tramo de la red está lento por la garita.
- **Qué datos hay.** Posiciones con su instante de reporte, estado de cada unidad, tramos
  de la red con su tiempo de viaje y cuál está afectado. Nadie mide «tiempo de llegada».
- **Qué debe deducir.** Cuánto tardaría cada unidad elegible en llegar, por qué ruta, y
  cuál llega primero, contando también cuándo quedaría libre la que ahora está ocupada.
- **Qué debe contestar.** La unidad y su ruta, por qué no la que está más cerca en línea
  recta, las rutas empatadas si las hay y si alguien llega dentro de la meta de
  referencia del original (~8 min para soporte vital avanzado, ~4 min para bomberos).
- **Por qué es lógica.** «Cerca» es una relación sobre una red, no una distancia. Es
  razonar sobre caminos y dependencias entre el estado y la llegada.

### Situación 3 — Doce llamadas, un solo choque

- **Qué pasa.** Un accidente múltiple genera 12 llamadas (aquí unas pocas). Casi todas
  hablan del mismo choque, pero una viene de una esquina cercana y con otro detalle:
  puede ser el mismo hecho o un segundo accidente. Las unidades alcanzan para uno solo.
- **Qué datos hay.** Cada llamada con lugar, instante, tipo reportado y lo que dice ver
  (vehículos, personas lesionadas). Ningún dato dice a qué incidente pertenece.
- **Qué debe deducir.** Qué llamadas son el mismo incidente, cuáles no, y de cuáles no se
  sabe; y qué prioridad y qué unidades pide el incidente que resulta de unirlas.
- **Qué debe contestar.** Los grupos con la evidencia de cada unión, la llamada dudosa
  marcada como dudosa (ni fusionada ni descartada) y qué cuesta equivocarse en cada
  sentido: fusionar mal deja un incidente real sin unidad; no fusionar manda unidades que
  hacen falta en otra parte. Doce llamadas no son doce incidentes, pero tampoco hay
  que dar por hecho que la última lo sea.
- **Por qué es lógica.** «Mismo incidente» no es un dato: se deduce de coincidencias de
  lugar, tiempo y relato, y a veces la respuesta honesta es «no lo sé».

### Situación 4 — La unidad que dejó de contestar

- **Qué pasa.** Una unidad despachada, «en camino» según el sistema, lleva un rato sin
  reportar su posición. Puede estar en un tramo sin cobertura o haber tenido una falla.
  El incidente al que va es de prioridad 1.
- **Qué datos hay.** La asignación, el estado registrado, los reportes de posición con su
  instante, la bitácora del incidente y las otras unidades con sus tiempos de viaje.
- **Qué debe deducir.** Si la unidad probablemente avanza, si el incidente sigue cubierto
  y qué se sabe de verdad frente a lo que el sistema todavía dice.
- **Qué debe contestar.** Tres respuestas distintas: «llega», «no llega» y «no lo sé». Si
  conviene mandar otra unidad, cuál y de dónde la sacaría, qué incidente descubre y qué
  hacer si la primera reaparece. Silencio no es lo mismo que detenida; el umbral lo
  fijas tú.
- **Por qué es lógica.** El sistema afirma lo que se ordenó; la realidad es lo que se
  sabe. «Está en camino» es una cadena de deducciones, no un hecho: posición vieja,
  llegada incierta, incidente sin garantía, refuerzo, otro incidente descubierto.

### Situación 5 — El sismo: más incidentes que unidades

- **Qué pasa.** Tras un sismo entran a la vez varios incidentes que piden tipos de unidad
  distintos: un incendio con lesionados (bomberos y ambulancia), personas atrapadas
  (protección civil y ambulancia) y un herido (ambulancia). No alcanzan las unidades
  libres, y algunas solo sirven para uno de los incidentes.
- **Qué datos hay.** Los incidentes con su prioridad y los tipos de unidad que piden, las
  unidades libres con su tipo y los tiempos de viaje hasta cada incidente.
- **Qué debe deducir.** Un reparto completo de unidades a incidentes, donde ninguna
  unidad se use dos veces y la prioridad pese, o, si no existe, qué incidentes quedan
  sin cubrir o cubiertos a medias y por qué.
- **Qué debe contestar.** El reparto con su razón por incidente y, al pedir más, los
  demás repartos válidos. Si no hay ninguno completo, lo dice y señala el motivo, sin
  fallar en silencio. Lo intuitivo es dar a cada incidente su unidad más cercana, en
  orden de llegada: puede dejar sin cubrir un incidente que otro reparto sí cubría.
- **Por qué es lógica.** Es asignar recursos escasos con restricciones: el reparto
  de uno cambia lo que le queda a los demás. Por eso se razona sobre el conjunto.

## Por qué no basta un script

Con `unidad = min(libres, key=km_en_linea_recta)` resuelves un incidente con la red
despejada y todas las unidades quietas. Tu gemelo debe contestar, **con las mismas
reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué unidad mando al incidente 3? | decisión |
| ¿Por qué no la ambulancia que está más cerca? | explicación |
| ¿Qué repartos cubren los tres incidentes del sismo? | todas las respuestas |
| ¿Qué falta para que el incidente 5 tenga ambulancia? | la pregunta al revés |
| ¿Qué pasaría si se cierra el tramo de la garita? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué significa «más cercana» y cómo se calcula? (pregunta del original)
2. ¿Qué no puede perderse jamás, aunque todo lo demás falle? ¿Qué debe quedar escrito
   cuando retiras una unidad de un incidente, para que nadie quede olvidado?
3. ¿Cómo distingue tu gemelo «no ha llegado» de «no sé si va en camino»?
4. ¿Cuándo dos llamadas son el mismo incidente, y qué cuesta equivocarse en cada sentido?
5. ¿Qué parte de tu simulación en Erlang (el proceso por incidente, el proceso por
   unidad, la reasignación cuando nadie acepta) podría alimentar a este gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del centro, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra el despacho
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar llamadas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 8 unidades, 4 zonas y unos 10 puntos de la red, contra las 40
  unidades y los 200 incidentes por turno del escenario original.
- El «ahora» es un hecho del modelo, en segundos desde que empieza el turno, no el reloj
  del sistema, para que las respuestas se puedan repetir.
- Los tiempos de viaje de los tramos, las zonas con su nombre, los identificadores
  («incidente 3», «unidad 4») y el número de llamadas de los ejemplos son datos del
  ejercicio, no hechos del mundo ni estadísticas.
- Defines tú, y lo anotas: cuántas unidades de cada tipo pide cada clase de incidente,
  cuánta prioridad hace falta para retirar una unidad, qué tan cerca y qué tan seguidas
  deben ser dos llamadas para unirlas, cuánto silencio vuelve dudosa a una unidad, cuál
  es la meta de respuesta por prioridad y qué tramos están afectados.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Cobertura: no dejar una zona sin ninguna unidad al despachar la más cercana.
- Filtro de llamadas improcedentes: bromas, errores y llamadas de solo información.
- Hospital de destino saturado y a dónde trasladar.
- Cierres de calles por un evento masivo o por el propio sismo.
- Relevo de turno y tripulaciones que no pueden seguir en servicio.

---
*Las cifras de referencia (turno de 8 horas, 40 unidades, 200 incidentes, 12 llamadas,
1 y 3 km, 4 y 8 minutos) vienen del problema original y son órdenes de magnitud. Verifica
la fuente vigente antes de citarlas en tu entrega.*
