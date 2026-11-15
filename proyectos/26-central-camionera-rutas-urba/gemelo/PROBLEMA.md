# #26 — Central camionera / rutas urbanas: gemelo digital con programación lógica

> Extensión del proyecto #26. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang sigues unidades: un proceso por unidad con su posición, un proceso
por ruta con sus paradas y un calculador de llegada estimada. Esa simulación responde
«¿dónde va cada unidad y a qué hora llega?». El pasajero y quien despacha en la central
necesitan algo más: «¿qué hago, por dónde llego, a quién le falla esto, y por qué?».

El gemelo digital es el **modelo lógico** de la central y sus rutas: hechos que reflejan
su estado y reglas que reflejan cómo se decide en ellas. Se escribe en Prolog porque lo
que hay que resolver aquí no es dividir distancia entre velocidad, sino deducir qué
unidad es creíble, qué rutas dependen de qué tramo, quién usa el andén y quién cede, y
poder decir «no lo sé» cuando el dato no alcanza.

## La central y sus rutas que se clonan

Una mañana de hora pico en Tijuana, reducida a 3 rutas urbanas (A, B y C) con 8 paradas,
6 unidades urbanas, 2 autobuses foráneos (Ensenada y Mexicali) y 4 andenes en la central.

| Parte | Contenido |
|---|---|
| Entidades | parada → tramo → ruta (secuencia de paradas); unidad; andén; pasajero con boleto |
| Red | los tramos los comparten varias rutas; algunas paradas son de trasbordo |
| Estado por unidad | lecturas GPS con su instante, ruta asignada, ocupación, si va a bordo alguien con boleto foráneo |
| Estado por andén | qué unidad lo ocupa y entre qué instantes; los horarios programados de llegada y salida |
| Eventos | llega una lectura, una unidad deja de reportar, se detiene, un accidente bloquea un tramo, una unidad cambia de ruta, dos foráneos piden andén |
| Decisiones | ¿qué unidad es creíble?, ¿por dónde llego?, ¿quién usa el andén?, ¿espero un trasbordo?, ¿a qué ruta pertenece esta unidad? |

## Situaciones que tu gemelo debe razonar

Cuatro salen del problema original (la 1, la 2, la 3 y la 5, con complementos); la 4 plantea
algo nuevo con sus datos: el trasbordo que choca con el andén, que sale del foco de
«trasbordos» del proyecto. En cada una, tu gemelo debe llegar a una decisión **y poder
explicarla**.

### Situación 1 — La unidad más cercana no es la que llega primero

- **Qué pasa.** Una pasajera espera en una parada de la ruta B. La app muestra una unidad a
  pocas cuadras; pero lleva 15 minutos casi sin moverse por una avería. Otra va más lejos,
  pero avanza. Una tercera dejó de reportar al entrar a una zona sin señal. Y una lectura
  salta mucho más de lo que explica el error normal del GPS.
- **Qué datos hay.** Lecturas cada 10 s con su instante y su posición, el error normal del
  GPS (5 a 15 m), la velocidad típica en hora pico (15 a 20 km/h) y la ruta con sus
  paradas. Ningún dato dice «detenida», «averiada», «sin señal» ni «llega en tantos
  minutos».
- **Qué debe deducir.** El estado de cada unidad (avanza, detenida, sin dato, lectura
  imposible) y, solo para las que tienen base, su llegada a la parada. Un silencio puede
  ser un túnel, una falla o un fuera de servicio; los datos no distinguen cuál.
- **Qué debe contestar.** El orden probable de llegada con la base de cada una (medida,
  inferida o «no lo sé») y su edad; qué unidades se excluyen y por qué; qué lectura
  resolvería la duda. Intuitivo: la más cercana llega primero. Aquí es falso.
- **Por qué es lógica.** Dos unidades con la misma distancia valen distinto según su
  historia. Quien confía en una llegada sin base espera en vano y pierde su cita.

### Situación 2 — El accidente y las rutas que se quedaron sin salida

- **Qué pasa.** Un accidente bloquea una avenida que cruzan varias rutas. Un pasajero espera
  en una parada de la ruta A y debe llegar a la central. Su ruta directa usa el tramo
  bloqueado. Otras rutas pasan cerca; una exige trasbordo, y otra comparte el tramo
  bloqueado más adelante, aunque no lo parezca. Nadie sabe cuándo se despejará.
- **Qué datos hay.** La red de tramos, las rutas como secuencias de paradas, qué paradas
  son de trasbordo, el aviso de bloqueo con su instante y las posiciones de las unidades.
  Ningún dato dice «ruta afectada», «parada aislada» ni «unidad atrapada».
- **Qué debe deducir.** Qué rutas, paradas y unidades dependen del tramo bloqueado, directa
  o indirectamente, y qué paradas quedan sin servicio. Todas las maneras de llegar a la
  central desde esa parada, con sus trasbordos y su llegada estimada.
- **Qué debe contestar.** Todas las alternativas viables con su base; cuáles dependen del
  bloqueo sin que se note; y, si ninguna existe, que no hay y por qué. Intuitivo: esperar
  la ruta directa, que no cambió. Aquí un trasbordo puede ganarle.
- **Por qué es lógica.** La dependencia es un camino por recorrer en una red, no un campo
  de una ruta. Un solo hecho (el bloqueo) cambia varias respuestas a la vez.

### Situación 3 — Dos foráneos piden el mismo andén

- **Qué pasa.** El autobús a Ensenada y el de Mexicali piden el mismo andén en horas que se
  traslapan. Una unidad averiada sigue ocupando otro andén de la central, y uno de los
  foráneos llega con retraso. Con andenes limitados, no siempre cabe todo.
- **Qué datos hay.** Los andenes, los horarios programados, las ocupaciones vigentes, los
  retrasos observados y la avería. Ningún dato dice «traslape»: se deduce de las horas
  reales, no de las programadas.
- **Qué debe deducir.** Qué asignaciones son posibles con las horas reales y cuáles solo
  con las programadas. Si el reparto perfecto no existe, cuáles son los menos malos.
- **Qué debe contestar.** Todos los repartos válidos; si no hay, quién se queda sin andén y
  por qué. Por qué uno gana el andén y qué tendría que cambiar para que el otro entre.
- **Por qué es lógica.** Las restricciones se declaran una vez; los repartos salen de
  ellas. Cuando falta un andén, decir «no cabe, y esto lo impide» es la respuesta.

### Situación 4 — El trasbordo que espera y el andén que no alcanza

- **Qué pasa.** Por el accidente, un urbano llega tarde a la central con pasajeros que
  traen boleto para el foráneo a Ensenada, que sale pronto. Esperarlos ocupa el andén más
  tiempo, retrasa a quienes ya están a bordo y estorba al foráneo de Mexicali. Salir a
  tiempo deja a los del trasbordo en tierra hasta el siguiente.
- **Qué datos hay.** Los boletos, quién va a bordo de cada unidad, la llegada estimada del
  urbano con su base, los horarios y la ocupación de los andenes. Ningún dato dice
  «trasbordo perdido».
- **Qué debe deducir.** Una cadena: el bloqueo retiene al urbano; su llegada cae antes o
  después de la salida; eso pone en riesgo a sus pasajeros; esperarlos ocupa un andén;
  eso afecta a otro foráneo. Si la llegada del urbano no tiene buena base, el trasbordo
  es «en duda», no «perdido».
- **Qué debe contestar.** Las opciones (esperar o salir) con a quién se le falla en cada
  una y con qué hechos; qué habría que saber para decidir. Intuitivo: esperar al que
  viene retrasado para no dejar a nadie. Puede perjudicar a más gente de la que salva.
- **Por qué es lógica.** Dos partes tienen razón y la regla debe decidir y justificar a
  quién se le falla. Es una cascada: cada paso depende del anterior.

### Situación 5 — La unidad que cambió de ruta y las que van en bola

- **Qué pasa.** Una unidad de la ruta A, a mitad del viaje, entra a un tramo que comparten
  A y B, y nadie avisó si cambió de ruta. En la ruta C, dos unidades se acercan tanto que
  viajan juntas, y atrás queda un hueco largo.
- **Qué datos hay.** Lecturas, qué tramos y paradas son exclusivos de una ruta y cuáles se
  comparten, el aviso de cambio (a veces falta) y los horarios. Ningún dato dice a qué
  ruta pertenece una unidad ahora ni que dos unidades van en bola.
- **Qué debe deducir.** En un tramo común no se sabe a qué ruta pertenece la unidad; al
  pasar por uno exclusivo, sí. Qué paradas deben dejar de esperarla y cuáles no. Que dos
  unidades de una misma ruta, juntas, no son dos llegadas independientes, y cuánto hueco
  queda detrás.
- **Qué debe contestar.** Por parada, las unidades que se esperan con su base; las que
  están «en duda» entre dos rutas; el hueco; qué lectura aclararía. Intuitivo: dos
  unidades cerca son el doble de servicio. Aquí no.
- **Por qué es lógica.** Es razonar sobre relaciones entre unidades, rutas y tramos con
  tres respuestas posibles: «sí», «no» y «no lo sé».

## Por qué no basta un script

Con `eta = distancia_restante / velocidad_promedio` obtienes una llegada con una unidad
que reporta bien. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Cuándo llega la ruta B a la parada de la Zona Río? | decisión |
| ¿Por qué no cuentas la unidad 4, si está más cerca? | explicación |
| ¿Cómo llego del Centro a la central con la avenida bloqueada? | todas las respuestas |
| ¿Qué tendría que pasar para esperar al urbano sin quitarle el andén al de Mexicali? | la pregunta al revés |
| ¿Qué pasaría si el accidente tarda 20 minutos más en despejarse? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Cómo representas el «progreso» de una unidad sobre una ruta, cuando varias rutas
   comparten tramos?
2. ¿Qué tan vieja puede ser una posición para seguir mostrándola, y qué muestra tu gemelo
   cuando pasa ese límite?
3. ¿Cómo distingue tu gemelo «detenida», «sin señal» y «fuera de servicio»?
4. Cuando el trasbordo y el andén chocan, ¿dónde queda escrito quién cede?
5. ¿Qué proceso de tu simulación en Erlang (una unidad, una ruta, el calculador de llegada)
   podría alimentar a este gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la red y las unidades, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar posiciones simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 3 rutas, 8 paradas, 6 unidades urbanas, 2 foráneos y 4 andenes, contra
  las 30 unidades, 6 rutas y 12 andenes del escenario original.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas se
  puedan repetir. Los instantes se expresan en segundos desde el inicio de la jornada.
- La red, los nombres de rutas y paradas, los boletos y quién va a bordo son de esta
  extensión: son datos del ejercicio, no estadísticas ni datos de rutas reales.
- Los defines tú y los declaras: cuánto silencio vuelve dudosa a una unidad, qué salto es
  imposible, cuánto tarda un trasbordo a pie, el tiempo de abordaje y de rotación en el
  andén, cuánto se espera un trasbordo, quién tiene prioridad en el andén y cuánto tarda
  en despejarse un bloqueo.
- Los identificadores y cantidades de los ejemplos («unidad 4», «20 minutos») son
  ilustrativos.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Lluvia o neblina que cambian las velocidades de todo un corredor.
- Cambio de turno de los conductores y unidades que salen de servicio.
- Integración tarifaria y transbordo gratuito entre rutas.
- Pasajeros con necesidades de accesibilidad y unidades que las atienden.
- Desvíos programados por obras o eventos masivos.

---
*Las cifras del dominio (GPS con error de 5 a 15 m, reporte cada 10 s, velocidad urbana de
15 a 20 km/h en hora pico, unidad detenida 15 min, 30 unidades, 6 rutas y 12 andenes)
vienen del problema original y son órdenes de magnitud; verifica la fuente vigente antes
de citarlas. La escala reducida, la red y los boletos son de esta extensión.*
