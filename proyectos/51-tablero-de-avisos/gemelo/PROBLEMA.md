# #51 — Tablero de avisos: gemelo digital con programación lógica

> Extensión del proyecto #51. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang montaste el tablero: un proceso que reparte avisos, conexiones que
llegan y se caen, un expirador que los retira. Esa simulación responde «¿llegó el aviso
a la conexión?». Quien coordina una carrera necesita algo más: «¿a quién le toca, cómo
se le entrega, qué debe ver ahora y de verdad se enteró?».

El gemelo digital es el **modelo lógico** del tablero: hechos que reflejan su estado y
reglas que reflejan cómo se decide en él. Se escribe en Prolog porque aquí no se reparte:
se deduce una audiencia, se heredan reglas, se justifica y se sabe decir «no lo sé».

## El campus que se clona

Un campus como el TecNM Tijuana, reducido a 3 carreras (sistemas, industrial y
arquitectura), 6 grupos, 12 alumnos y un día con 8 avisos. Los nombres de personas,
grupos y salones son ejemplos de esta extensión.

| Parte | Contenido |
|---|---|
| Entidades | campus → carrera → semestre → grupo → alumno; quienes publican (dirección, coordinación de carrera, docentes); avisos; conexiones de los alumnos |
| Estado por alumno | su carrera, su semestre, sus grupos (uno o varios) y desde cuándo, sus preferencias y si tiene la conexión abierta |
| Reglas por nivel | campus, carrera y grupo pueden fijar cómo se entregan los avisos; el alumno, sus preferencias |
| Estado por aviso | quién lo publicó, su tipo, su prioridad (urgente o informativo), a quién va dirigido (todos, carrera, semestre o grupo) y qué le ha pasado: programado, publicado, corregido, retirado o vencido |
| Eventos | se publica, programa, corrige o retira un aviso; un alumno se conecta, se desconecta, abre o lee; cambia de grupo; una carrera cambia su política |
| Decisiones | ¿a quién le corresponde?, ¿cómo se le entrega?, ¿qué debe ver al abrir la app?, ¿se enteró? |

## Situaciones que tu gemelo debe razonar

Cuatro de las cinco salen del problema original; la 1 añade un complemento derivado (un
grupo con alumnos de otra carrera). La 5 es nueva: toma del original el resumen de
informativos y el silencio por saturación, y del foco, la herencia de reglas entre
niveles. En cada una, tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — Una carrera, un grupo prestado

- **Qué pasa.** Coordinación de sistemas avisa del cambio de salón para la presentación
  de proyectos de quinto semestre. El mismo día, la docente de Cálculo avisa a su grupo
  que lleve calculadora. Valeria, de sistemas, pertenece a dos grupos y no debe recibir
  nada por duplicado. Andrés es de industrial, pero cursa Cálculo en un grupo de
  sistemas porque ahí se abrió la materia. Si Valeria no se entera del salón pierde su
  presentación; si Andrés no se entera de la calculadora, entra sin ella a su examen.
- **Qué datos hay.** La jerarquía campus, carrera, semestre y grupo; las altas y bajas de
  cada alumno en sus grupos; el destino de cada aviso. Ningún dato dice «a esta persona
  le toca».
- **Qué debe deducir.** La audiencia de cada aviso a partir de su destino y de la
  pertenencia; quién la alcanza por más de un camino; y quién está en un grupo de una
  carrera que no es la suya. Lo intuitivo es que la audiencia de una carrera es la suma
  de sus grupos; pero estar en un grupo no es ser de esa carrera.
- **Qué debe contestar.** Para cada aviso, quiénes lo reciben y por qué camino; quiénes
  lo alcanzarían dos veces y se les entrega una; y qué alumnos quedan en la frontera,
  con la razón.
- **Por qué es lógica.** «A quien le corresponde» no se guarda en ningún lado: se deduce
  de relaciones, y la misma deducción sirve para preguntar por un aviso o por un alumno.

### Situación 2 — Lo silencié, pero hoy sí me importa

- **Qué pasa.** Una tormenta amenaza la ciudad y dirección publica una suspensión de
  clases, urgente, para todos. Marisol vive lejos del campus y, hartada de mensajes,
  silenció los avisos de su grupo y los informativos; su decisión es legítima. Pero si
  no se entera, sale de casa hacia un campus cerrado. Ese día, un docente marca como
  urgente un aviso sobre un quiz para que todos lo vean. Si todo lo urgente es
  intocable, todos acabarán silenciándolo todo.
- **Qué datos hay.** Las preferencias de campus, de carrera, de grupo y de cada alumno,
  con quién las fijó; la prioridad declarada de cada aviso; el rol y el ámbito de quien
  lo publicó; el estado de la conexión.
- **Qué debe deducir.** Para cada alumno y cada aviso, qué preferencias le aplican y
  cuáles chocan con la prioridad del aviso; y si la urgencia declarada es creíble dado
  quién la declara y a quién se dirige.
- **Qué debe contestar.** Cómo se entrega cada aviso (de inmediato, en resumen, solo al
  abrir o no se entrega), la regla que cedió y a quién se le falla; y qué tendría que
  cambiar para que el aviso del quiz sí pudiera silenciarse.
- **Por qué es lógica.** Dos partes tienen razón y la prioridad entre ellas se declara
  una vez, con su justificación, en lugar de improvisarse aviso por aviso.

### Situación 3 — El salón que ya no es, y el examen que tampoco

- **Qué pasa.** El lunes coordinación publica que el examen de Estructuras de Datos es
  en el salón X, y deja programado un recordatorio para el jueves. El martes corrige:
  ahora es en el salón Y. El miércoles retira la corrección porque el examen se aplaza
  y aún no hay fecha. El viernes abre la app Iván, que no se conectaba desde hace una
  semana. Quien leyó el aviso del lunes sigue creyendo que es en X; llegar a un salón
  equivocado o a un examen que no existe cuesta un día y la confianza en el tablero.
- **Qué datos hay.** Los eventos de cada aviso con su instante (publicado, programado,
  corregido, retirado, vencido), cuál sustituye a cuál, quién lo leyó y cuándo, y la
  última conexión de cada alumno.
- **Qué debe deducir.** En cadena: qué aviso sustituye a cuál, luego cuáles siguen
  vigentes, luego si el recordatorio programado aún procede, y luego quién se quedó con
  información caduca. Lo intuitivo es que al retirar la corrección «vuelve» el original,
  o que lo retirado simplemente desaparece; ambas cosas son sospechosas.
- **Qué debe contestar.** Qué ve Iván al abrir: lo vigente, lo retirado que le atañe y
  lo vencido que ya no necesita; qué pasa con el recordatorio programado; y a quiénes
  hay que avisar que lo que leyeron dejó de valer.
- **Por qué es lógica.** Lo vigente no es un campo de cada aviso: se concluye de la
  historia de todos los avisos relacionados.

### Situación 4 — Entregado no es leído

- **Qué pasa.** Dirección publica un aviso urgente y el distribuidor marca «entregado»
  a todos los conectados. Coordinación no alcanza a llamar a todos y quiere telefonear
  solo a quienes no se enteraron. Pero la conexión de Diego se cerró segundos antes del
  envío y aun así figura como entregado. Ana mandó un acuse de «leído» con un instante
  anterior a la publicación, porque su reloj está desfasado. Luis tiene la app abierta,
  sin tocarla hace horas. Elena nunca se conectó. Omitir a quien no se enteró de una
  contingencia es un riesgo; llamar a todos no es posible.
- **Qué datos hay.** Los eventos de conexión con su instante, el instante de publicación
  y los acuses (entregado, visto, leído) con el instante que reporta cada dispositivo.
- **Qué debe deducir.** Por alumno, si se enteró; qué acuses son imposibles y por qué; y
  qué significa la ausencia de acuse: que no leyó o que no hay forma de saberlo.
- **Qué debe contestar.** Tres respuestas distintas: «sí se enteró», «no» y «no lo sé»;
  a quién llamar y en qué orden de certeza; y qué dato haría falta para salir de la duda.
- **Por qué es lógica.** «Entregado» es lo que dice el sistema y «leído» es lo que pasó
  en una persona; los separa un tramo que ningún dato mide y que se razona.

### Situación 5 — Quién manda: campus, carrera, grupo o alumno

- **Qué pasa.** En un día de 8 avisos, el campus dispone que los informativos vayan en un
  resumen y no sueltos. Arquitectura pide que sus avisos de taller nunca esperen al
  resumen, porque una entrega de maqueta es al día siguiente. Una docente de industrial
  quiere que su aviso informativo salga de inmediato. Un alumno de arquitectura, en un
  grupo de sistemas, pidió silenciar los avisos de sistemas. A media jornada, industrial
  cambia su política. Quien no se entera pierde la calificación de esa entrega; quien
  recibe todo suelto silencia todo.
- **Qué datos hay.** Las reglas de cada nivel con quién las fijó y desde cuándo; las
  preferencias de cada alumno; los avisos del día con su tipo, prioridad y emisor; y
  cuántos avisos ha recibido ya cada alumno hoy.
- **Qué debe deducir.** Para cada alumno y aviso, la regla vigente tras heredar entre
  niveles: qué nivel la fija, cuál la modifica, cuál no puede ser modificada por el de
  abajo; y cómo se ordena el resumen cuando dos avisos compiten.
- **Qué debe contestar.** Por entrega, la decisión y el nivel que la fijó; cuando dos
  niveles chocan, cuál ganó y a quién se le falla; y, si industrial revierte su cambio
  mañana, qué alumnos verían cambiar algo y cuáles no.
- **Por qué es lógica.** La herencia se declara una vez y vale para todos los grupos; lo
  excepcional se escribe como excepción.

## Por qué no basta un script

Con `if alumno.carrera == aviso.carrera: enviar(aviso, alumno)` resuelves una carrera
sin grupos prestados, sin preferencias, sin correcciones. Tu gemelo debe contestar,
**con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Cómo se le entrega a Marisol el aviso de la tormenta? | decisión |
| ¿Por qué Andrés recibe el aviso de la docente de Cálculo? | explicación |
| ¿Quiénes reciben el aviso de coordinación de sistemas? | todas las respuestas |
| ¿Qué le falta a Iván para que el examen le aparezca como vigente? | la pregunta al revés |
| ¿Qué pasaría si arquitectura cambiara su política mañana? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para saber a quién le corresponde un aviso en un instante, sin
   guardar la lista de destinatarios?
2. Si un alumno cambió de grupo después de publicado el aviso, ¿desde qué instante
   cuenta su pertenencia y dónde queda escrito?
3. Cuando la preferencia del alumno choca con la prioridad del aviso, ¿dónde queda
   escrito cuál gana y cómo muestra tu gemelo a quién se le falló?
4. ¿Cómo distingue tu gemelo «no lo leyó» de «no sé si lo leyó»?
5. En Erlang, el servidor de avisos filtraba por suscripción y el expirador retiraba
   avisos. ¿Qué de eso podría alimentar a este gemelo, y qué decide el gemelo que el
   distribuidor no puede?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del campus, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar eventos simulados o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 3 carreras (de las que el original menciona), 6 grupos y 12 alumnos,
  contra 12 carreras, 120 grupos y 3,000 alumnos; un día de 8 avisos contra 40.
- Inventado por esta extensión y sin cifras: los nombres de personas, grupos, materias y
  salones; los grupos con alumnos de otra carrera; los avisos que se sustituyen unos a
  otros; y las políticas de carrera y las preferencias por nivel.
- El «ahora» es un hecho del modelo, no el reloj del sistema.
- Tú defines y declaras como supuesto: quién puede declarar un aviso urgente; si algo
  no puede silenciarse ni anularse y qué; qué nivel gana cuando la política de la
  carrera choca con la del campus; cuántos avisos en un día saturan a un alumno y qué
  cambia entonces; cuánto silencio de un dispositivo vuelve dudoso un acuse; cuándo
  deja de ser útil un aviso informativo; si quien entra a un grupo ve lo publicado
  antes de su alta; y qué reloj manda cuando el del dispositivo y el del servidor
  discrepan.

## Extensiones posibles

Fuera del problema original: investiga y cita tus fuentes antes de fijar cifras.

- Avisos de asociaciones estudiantiles que requieren visto bueno antes de llegar a miles.
- Avisos que dependen de otros (la inscripción, del calendario publicado).
- Alumnos en baja temporal, de intercambio o egresados: quién sigue recibiendo qué.
- Accesibilidad: avisos que deben llegar por más de un medio.

---
*Las cifras de referencia (3,000 alumnos, 12 carreras, 120 grupos, 40 avisos por día,
unos 35 alumnos por grupo) vienen del problema original. Los ejemplos y las políticas
por nivel son inventados: verifica la fuente vigente antes de citar cualquier cifra.*
