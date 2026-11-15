# #7 — Control de acceso: gemelo digital con programación lógica

> Extensión del proyecto #7. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el control de acceso: una puerta por proceso, una bitácora
que no pierde eventos, tarjetas que se revocan. Esa simulación responde «¿qué pasó?». El
jefe de seguridad de la planta necesita algo más: «¿esa persona debía pasar, y por qué?
¿a quién le fallamos cuando dos reglas chocan?».

El gemelo digital es el **modelo lógico** de la planta: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque lo que hay que
resolver aquí no es calcular, sino deducir, justificar y desempatar.

## La planta que se clona

Una planta maquiladora de Tijuana con turnos continuos, reducida a 5 puertas y 8 personas.

| Parte | Contenido |
|---|---|
| Entidades | planta → zona → puerta → lector; persona → rol → tarjeta |
| Zonas | calle, planta (producción), almacén de insumos, oficinas |
| Puertas | acceso principal (un lector de entrada y otro de salida), línea de producción, almacén, oficinas y la salida de emergencia del almacén |
| Personas | operadores de tres turnos, supervisora, almacenista, mantenimiento, vigilante y un visitante |
| Estado por puerta | modo de falla (cerrada o abierta sin energía), energía, si es salida de emergencia, contacto abierto o cerrado, conteo de personas que cruzan, última vez que habló con el servidor |
| Estado por persona | rol, turno, tarjeta (activa, reportada, revocada), excepciones vigentes |
| Eventos | un lector lee una tarjeta, una puerta se abre o se cierra, se reporta una tarjeta, una puerta se sincroniza, suena la alarma de incendio, se va la energía |
| Decisiones | ¿abrir?, ¿alertar a vigilancia?, ¿quién está dentro?, ¿qué puerta aún acepta esta tarjeta? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original (reglas comunes, escenario, casos difíciles y modos
de falla); cada una añade un elemento derivado que se señala. En cada una, tu gemelo debe
llegar a una decisión **y poder explicarla**.

### Situación 1 — ¿Le toca entrar a esta hora?

- **Qué pasa.** Cambio de turno, con fila en el acceso. Iván, operador del turno
  vespertino, pasa su tarjeta en la línea de producción antes de que empiece su turno:
  Marta, la supervisora, le pidió llegar antes para cubrir una vacante (excepción,
  elemento derivado). A la vez, el visitante intenta abrir las oficinas con una tarjeta
  activa. Negar a Iván retrasa la línea; abrir al visitante deja a un extraño adentro.
- **Qué datos hay.** Rol y turno de cada persona, qué zonas permite cada rol en cada
  turno, estado de la tarjeta, excepciones registradas (quién las dio, para quién y
  hasta cuándo). Ningún dato dice «tiene derecho».
- **Qué debe deducir.** Si la persona tiene derecho a esa puerta en ese instante: sale
  de encadenar rol, turno asignado, horario de la zona, estado de la tarjeta y, si la
  hay, una excepción vigente y la facultad de quien la dio.
- **Qué debe contestar.** Abrir o negar, con la razón; si negó, qué tendría que ser
  distinto para abrir; y quiénes podrían pasar por esa puerta ahora.
- **Por qué es lógica.** El permiso se concluye de varias relaciones, y una excepción
  cambia la conclusión sin tocar la regla general.

### Situación 2 — Entró, salió y el sistema no se enteró

- **Qué pasa.** El anti-passback no deja entrar dos veces sin salir. El acceso principal
  tiene un lector de entrada y otro de salida, cada uno con su reloj, y en el cambio de
  turno uno de ellos manda sus eventos con retraso. Rosa salió, volvió por su
  chamarra y pasa la tarjeta para entrar de nuevo; la bitácora aún no recibe su salida.
  En otro caso, parecido por fuera, alguien reutiliza la tarjeta de un compañero que
  entró hace poco para pasar a otra persona. Negar a Rosa la deja atrapada afuera;
  abrir al reutilizador rompe la regla.
- **Qué datos hay.** Eventos de ambos lectores con el instante que marcó cada reloj y el
  instante en que llegaron a la bitácora, y cuál lector es de entrada y cuál de salida.
- **Qué debe deducir.** Dónde está cada persona (fuera, dentro o no se sabe): ningún
  sensor lo mide. Y cuándo el orden de los eventos alcanza para saberlo y cuándo no.
- **Qué debe contestar.** Abrir, negar o «no se sabe» con lo que la política decide en
  esa duda, la evidencia de cada caso, y quién está dentro de la planta ahora.
- **Por qué es lógica.** Es razonar sobre una secuencia cuyo orden puede ser incierto, y
  separar «no ha salido» de «no me he enterado de que salió».

### Situación 3 — La tarjeta robada que ya abrió tres puertas

- **Qué pasa.** Una tarjeta reportada como robada se usa 3 veces en 1 minuto, en puertas
  distintas, con el servidor central incomunicado 30 minutos. La revocación existe en el
  servidor, pero cada puerta solo la conoce hasta que se sincroniza. Revocar sin matices
  castiga a la dueña, que quizá hizo uno de esos usos antes de perderla; no hacerlo
  deja al ladrón abriendo puertas.
- **Qué datos hay.** Cuándo se reportó y cuándo se revocó, la última sincronización de
  cada puerta, los tres usos con puerta e instante y la distancia a pie entre puertas
  (dato derivado, propio de esta extensión).
- **Qué debe deducir.** Qué puertas aceptarían todavía esa tarjeta (ninguna lo
  informa), cuáles usos son compatibles con una sola persona y cuáles ocurrieron antes
  de que la puerta pudiera saberlo.
- **Qué debe contestar.** Puertas expuestas y usos sospechosos con su evidencia; y la
  hipótesis: «¿qué habría pasado si el reporte llega antes del primer uso?».
- **Por qué es lógica.** Hay dos verdades, la del servidor y la de cada puerta, y la
  auditoría necesita razonar con la segunda.

### Situación 4 — Hay fuego, no hay luz y una tarjeta revocada adentro

- **Qué pasa.** Suena la alarma de incendio y se va la energía. En el almacén, que guarda
  insumos de valor, la bitácora dice que están Luis, el almacenista, y quien entró con la
  tarjeta ya revocada. Las salidas de emergencia deben abrir siempre (NOM-002-STPS-2010),
  pero la puerta de entrada del almacén queda cerrada sin energía y seguridad patrimonial
  no quiere que una tarjeta revocada abra nada. Las dos partes tienen razón.
- **Qué datos hay.** Modo de falla de cada puerta, cuál es salida de emergencia, estado de
  la energía y de la alarma, quién está adentro según la bitácora y estado de cada tarjeta.
- **Qué debe deducir.** Qué puertas quedan abiertas o cerradas sin energía (no hay sensor
  que lo diga), por dónde puede salir cada persona y quién queda sin salida. Cada paso
  depende del anterior, y lo que parece más seguro quizá no lo sea.
- **Qué debe contestar.** Por dónde sale cada persona, qué se abre, qué se queda cerrado,
  a quién avisar, y quién gana: si hay que fallarle a alguien, a quién y por qué.
- **Por qué es lógica.** Es un desempate entre reglas que valen, con una explicación
  que seguridad pueda defender ante una auditoría.

### Situación 5 — La puerta que se abrió y nadie la abrió (o la abrieron dos)

- **Qué pasa.** La puerta del almacén tiene tres señales: el lector (acceso concedido),
  el sensor de contacto (abierta o cerrada) y el contador de paso (cuántos cruzan). Una
  tarde, la puerta se abre sin ningún acceso concedido antes, aunque el técnico de
  mantenimiento tenía una orden de trabajo en esa puerta y usa llave mecánica. Otro día,
  hay un acceso concedido y cruzan dos personas. Otro, la puerta queda abierta mucho
  después de un acceso normal. Si se despierta al guardia en vano se pierde su confianza;
  si no se le despierta, entra alguien.
- **Qué datos hay.** Eventos del lector, lecturas de contacto y de paso con su instante,
  órdenes de trabajo (dato derivado) y el rango físico de cada sensor.
- **Qué debe deducir.** Si fue puerta forzada, tailgating, puerta abierta de más o una
  apertura autorizada fuera del lector: ningún sensor dice cuál, se deduce de cómo
  coinciden o no las tres señales. Y si falta una señal, que no se sabe.
- **Qué debe contestar.** Qué alertar y a quién despertar, con qué evidencia, y por qué
  no es un forzamiento cuando lo parece (o sí lo es cuando no lo parece).
- **Por qué es lógica.** Las órdenes y los sensores se contradicen y el gemelo debe
  decir cuál le cree, sin confundir «cerrada» con «no reporta».

## Por qué no basta un script

Con `if tarjeta in permitidas[puerta]: abrir()` resuelves una puerta con una tarjeta
perfecta. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué hago con la tarjeta de Iván en la línea? | decisión |
| ¿Por qué se negó la entrada de Rosa? | explicación |
| ¿Quiénes están ahora dentro del almacén? | todas las respuestas |
| ¿Qué tendría que cambiar para que el visitante abriera las oficinas? | la pregunta al revés |
| ¿Qué habría pasado si el reporte llega antes del primer uso? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco consultas
sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el programa.

## Preguntas guía

1. ¿Qué hechos necesitas para saber, en un instante, quién está dentro y qué sabe cada
   puerta?
2. Cuando dos reglas chocan (emergencia y revocación, horario y excepción), ¿dónde queda
   escrito cuál gana y a quién se le falla?
3. ¿Cómo distingue tu gemelo «no pasó» de «no me enteré de que pasó»?
4. ¿Qué eventos son críticos y no pueden descartarse bajo carga, y qué parte de la
   explicación sirve al guardia y qué parte al auditor?
5. ¿Qué hace cada puerta de tu simulación en Erlang cuando no puede consultar al
   servidor, y qué sabría tu gemelo de esa puerta en ese momento?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la planta, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar eventos o graficar.

## Supuestos de esta extensión

- Escala reducida: 5 puertas, 8 personas y 4 zonas, contra las 40 puertas, 2,000
  personas y picos de 150 lecturas por minuto del escenario original.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas se
  puedan repetir. El tiempo de respuesta de la puerta del original no se evalúa aquí.
- Los nombres de personas y las tarjetas de los ejemplos son solo ilustrativos.
- Los define el estudiante: horarios de cada turno, qué rol entra a qué zona, cuánto es
  «demasiado tiempo» con la puerta abierta, qué desfase tolera entre relojes, qué hace la
  política en la duda, quién puede dar excepciones y las distancias entre puertas.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Contratistas con tarjeta temporal, con vigencia y acompañante obligado.
- Aforo máximo por zona y qué pasa al alcanzarlo en un simulacro.
- Ruta de evacuación como grafo, con puertas que se bloquean por humo.

---
*Las cifras (3 usos en 1 minuto, 30 minutos de servidor incomunicado, NOM-002-STPS-2010,
40 puertas, 2,000 personas, 150 lecturas por minuto) son de referencia y vienen del
problema original. Verifica la fuente vigente antes de citarlas en tu entrega.*
