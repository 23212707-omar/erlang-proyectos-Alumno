# #50 — Examen en línea: gemelo digital con programación lógica

> Extensión del proyecto #50. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el examen: un proceso por alumno con su temporizador,
desconexiones inyectadas, un servidor que se reinicia. Esa simulación responde «¿se
conservó el tiempo y las respuestas?». Quien atiende una inconformidad necesita algo más:
«¿qué pasó exactamente con este alumno, qué cuenta, qué no, y con qué evidencia lo
sostengo?».

El gemelo digital es el **modelo lógico** del examen: hechos que reflejan lo que el
servidor registró y reglas que reflejan cómo se decide sobre un intento. Se escribe en
Prolog porque aquí no se calcula un reloj: se reconstruye una historia, se justifica cada
veredicto y se sabe decir «no lo sé».

## El examen que se clona

Un grupo de 10 alumnos presenta un examen de 60 minutos con 20 preguntas, cada alumno con
su propio temporizador y su orden de preguntas. Es una reducción del escenario original
(200 alumnos, 60 minutos).

| Parte | Contenido |
|---|---|
| Entidades | examen, alumno, intento (uno por alumno), sesión (un dispositivo conectado al intento), pregunta, respuesta, evento de la bitácora, servidor |
| Personas (complemento derivado) | el alumno, la docente que registra justificaciones y la coordinación que las aprueba |
| Estado por intento | no iniciado, en curso, pausado por desconexión o entregado; hora de inicio, último guardado, extensiones concedidas |
| Estado por sesión | conectada o desconectada, y desde cuándo |
| Eventos | inicia, autoguarda una respuesta, pierde o recupera la conexión, abre otra sesión, cambia de pestaña, entrega, se aprueba una extensión, el servidor cae y arranca |
| Decisiones | ¿cuánto tiempo le queda?, ¿esta respuesta cuenta?, ¿qué sesión es la vigente?, ¿en qué estado está el intento?, ¿se concede la extensión?, ¿qué evidencia se entrega en una inconformidad? |

Dato del mundo real que manda en todo lo demás: el tiempo restante lo decide el
servidor, no el navegador, y un alumno debe poder reconectarse sin que el tiempo se
detenga ni se reinicie.

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original: el escenario a simular y sus casos difíciles. Lo
que el original no pide (las personas que registran y aprueban, las marcas de tiempo que
declara el navegador, los eventos que se pierden) es un complemento derivado y se marca
en el texto. En cada situación, tu gemelo debe decidir **y poder explicar la decisión**.

### Situación 1 — Cuatro minutos que no detienen el reloj

- **Qué pasa.** Ana y Beto pierden la conexión cuatro minutos. Beto, a la mitad de su
  examen; Ana, cuando le faltaban tres minutos para terminar. Para ambos el sistema
  muestra «pausado por desconexión». Si Ana se queda sin tiempo mientras estaba fuera,
  pierde las respuestas que no alcanzó a mandar y su calificación; si el sistema le da
  de más, el resultado deja de ser justo para el grupo.
- **Qué datos hay.** Inicio de cada intento, eventos de pérdida y recuperación de la
  conexión, autoguardados y la duración del examen. Ningún dato dice «tiempo restante».
- **Qué debe deducir.** El tiempo que le queda a cada uno en cada instante, el estado
  real del intento y, para Ana, en qué momento quedó entregado y con qué respuestas.
- **Qué debe contestar.** Estado y tiempo restante de ambos «ahora»; para Ana, cuándo se
  cerró su intento y qué respuestas cuentan. Lo intuitivo es leer «pausado» como «el
  reloj se detuvo» y cerrar el intento hasta que ella reconecte: es sospechoso porque el
  original dice que el tiempo no se detiene.
- **Por qué es lógica.** El tiempo restante se concluye de varios hechos y el nombre de
  un estado no es lo que ese estado significa. Se encadena: inicio, vencimiento,
  desconexión que no lo mueve, reconexión tardía, intento ya cerrado.

### Situación 2 — La respuesta del último segundo

- **Qué pasa.** Carla, Diego y Elena mandan una respuesta justo al final. Carla había
  pulsado «Entregar» un instante antes y mandó una corrección; Diego manda una respuesta
  que el navegador marca a tiempo pero que el servidor recibe después del cierre; la de
  Elena cae en el mismo segundo del cierre. La calificación de los tres depende de ello.
- **Qué datos hay.** Instante de recepción en el servidor, marca de tiempo que declara el
  navegador (dato derivado y no confiable según el original), entrega manual si la hubo,
  autoguardados anteriores de esa pregunta y extensiones del intento.
- **Qué debe deducir.** El instante exacto de cierre de cada intento y el orden entre ese
  cierre, la entrega y la respuesta, usando solo lo que el servidor registró.
- **Qué debe contestar.** Por respuesta: «cuenta», «no cuenta» o «no se sabe», con el
  par de eventos cuyo orden la decide. Lo intuitivo es que cuenta toda respuesta enviada
  antes del vencimiento; para Carla esa intuición falla.
- **Por qué es lógica.** La respuesta correcta nace del orden entre eventos, no de
  comparar una hora con un límite, y un empate es un dato que no alcanza, no un «no».

### Situación 3 — Una persona, dos sesiones

- **Qué pasa.** Gabriela aparece con una sesión desde el celular y otra desde una
  computadora, y la pregunta 7 está contestada distinto en cada una. Si fue un cambio de
  dispositivo tras una caída, castigarla es injusto; si las dos estuvieron activas a la
  vez, alguien pudo ayudarla. La docente tiene que decidir y firmar.
- **Qué datos hay.** Eventos de conexión y de pérdida por sesión, de qué sesión salió
  cada respuesta y los cambios de pestaña. El orden de las preguntas es distinto por intento.
- **Qué debe deducir.** Si las sesiones se traslapan o se suceden, cuál es la vigente y
  qué respuesta de la pregunta 7 vale. Cuando el celular se apagó, no hubo evento de
  pérdida (dato derivado): el silencio no prueba que siguiera conectado.
- **Qué debe contestar.** Sesión vigente, respuesta que cuenta, si el caso se marca para
  revisión y, cuando falte un evento, «no se sabe» con el dato que lo aclararía.
- **Por qué es lógica.** «Una sola sesión por alumno» choca con «no perder respuestas
  guardadas»: dos reglas legítimas, y la que gane debe quedar escrita y explicarse.

### Situación 4 — El servidor se reinició y no anotó nada

- **Qué pasa.** A mitad del examen el servidor cae unos minutos y vuelve. Mientras estuvo
  caído no pudo registrar nada. Fausto vuelve a conectarse; Hugo reporta un autoguardado
  fechado dentro del hueco; Irma nunca reconecta; de Julián hay respuestas guardadas pero
  no el evento de inicio, que se perdió con la caída. Cada uno reclamará por su tiempo.
- **Qué datos hay.** Los eventos que sí se alcanzaron a guardar, el instante de la caída
  y del arranque, y los autoguardados con su instante de recepción.
- **Qué debe deducir.** Para cada intento, la historia de estados posible; cuánto tiempo
  corrió mientras el servidor no registraba; qué entrada es imposible; y qué se puede y
  qué no se puede afirmar de un inicio que nunca quedó anotado.
- **Qué debe contestar.** Por intento: estado, vencimiento (o el intervalo en que debe
  estar), si el reinicio le costó tiempo y la primera entrada que rompe una historia. Lo
  intuitivo es que al arrancar el servidor todos empiezan de nuevo; es sospechoso porque
  el tiempo no se reinicia.
- **Por qué es lógica.** La historia no se lee: se reconstruye. «Nadie reportó una
  desconexión» no significa que nadie se desconectó.

### Situación 5 — Tiempo extra para quien ya entregó

- **Qué pasa.** La docente justifica que Irma perdió tiempo por la caída del servidor y
  la coordinación aprueba una extensión, pero minutos después de que el intento de Irma
  se cerró. Con Julián la extensión se aprobó antes del cierre. Dos partes tienen razón:
  Irma, que perdió tiempo por una falla ajena, y el principio del original de que los
  resultados no se pueden alterar, que protege al resto del grupo. El gemelo debe
  decidir y justificar a quién se le falla.
- **Qué datos hay.** La justificación (autor, texto, instante de registro y el instante
  que el autor dice que la hizo), la aprobación y el cierre de cada intento.
- **Qué debe deducir.** Si la extensión llegó antes o después del cierre por el orden de
  los eventos registrados, no por la hora que el autor declara, y cuánto acumula cada
  alumno si ya tenía otra.
- **Qué debe contestar.** Aplicada, no aplicada o requiere decisión humana, las dos
  reglas en choque, cuál ganó, a quién se le falla y qué evidencia habría cambiado el
  veredicto. «Aprobada» no significa «aplicada».
- **Por qué es lógica.** Dos principios legítimos chocan y la prioridad se declara una
  vez; la explicación es la evidencia de la inconformidad.

## Por qué no basta un script

Con `if time.time() - inicio > duracion: cerrar(intento)` resuelves un alumno sin
caídas, con un reloj confiable y sin extensiones. Tu gemelo debe contestar, **con las
mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Puede Ana mandar una respuesta ahora? | decisión |
| ¿Por qué no cuenta la corrección de Carla? | explicación |
| ¿Qué intentos están cerrados en este instante? | todas las respuestas |
| ¿Cuándo debió quedar registrada la extensión de Irma para aplicarse? | la pregunta al revés |
| ¿Qué pasaría si el servidor hubiera caído cinco minutos más tarde? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir un intento en un instante?
2. Si el estado de un intento no se guarda, ¿de qué eventos se deduce?
3. Cuando «una sola sesión» choca con «no perder respuestas», ¿dónde queda escrito
   cuál gana?
4. ¿Cómo distingue tu gemelo «no hubo desconexión» de «no sé si hubo desconexión»?
5. En Erlang el `gen_statem` de cada alumno llevaba su estado y su temporizador. ¿Qué
   de eso podría alimentar a este gemelo, y qué decide el gemelo que el proceso no puede?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del examen, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar eventos simulados o
  graficar la línea de tiempo.

## Supuestos de esta extensión

- Escala reducida: 10 alumnos y 20 preguntas, contra los 200 alumnos y las 20 a 60
  preguntas del escenario original. Los nombres, los números de pregunta y las cantidades
  de los ejemplos («tres minutos», «cinco minutos», «unos minutos» de caída) son
  ilustrativos.
- El «ahora» es un hecho del modelo, en segundos, no el reloj del sistema, para que las
  respuestas se puedan repetir. Cada intento tiene su propio inicio.
- Tú defines y declaras como supuesto: la tolerancia para decir que dos eventos son del
  mismo instante; cuánto silencio vuelve sospechosa una sesión; si las extensiones se
  suman o se sustituyen; quién puede aprobarlas y hasta cuándo; y qué sesión gana cuando
  hay dos.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Una pregunta con varias variantes en el banco que resulta tener un error.
- Alumnos con acceso a un examen en horario distinto por una causa justificada.
- Detección de patrones de copia a partir de los cambios de pestaña de un grupo.
- Exámenes con más de una sección y tiempo propio por sección.

---
*Las cifras son de referencia y vienen del problema original. Verifica la fuente vigente
antes de citarlas en tu entrega.*
