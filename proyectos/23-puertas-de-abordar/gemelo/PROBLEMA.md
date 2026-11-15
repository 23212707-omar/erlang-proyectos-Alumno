# #23 — Puertas de abordar: gemelo digital con programación lógica

> Extensión del proyecto #23. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la asignación de puertas: un asignador, una máquina de
estados por puerta (libre, asignada, abordando) y una cola de vuelos sin puerta. Esa
simulación responde «¿qué puerta tiene cada vuelo ahora?». Quien opera la terminal
necesita algo más: «¿a qué puerta debe ir cada vuelo, qué pasa si algo cambia, a quién
hay que avisar y por qué?».

El gemelo digital es el **modelo lógico** de la terminal: hechos que reflejan su estado
y reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque lo que hay que
resolver no es calcular una hora, sino acomodar sin contradicciones, justificar cada
cambio y saber decir «no lo sé».

## La terminal que se clona

Una jornada de una terminal compacta como la de TIJ, reducida a 5 puertas más una
posición remota con autobús, 10 vuelos y 3 tipos de aeronave. El escenario es el del
problema original, a escala pequeña; los complementos que no trae se listan en
«Supuestos».

| Parte | Contenido |
|---|---|
| Entidades | terminal → puertas y posición remota; vuelos con aerolínea y aeronave; operadores |
| Estado por puerta | tamaño de aeronave que admite, si es nacional o internacional (aduana), si está en mantenimiento o fuera de servicio y hasta cuándo |
| Estado por vuelo | alcance (nacional o internacional), aeronave, pasajeros, hora programada, estimada y real de llegada y de salida, puerta asignada, si esa puerta ya se anunció a los pasajeros, si ya abordan |
| Eventos | un vuelo se demora, una aeronave llega o sale, una puerta sale de servicio, un operador asigna o reasigna una puerta, se anuncia un cambio |
| Decisiones | ¿a qué puerta va cada vuelo?, ¿cuáles vuelos chocan?, ¿a quién hay que mover y a quién avisar?, ¿qué se hace cuando no hay solución perfecta? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original (sus datos del mundo real, su escenario y sus casos
difíciles). La 5 añade un complemento que el original no trae y que se declara en
«Supuestos». En cada una, tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — La puerta que todavía no está libre

- **Qué pasa.** El vuelo 4 está demorado y su aeronave sigue en la puerta 2. La aeronave
  del vuelo 7 ya va hacia esa misma puerta, que el horario le había dado. Una puerta debe
  estar libre desde que llega la aeronave hasta que se va, más un colchón de seguridad;
  un vuelo angosto tarda 40-60 min en rotación y el abordaje dura 25-35. La nueva hora
  de salida del 4 la dio la aerolínea, pero nadie ha confirmado que ya cerró.
- **Qué datos hay.** Horarios programados, estimados y reales; tipo de aeronave y
  rotación; asignaciones vigentes. Ningún dato dice «la puerta estará ocupada hasta tal
  hora» ni «hay un conflicto».
- **Qué debe deducir.** El intervalo de ocupación real de cada vuelo, qué pares se
  traslapan en una misma puerta y por cuánto; y, donde una hora no está confirmada, si el
  choque es seguro, descartado o dudoso.
- **Qué debe contestar.** Qué vuelos chocan, en qué puerta y en qué tramo; cuáles choques
  dependen de un dato sin confirmar; y qué hora de salida del 4 haría desaparecer el
  choque.
- **Por qué es lógica.** El conflicto no es un dato: es una relación entre intervalos que
  se mueve con cada demora. «Libre según el horario» no es lo mismo que «libre».

### Situación 2 — Se cae una puerta a mediodía y arrastra a las demás

- **Qué pasa.** A medio día la puerta 3 sale de servicio de repente. Era una de las dos
  puertas internacionales con espacio para aeronaves grandes y tenía el vuelo 9. Las
  puertas que sí le sirven al 9 están ocupadas por vuelos que a su vez solo caben en
  ciertas puertas; mover uno obliga a mover otro. Algunos pasajeros ya vieron su puerta
  en las pantallas y otros no.
- **Qué datos hay.** Qué puerta falló y desde cuándo; qué admite cada puerta (tamaño,
  nacional o internacional); asignaciones vigentes; cuáles ya se anunciaron; pasajeros
  por vuelo; cuáles vuelos ya abordan.
- **Qué debe deducir.** Qué vuelos quedan sin puerta válida y, de ahí, cuáles más tienen
  que moverse: cuáles movimientos son forzados y cuáles opcionales.
- **Qué debe contestar.** El plan completo de reasignaciones, a quién hay que avisar y,
  si hay varios planes válidos, cuáles son y qué cuesta cada uno en vuelos movidos y en
  pasajeros ya informados. Si no hay plan, el motivo.
- **Por qué es lógica.** Cada movimiento nace de otro: la cadena se deduce, no se
  recorre con un ciclo. Lo intuitivo es el plan que mueve menos vuelos; es sospechoso
  porque un solo vuelo ya anunciado y de aeronave grande puede confundir a más gente que
  dos cuya puerta nadie había visto aún.

### Situación 3 — Dos vuelos demorados, una puerta, y razón de ambos

- **Qué pasa.** Dos vuelos demorados compiten ahora por la puerta 2. La aerolínea del
  vuelo 11 tiene preferencia por esa puerta, su puerta ya se anunció y sus pasajeros
  (150-190) están en la sala. El vuelo 8 es de otra aerolínea y su puerta aún no se ha
  anunciado, pero su demora lo trajo justo al hueco que el 11 esperaba. Solo queda una
  posición remota con autobús para el que no se quede con la 2.
- **Qué datos hay.** Horarios estimados de ambos, preferencias de aerolínea, anuncios
  hechos, pasajeros, y qué admite la posición remota.
- **Qué debe deducir.** Que los dos no caben en la puerta 2 y qué ocurre con cada
  reparto posible; y cuál reparto respeta qué.
- **Qué debe contestar.** Quién se queda con la puerta, a quién se le falla y por qué ese
  criterio y no otro; qué se le ofrece al otro; y qué tendría que cambiar (por ejemplo,
  otra demora) para que la respuesta fuera la contraria.
- **Por qué es lógica.** Es un dilema: respetar lo ya prometido a los pasajeros y
  respetar la preferencia de la aerolínea son dos razones válidas que chocan. La regla
  que desempata debe estar escrita una vez y poder justificarse ante quien pierde.

### Situación 4 — Sobran puertas y aun así no cabe

- **Qué pasa.** Por la tarde, las demoras apilan varios vuelos en la misma franja. Hay
  más puertas que vuelos, pero dos vuelos son internacionales y en esa franja solo una
  puerta con aduana está disponible; una aeronave grande solo cabe en dos puertas y una está en mantenimiento, cuyo
  fin el taller anunció como «pronto», sin hora. No hay solución perfecta.
- **Qué datos hay.** Puertas con sus capacidades, vuelos con sus requisitos, franjas
  de ocupación de la Situación 1 y el mantenimiento con su hora de fin desconocida.
- **Qué debe deducir.** Que no existe un reparto válido y por qué: qué vuelos y qué
  restricciones lo hacen imposible, aunque el conteo de puertas sugiera lo contrario.
  Qué se tendría que relajar para que exista uno.
- **Qué debe contestar.** «No hay reparto perfecto», el motivo, las opciones imperfectas
  (remota con autobús, esperar, una puerta no preferida) con lo que cada una sacrifica y
  a quién; y qué pasa si el mantenimiento termina a tiempo y si no.
- **Por qué es lógica.** El número de puertas no dice cuántas sirven: cada vuelo tiene
  las suyas. «Cuál se elige cuando no hay solución perfecta» solo se responde si el
  criterio de lo imperfecto está declarado. Y «el fin del mantenimiento no se sabe» no
  es «terminó» ni «no terminó».

### Situación 5 — Dos operadores, la misma puerta

- **Qué pasa.** Dos operadores reasignan la puerta 4 a la vez: uno manda allí el vuelo 6
  y otro el vuelo 8. Además, el sistema da por salido al vuelo 3, pero el personal de
  rampa avisa que su aeronave sigue en esa puerta. Los pasajeros del 6 y del 8 pueden
  caminar hacia una puerta que no les corresponde.
- **Qué datos hay.** Las dos órdenes con operador y marca de tiempo (pueden coincidir o
  estar desfasadas), el aviso de rampa y el registro de salida del vuelo 3.
- **Qué debe deducir.** Que las órdenes no pueden valer a la vez; cuál queda vigente y
  cuál desplazada, o que con estos datos no se sabe; en qué estado queda la puerta 4; y
  de ahí qué vuelo queda sin puerta y a quién hay que avisar.
- **Qué debe contestar.** Un veredicto por orden (vigente, desplazada o no se sabe), la
  lista de avisos con su razón, y qué dato haría falta para decidir.
- **Por qué es lógica.** Hay un conflicto entre acciones y otro entre dos fuentes: lo que
  el sistema dice contra lo que ve la rampa. La decisión encadena varios hechos y debe
  poder explicarse a quien pierde.

## Por qué no basta un script

Con `if puerta.libre: asignar(vuelo, puerta)` acomodas un vuelo con horarios perfectos y
sin nadie más pidiendo puerta. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿A qué puerta mando el vuelo 7? | decisión |
| ¿Por qué no a la 2? | explicación |
| ¿De cuántas formas caben los vuelos de la tarde? | todas las respuestas |
| ¿Qué tendría que pasar para que el vuelo 9 use la puerta 2? | la pregunta al revés |
| ¿Qué pasa si la puerta 3 sale de servicio ahora? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué significa «ocupar una puerta», y cuándo empieza y termina?
2. ¿Cuánto cambio es aceptable para no confundir a los pasajeros, y dónde queda escrito?
3. ¿Cómo distingue tu gemelo «no hay conflicto» de «no sé si hay conflicto»?
4. Cuando no hay solución perfecta, ¿dónde queda escrito qué se sacrifica y a quién?
5. En Erlang cada puerta es una máquina de estados y el asignador decide. ¿Qué de eso
   podría alimentar a este gemelo, y qué decide el gemelo que el proceso no puede?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la terminal, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra el reparto
  de puertas con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar demoras simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 5 puertas y una posición remota, 10 vuelos y 3 tipos de aeronave,
  contra las 8 puertas, 60 vuelos y 3 tipos del escenario original. Los nombres de los
  tipos (por ejemplo regional, angosto y ancho) los pones tú.
- Los números de vuelo y de puerta de los ejemplos son ilustrativos; defines cuáles
  puertas son internacionales, qué tamaño admite cada una y quién tiene preferencia.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir.
- Complementos que el original no trae: el aviso del personal de rampa (Situación 5),
  los operadores con su turno, y el anuncio de la puerta a los pasajeros como hecho con
  su hora.
- Tú defines: el colchón de seguridad y la rotación de las aeronaves que no son
  angostas; cuánto cambio es aceptable; qué costo minimiza un plan (vuelos movidos,
  pasajeros afectados u otro); cuándo ya es demasiado tarde para mover un vuelo; qué
  operador o marca de tiempo manda; y cuánto es «pronto» en el mantenimiento. Decláralo.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Conexiones de pasajeros entre vuelos y tiempo para llegar de una puerta a otra.
- Compartir una puerta entre aerolíneas por franjas.
- Mantenimiento programado de puertas y su efecto en el reparto de la semana.
- Servicios en tierra (combustible, equipaje, limpieza) que alargan la rotación.
- Cambio de aeronave de última hora: el vuelo ya no es del tamaño que se asignó.

---
*Las cifras (8 puertas, 60 vuelos, 3 tipos de aeronave, rotación de 40-60 min, abordaje
de 25-35 min, 150-190 pasajeros) vienen del problema original; lo demás es escala o
complemento declarado arriba. Verifica la fuente vigente antes de citarlas en tu entrega.*
