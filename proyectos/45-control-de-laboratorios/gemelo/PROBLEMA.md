# #45 — Control de laboratorios: gemelo digital con programación lógica

> Extensión del proyecto #45. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el calendario: un proceso por laboratorio con sus reservas,
cada reserva pasando de solicitada a aprobada, en uso y finalizada, y, si dos reservas
traslapadas llegan a la vez, una se rechaza con un mensaje claro. Esa simulación responde
«¿qué reserva quedó en qué bloque?». Quien coordina los laboratorios necesita algo más:
«¿a quién le muevo, qué se libera, qué equipo está de verdad disponible, y por qué?».

El gemelo digital es el **modelo lógico** de los laboratorios: hechos que reflejan su estado
y reglas que reflejan cómo se decide en ellos. Se escribe en Prolog porque lo que hay que
resolver aquí no es calcular, sino repartir salas, equipos y tiempo que no alcanzan, deducir
lo que ningún registro dice y distinguir «no se devolvió» de «no consta que se devolvió».

## Los laboratorios que se clonan

Un campus de laboratorios como el del TecNM Tijuana, reducido a 3 laboratorios, unos 8
equipos prestables, 5 grupos y una docena de reservas a la vista. Es una simulación
planteada por el problema original; lo que se añade (detalles y actores) está marcado en
las situaciones.

| Parte | Contenido |
|---|---|
| Entidades | campus → laboratorio, equipo prestable; grupos y sus responsables; reservas y series recurrentes; lista de espera |
| Estado por laboratorio | aforo, calendario de reservas, bloques de mantenimiento |
| Estado por equipo | laboratorio donde vive, bloques de mantenimiento o calibración, quién lo tiene prestado |
| Estado por reserva | tipo (clase fija o práctica libre), grupo, responsable, laboratorio, equipo, inicio, fin y eventos |
| Eventos | se solicita, aprueba, cancela o libera una reserva; el grupo entra o sale; se presta o se devuelve un equipo; empieza un mantenimiento |
| Decisiones | ¿cabe esta reserva?, ¿a quién se mueve?, ¿está libre este equipo?, ¿se libera esta reserva?, ¿quién queda sin lugar? |

## Situaciones que tu gemelo debe razonar

Las cinco parten del problema original; los complementos derivados añaden un detalle que
el original no menciona y se señalan en cada una. En cada situación, tu gemelo debe llegar
a una decisión **y poder explicarla**.

### Situación 1 — La clase que llega después

- **Qué pasa.** Ya hay prácticas reservadas en un laboratorio cuando la coordinación da de
  alta una clase fija en ese mismo horario. Las clases tienen prioridad sobre las prácticas
  libres, pero dos de las reservas afectadas ya traen equipo asignado: la de un grupo que
  prepara un proyecto y la de otro que ya no tiene otro bloque libre esa semana (ambos
  casos son complemento derivado). Los
  demás laboratorios tienen aforo y equipo distintos.
- **Qué datos hay.** Reservas con tipo, laboratorio, equipo, inicio y fin; aforo de cada
  laboratorio; el equipo de cada uno; la clase nueva. Nadie guarda «reserva afectada».
- **Qué debe deducir.** Qué reservas se traslapan con la clase, cuáles pueden reubicarse y
  dónde (aforo y equipo cuentan), y la cadena: mover una reserva ocupa un bloque que
  desplaza a otra, y esa a una tercera.
- **Qué debe contestar.** El plan completo (quién se queda, quién se mueve y a dónde,
  quién se cancela) con la razón de cada movimiento; los demás planes válidos; y, si no
  alcanza, a quién se le falla y por qué a él. Lo obvio es que la clase gana y desplaza a
  todos los que estorben; es sospechoso porque algunos desplazados sí tienen dónde ir y
  otros no, y la regla debe decidir a quién se le falla, no solo si la clase gana.
- **Por qué es lógica.** La prioridad se declara una vez y vale para todos los casos. La
  pregunta al revés («¿qué tendría que liberarse para que la clase no desplace a nadie?»)
  sale de las mismas reglas.

### Situación 2 — La serie que cruza el mantenimiento

- **Qué pasa.** Un grupo reserva el mismo laboratorio y bloque cada semana durante varias
  semanas (la serie, un ejemplo de reserva recurrente). Una de esas semanas el laboratorio
  tiene mantenimiento programado; un equipo que usa la serie (vida limitada y calibración
  son datos del original) tiene la calibración vencida a media serie. Además, el aviso
  del mantenimiento dice «hasta nuevo aviso» y no trae fecha de fin (dato faltante,
  complemento derivado).
- **Qué datos hay.** La serie con sus reservas, los bloques de mantenimiento y calibración
  con sus fechas, y el calendario de los demás laboratorios. Nadie guarda «ocurrencia
  afectada».
- **Qué debe deducir.** Qué ocurrencias de la serie caen en bloques de mantenimiento o
  calibración, de laboratorio o de equipo; cuáles no se sabe si caen; y la cadena: una
  ocurrencia afectada se reubica en otro laboratorio, ese no tiene el equipo, y el que sí
  lo tiene está ocupado por otra serie.
- **Qué debe contestar.** Para cada ocurrencia, «afectada», «libre» o «no se sabe», con la
  evidencia; dónde reubicar las afectadas y qué se cede; y qué ocurrencias futuras
  dependen de que el mantenimiento termine. Cancelar toda la serie es lo cómodo y es
  sospechoso: casi todas las ocurrencias pueden conservarse.
- **Por qué es lógica.** Una serie son muchas reservas que comparten una condición, y un
  bloque con fin desconocido no es lo mismo que uno que no pisa. Las tres respuestas
  salen de las mismas reglas.

### Situación 3 — El equipo que se toca por un minuto

- **Qué pasa.** Un mismo equipo (un osciloscopio, por ejemplo) está reservado para dos
  prácticas cuyos horarios se tocan por un minuto, como señala el original. Las dos están
  en laboratorios distintos (complemento derivado), y el equipo se presta a un
  responsable que debe devolverlo. Según la captura, la primera práctica terminó, pero la
  devolución no consta en el registro.
- **Qué datos hay.** Las dos reservas con su equipo, inicio y fin; el préstamo y la
  devolución del equipo con su instante, o su ausencia; el laboratorio de cada reserva.
- **Qué debe deducir.** Si los horarios se pisan o solo se tocan (tú fijas la convención),
  si el equipo puede estar físicamente en el segundo laboratorio a tiempo, y si de verdad
  volvió.
- **Qué debe contestar.** «Sí», «no» o «no se sabe» para aceptar la segunda reserva, con
  la razón. Lo obvio es decidir con el reloj: se tocan, se rechaza; o no se pisan, se
  acepta. Es sospechoso porque ninguna reserva dice dónde está el equipo: aceptar a ciegas
  puede dejar a un grupo con la mesa lista y el instrumento en otro edificio.
- **Por qué es lógica.** El equipo es una entidad con ubicación y responsable, no un
  número de intervalo. «No devuelto» y «sin constancia de devolución» no son lo mismo, y
  la hipótesis «el responsable lo devolvió» cambia la respuesta.

### Situación 4 — La reserva a la que nadie llega

- **Qué pasa.** Un laboratorio está reservado y nadie ha llegado, mientras otros grupos
  esperan lugar; no presentarse deja un laboratorio vacío (dato del original). Pero la
  entrada se registra a mano, el responsable avisó por mensaje que llegaría tarde (el
  aviso es complemento derivado), y ese mismo responsable tiene un equipo que prestó antes
  y nunca devolvió. Si se libera la reserva, entra un grupo de la lista de espera; si el
  responsable aparece a media sesión, hay dos grupos con razón.
- **Qué datos hay.** La reserva con sus eventos de entrada, los préstamos y devoluciones del
  responsable, la lista de espera y el ahora. Nadie guarda «reserva fantasma» ni «adeudo».
- **Qué debe deducir.** Si la reserva es fantasma, si no se sabe, y la cadena: equipo sin
  devolver implica adeudo, el adeudo bloquea al responsable, el bloqueo invalida sus
  otras reservas futuras, y eso abre bloques que la lista de espera necesita.
- **Qué debe contestar.** La decisión sobre la reserva (liberar, esperar o «no se sabe»),
  qué otras reservas del responsable quedan bloqueadas, quién de la lista de espera
  entra, y a quién se le falla si el responsable aparece. Un laboratorio sin nadie parece
  fantasma; es sospechoso porque «no consta la entrada» no es «no llegó».
- **Por qué es lógica.** Lo que decide no está en un solo registro: se deduce de varios
  hechos que se cumplen a la vez, y la explicación debe nombrarlos.

### Situación 5 — La semana de proyectos

- **Qué pasa.** En la semana de proyectos la demanda es 5 veces la normal y los bloques
  libres se agotan en horas. Llegan varias solicitudes a la vez; cada una pide laboratorio
  con aforo suficiente, uno o más equipos y un bloque de 1 a 2 h. Al sumar, las horas
  libres alcanzan, pero no están juntas ni en el laboratorio que tiene el equipo
  (complemento derivado: algunos equipos viven en un laboratorio concreto).
- **Qué datos hay.** Solicitudes con grupo y tamaño, equipo requerido y duración; el
  calendario, el aforo y el equipo de cada laboratorio; los bloques de mantenimiento.
- **Qué debe deducir.** Qué repartos atienden a todas sin traslape de sala, de equipo ni de
  aforo; y, si no existe ninguno, cuál es el cuello de botella.
- **Qué debe contestar.** El reparto completo con la razón de cada asignación; los demás
  válidos; y, si no cabe todo, a quién se le falla, por qué a él y qué bloque lo
  resolvería. Lo obvio es que si hay horas suficientes, todos caben; es sospechoso porque
  las horas libres no se pueden sumar: un bloque libre sin el equipo no sirve.
- **Por qué es lógica.** Es un reparto sobre tres recursos a la vez, y el mismo modelo que
  rechaza una solicitud sirve para proponer cómo se acomoda.

## Por qué no basta un script

Con `if inicio_a < fin_b and inicio_b < fin_a: rechazar()` resuelves dos reservas con datos
perfectos. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Puede el grupo 4 usar el osciloscopio en ese bloque? | decisión |
| ¿Por qué no? | explicación |
| ¿Qué bloques le sirven al grupo 4 esta semana? | todas las respuestas |
| ¿Qué tendría que liberarse para que el grupo 4 entre a Electrónica? | la pregunta al revés |
| ¿Qué pasaría si Electrónica entra a mantenimiento mañana? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para saber si un equipo está realmente disponible en un bloque?
2. Cuando una clase y una práctica libre se disputan un bloque, ¿dónde queda escrito
   quién gana y a quién se mueve?
3. ¿Cómo distingue tu gemelo «no se devolvió» de «no consta que se devolvió»?
4. ¿Qué parte de la explicación le sirve al coordinador y qué parte es ruido?
5. En tu simulación en Erlang, ¿qué sabe un proceso de laboratorio con su calendario y qué
   decisión de reparto entre laboratorios y equipos solo puede tomar el gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de los laboratorios, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar reservas simuladas o
  graficar la ocupación.

## Supuestos de esta extensión

- Escala reducida: 3 laboratorios, unos 8 equipos, 5 grupos y una docena de reservas,
  contra los 12 laboratorios, 150 equipos y 1,000 reservas por semana del escenario
  original.
- El «ahora» es un hecho del modelo, en minutos, no el reloj del sistema, para que las
  respuestas se puedan repetir.
- Los identificadores y las cantidades de los ejemplos («grupo 4», «la serie», «una
  docena») son del ejercicio, no cifras del dominio.
- El original da reglas habituales sin cifras: tú defines el aforo de cada laboratorio, el
  tiempo máximo por reserva, la convención de fin de bloque (si un bloque que termina en
  el minuto en que empieza otro los traslapa), el tiempo de traslado y revisión de un
  equipo, la tolerancia para llamar fantasma a una reserva, el plazo del mantenimiento sin
  fecha de fin y qué reservas se pueden mover.
- Qué equipo vive en qué laboratorio y quién lo tiene prestado son datos de tu escenario.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Reactivos con caducidad y consumo en el laboratorio de química.
- Licencias de software limitadas en los laboratorios de cómputo.
- Sanciones escalonadas por adeudo y la forma de levantarlas.
- Contingencias del edificio (apagón, falla de red) que cierran laboratorios a media tarde.
- Técnicos de laboratorio como recurso que también hay que asignar.

---
*Las cifras son de referencia y vienen del problema original. Verifica la fuente vigente
antes de citarlas en tu entrega.*
