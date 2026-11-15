# #11 — Chat o notificaciones: gemelo digital con programación lógica

> Extensión del proyecto #11. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste un chat: un proceso por sala, conexiones que se caen y
vuelven, mensajes que se entregan aunque el destinatario esté desconectado. Esa
simulación responde «¿llegó el mensaje?». Quien coordina personas por ese chat necesita
algo más: «¿quién tenía derecho a verlo, quién lo escribió con autoridad y quién está
realmente enterado?».

El gemelo digital es el **modelo lógico** de la operación: hechos que reflejan su estado
y reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque aquí no se
trata de transportar mensajes, sino de **autorizar, desempatar y justificar** quién ve,
quién escribe y a quién se le puede dar por avisado.

## El mando de incendios que se clona

Un centro de mando de Protección Civil que coordina un incendio forestal en un cañón del
municipio de Tecate, con un chat por salas. **No existe: es un escenario planteado por
esta extensión**; el original solo pide un chat con grupos, confirmaciones y presencia, y
aquí ese chat tiene dueño, jerarquía y consecuencias. Se reduce a 11 personas, 5 salas y
2 zonas. Cada situación ocurre en un momento distinto del incidente.

| Parte | Contenido |
|---|---|
| Entidades | personas con rol y turno; salas (mando, brigada Norte, brigada Sur, albergue, informativa); dispositivos (cada persona tiene un celular; el camión 3 tiene una tablet que usan dos brigadistas); mensajes y órdenes |
| Personas | la coordinadora de mando (Yolanda), el subcoordinador de mando (Raúl), las jefas y jefes de brigada (Héctor en Norte, Marisol en Sur), los brigadistas (Beto, Ximena, Mateo), una voluntaria del albergue (Dulce), el enlace sanitario (Iván), una periodista acreditada (Paola) y el operador de radio (Chuy) |
| Estado por persona | rol, turno (inicio y fin), brigada y zona asignadas, dispositivos que usa |
| Estado por mensaje | quién lo escribió, en qué sala, tipo (aviso, orden, público, reservado), clave de envío, sello del dispositivo y sello del servidor (puede faltar), y los recibos que generó |
| Eventos | entra o sale alguien de una sala; empieza o termina un turno; se emite una orden; llega un recibo de entrega, de lectura o un acuse; llega un latido; el operador anota una confirmación por voz; se pide un acceso de emergencia |
| Decisiones | ¿quién ve y quién escribe en esta sala?, ¿qué orden rige?, ¿quién está enterado?, ¿qué le muestro a quien regresa?, ¿se concede este acceso excepcional? |
| Reglamento (inventado) | (a) cada sala pertenece a un incidente y es de un tipo: mando, brigada, albergue o informativa; (b) se ve una sala si se pertenece a su unidad con turno vigente (los turnos duran 12 horas) y una brigada trabaja en una zona a la vez, de modo que reasignarla cambia su sala; (c) se escribe si se puede ver y el rol lo permite: en brigada, su jefe y sus brigadistas; en albergue, voluntarios y mando; en informativa, solo mando; el mando escribe en todas; (d) solo el mando emite órdenes (evacuar, retirarse, mantener posición), dirigidas a una brigada, y una orden rige hasta que otra la sustituye o el incidente cierra; (e) quien entra a una sala ve los mensajes desde su ingreso, no antes; quien sale no ve los posteriores a su salida pero conserva lo ya visto; el mando ve todo el historial; (f) prensa y externos solo leen la sala informativa y solo mensajes marcados públicos; (g) el enlace sanitario puede pedir ver una sala de brigada cuando hay una persona herida: lo concede el mando, vale 30 minutos, no permite escribir y queda en bitácora con su motivo; (h) cada fuente registra algo distinto: el recibo de entrega es del dispositivo, el de lectura es de quien abrió la sala en ese dispositivo, el acuse es de la persona que toca «enterado» con su usuario, y la nota del operador es una confirmación por voz que él mismo captura |

## Situaciones que tu gemelo debe razonar

Las cinco las plantea esta extensión. La 2, la 3 y la 4 retoman casos del problema
original (mensajes concurrentes y reintento, palomitas y latidos de 30 a 60 segundos, el
usuario que vuelve tras 6 horas con 300 pendientes); la 1 y la 5 son nuevas. En cada
una, tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — Quién ve y quién escribe

- **Qué pasa.** Es la tarde y la sala Norte acaba de recibir la ruta de una cuadrilla.
  Beto, brigadista de Norte, terminó su turno hace 20 minutos y sigue con la app abierta.
  Ximena, que estaba en Norte, fue reasignada a Sur esta mañana. Paola, la periodista, y
  Dulce, voluntaria del albergue, piden «ver la sala de Norte». Si ve quien no debe, se
  filtra la posición de una cuadrilla; si no ve quien debe, llega tarde a la orden.
- **Qué datos hay.** Roles, turnos, asignaciones de brigada a zona, tipo de cada sala y
  quién se unió o salió de ella. Ningún dato dice «esta persona puede ver esta sala».
- **Qué debe deducir.** En cadena: de la persona a su turno vigente, de ahí a su brigada,
  de la brigada a su zona actual, de la zona a su sala, y de la sala y el rol a si puede
  ver y si puede escribir; son dos conclusiones distintas.
- **Qué debe contestar.** Para la sala Norte, quién ve, quién escribe y quién ve sin
  poder escribir; para Beto, Ximena, Paola y Dulce, la razón de cada «no»; y qué tendría
  que cambiar para que cada uno pudiera.
- **Por qué es lógica.** El permiso no está escrito en ningún lado: se concluye de
  hechos de distintas personas y momentos.

### Situación 2 — Dos órdenes, una brigada

- **Qué pasa.** Con Sur cerca del frente, Yolanda ordena «mantener posición» y, casi al
  mismo tiempo, Raúl ordena «retirarse» desde la tablet del puesto de mando. Los dos
  tienen autoridad de mando y ninguno vio la orden del otro. La de Raúl llegó dos veces
  por un reintento, y el reloj de su tablet no cuadra con el del servidor. Si se obedece
  la equivocada, la brigada se queda en el camino del fuego o abandona una casa que aún
  se podía salvar.
- **Qué datos hay.** Quién emitió, su rango dentro del mando, la clave de envío, el sello
  del dispositivo, el sello del servidor y las entregas a la brigada.
- **Qué debe deducir.** Cuántas órdenes hay de verdad (el reintento no es una orden más),
  si las dos son contradictorias, qué orden rige para Sur y si el orden en que llegaron
  se puede establecer con confianza.
- **Qué debe contestar.** La orden vigente, a quién se le falla y por qué, qué avisar a
  cada emisor y qué dato faltaría para estar seguros.
- **Por qué es lógica.** Dos personas con razón no se resuelven con una hora: la
  prioridad entre autoridades y la duda sobre los relojes se declaran una vez.

### Situación 3 — Entregado no es enterado

- **Qué pasa.** Mando emite «evacuar» para Sur y necesita saber a quién llamar primero.
  Mateo y Ximena comparten la tablet del camión 3, que marcó «entregado» y «leído» sin
  decir quién la abrió. Al celular de Mateo solo se le mandó una notificación push, de
  las que no se sabe si llegan. Marisol, jefa de Sur, tiene «entregado» en su celular,
  pero su último latido fue hace mucho más de lo normal, y Chuy anotó que confirmó la
  orden por radio. Quien se queda sin enterar puede quedar atrapado.
- **Qué datos hay.** Por persona y dispositivo: recibos, acuses, último latido, notas del
  operador y quién usa cada dispositivo. Ningún dato dice «esta persona sabe que debe
  evacuar».
- **Qué debe deducir.** Para cada integrante de Sur, si está enterado, no enterado o
  «no se sabe», combinando recibos, quién usaba el dispositivo, presencia y notas.
- **Qué debe contestar.** El veredicto y la evidencia de cada integrante, a quién llamar
  primero y qué fuente cerraría cada duda. Lo intuitivo es creer que «leído» cierra el
  caso; aquí ese razonamiento es sospechoso.
- **Por qué es lógica.** Dos sistemas (mensajes y voz) pueden no coincidir, y «no hay
  prueba» no es lo mismo que «no se enteró».

### Situación 4 — El regreso tras el apagón

- **Qué pasa.** Mateo pasó 6 horas sin señal en el cañón y vuelve a tener red con 300
  mensajes pendientes de tres salas. A mitad del apagón terminó su turno y, al regresar,
  lo reasignaron a Norte. Entre lo pendiente hay una orden de «mantener posición» ya
  sustituida por otra, mensajes de una sala que ya no es la suya y mensajes sin sello del
  servidor, solo con el de un teléfono. Si actúa sobre una orden vieja, arriesga a su
  cuadrilla.
- **Qué datos hay.** Sus ingresos y salidas de cada sala, su turno, los mensajes con sus
  sellos y las órdenes dirigidas a su brigada.
- **Qué debe deducir.** De cada mensaje pendiente, si Mateo tenía derecho a verlo en el
  momento en que se escribió, si sigue vigente y si su pertenencia a la sala se puede
  establecer.
- **Qué debe contestar.** Qué se le muestra primero, qué marcado como sustituido, qué no
  ve y por qué, y qué queda «en duda» y quién podría aclararlo.
- **Por qué es lógica.** Se razona con la historia, no con el ahora: quien pudo ver un
  mensaje ayer puede no verlo hoy.

### Situación 5 — El herido y la sala reservada

- **Qué pasa.** Iván, el enlace sanitario, pide ver la sala Sur porque cree que Ximena
  está herida y quiere ubicarla para enviar una ambulancia. La sala contiene mensajes
  «reservado» con la ruta de retirada de la brigada. Yolanda dice que esa ruta no debe
  salir de la brigada; Iván, que cada minuto cuenta. El motivo «persona herida» lo
  capturó Iván; la nota del operador sobre la herida aparece 4 minutos después de la
  solicitud. Las dos partes tienen razón.
- **Qué datos hay.** La solicitud con su motivo y su instante, quién puede conceder, la
  nota del operador, los mensajes con su marca y el historial de la sala.
- **Qué debe deducir.** Si el motivo está respaldado en el momento de pedirlo, quién
  puede conceder, qué parte de la sala alcanzaría el acceso y cuándo vence.
- **Qué debe contestar.** Conceder, negar o conceder en parte, a quién se le falla y por
  qué, qué queda en la bitácora y quién vio lo reservado si luego se pregunta.
- **Por qué es lógica.** Es un dilema, no una duda de datos: la regla decide, dice a
  quién le falla y deja rastro para la rendición de cuentas.

## Por qué no basta un script

Con `if usuario in sala.miembros: mostrar(mensaje)` resuelves una sala sin turnos, sin
reasignaciones y con un solo dispositivo por persona. Tu gemelo debe contestar, **con las
mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Puede Beto escribir en la sala Norte? | decisión |
| ¿Por qué se da a Mateo por no enterado? | explicación |
| ¿Quiénes ven hoy la sala Sur? | todas las respuestas |
| ¿Qué tendría que cambiar para que Ximena pueda ver Norte? | la pregunta al revés |
| ¿Qué pasaría si Marisol hubiera quedado fuera de Sur desde el cambio de turno? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para saber, en un instante, quién pertenece a una sala?
2. Cuando la jerarquía choca con el orden de llegada, ¿dónde queda escrito cuál gana?
3. ¿Cómo distingue tu gemelo «no se enteró» de «no tengo cómo saber si se enteró»?
4. ¿Qué parte de la explicación le sirve a quien se queda fuera de una sala y qué parte
   solo al auditor?
5. En Erlang decidiste qué es «entregado» y quién lo confirma. ¿Qué de eso alimentaría a
   este gemelo, y qué pregunta que un proceso por sala no puede contestar sí contesta él?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la operación, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch: solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en ella.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para simular mensajes o graficar.

## Supuestos de esta extensión

- Inventado por esta extensión: el centro de mando, el incendio, las personas, las salas,
  el reglamento (a)-(h) y los horarios. Son datos del ejercicio, no estadísticas.
- Escala reducida: 11 personas, 5 salas y 2 zonas (el original maneja 5,000 conexiones y
  grupos de hasta 200 miembros). Los números de los ejemplos (turnos de 12 horas, 20, 30
  y 4 minutos, el camión 3) son datos del ejercicio.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir. Los apagones y los retrasos no se sortean: entran como hechos.
- Tú defines y declaras como supuesto: cuánto desfase entre relojes se tolera; cuánto
  silencio de latido vuelve dudosa la presencia; cuándo dos órdenes son «casi
  simultáneas»; qué rango tiene cada integrante del mando; qué se hace cuando no hay
  sello del servidor; y qué regla gana en cada choque.

## Extensiones posibles

Para quien quiera ir más lejos; investiga y cita tus fuentes antes de fijar cifras.

- Mensajes que caducan y órdenes con vigencia propia.
- Quién puede reenviar un mensaje reservado y con qué rastro.
- Presencia («en línea», «escribiendo») que se muestra solo a quien tiene derecho a verla.

---
*Las cifras del dominio (heartbeats de 30 a 60 segundos, el usuario que vuelve tras 6
horas con 300 mensajes pendientes, los grupos de hasta 200 miembros) vienen del problema
original. El escenario y su reglamento son inventados: verifica la fuente vigente de toda
cifra antes de citarla.*
