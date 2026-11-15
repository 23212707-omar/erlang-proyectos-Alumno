# #41 — Signos vitales: gemelo digital con programación lógica

> Extensión del proyecto #41. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).
> Es un ejercicio con datos simulados, no un dispositivo médico.

## Del simulador al gemelo

En la parte de Erlang simulaste el monitor: pacientes que reportan signos cada segundo,
sensores que se desconectan, alarmas que se generan. Esa simulación responde «¿qué está
pasando en cada cama?». La enfermera necesita algo más: «¿a quién atiendo primero, y por
qué?».

El gemelo digital es el **modelo lógico** del piso: hechos que reflejan el estado de los
pacientes y reglas que reflejan cómo se decide en él. Se escribe en Prolog porque lo que
hay que resolver aquí no es calcular un número, sino combinar señales, justificar y
distinguir lo que se sabe de lo que no.

## El piso de hospitalización que se clona

Un hospital general de Tijuana, reducido a una unidad de cuidados intensivos y un piso de
medicina interna, con 6 pacientes y 3 enfermeras en el turno.

| Parte | Contenido |
|---|---|
| Entidades | unidad → paciente → sensor; enfermeras, un supervisor y un médico de guardia |
| Estado por paciente | perfil (adulto, adulto con EPOC, niño), límites propios si los tiene, enfermera asignada |
| Estado por señal | frecuencia cardiaca, frecuencia respiratoria, SpO₂, temperatura y presión sistólica, cada una con su instante; un sensor puede dar valor imposible o ningún valor |
| Eventos | llega una lectura, un sensor se desconecta o se reconecta, se activa o se limpia una alarma, alguien acusa recibo, se escala |
| Decisiones | ¿qué tan grave es?, ¿es falla técnica o deterioro?, ¿a quién se avisa?, ¿quién va primero? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original (en la 5, la jerarquía de escalamiento es un
complemento derivado de «escalar si nadie acusa recibo»). En cada una, tu gemelo debe
llegar a una decisión **y poder explicarla**.

### Situación 1 — Ningún signo grita, todos susurran

- **Qué pasa.** Un paciente del piso lleva veinte minutos deteriorándose poco a poco.
  Ningún signo está en un extremo, pero casi todos se han salido un poco de su rango. En
  la cama de al lado, otro paciente tiene un solo signo muy alterado y todo lo demás en
  orden. El que hace más ruido en pantalla se lleva a la enfermera; el otro se queda solo.
- **Qué datos hay.** Las lecturas de los cinco signos con su instante, los rangos de un
  adulto en reposo y el puntaje tipo NEWS2, cuya suma alta exige respuesta urgente.
  Ningún sensor mide «gravedad».
- **Qué debe deducir.** El nivel de gravedad de cada paciente a partir de la combinación
  de sus signos, cuál aporta más, si el puntaje va subiendo con el tiempo y qué le falta
  a cada uno para pasar al siguiente nivel de respuesta.
- **Qué debe contestar.** A quién se atiende primero, con el desglose signo por signo.
  Para el paciente que ningún monitor marca como crítico, la razón de por qué lo es.
- **Por qué es lógica.** La gravedad nace de que varias variables coincidan: lectura,
  puntos, suma, nivel y respuesta forman una cadena. Lo obvio (atender al signo más
  extremo) está mal.

### Situación 2 — ¿Falla del aparato o del paciente?

- **Qué pasa.** Tres sensores están desconectados (dedo sin pulsioxímetro: valor 0 o
  vacío) y un paciente se mueve tanto que sus lecturas saltan sin sentido. Pero un
  paciente agitado también se arranca el sensor, y uno que se desatura de verdad puede
  dar lecturas sucias. Si se llama «emergencia» a cada cero, el equipo de respuesta se
  cansa; si se llama «técnico» a todo, un paciente se deteriora sin que nadie lo vea.
- **Qué datos hay.** Lecturas con instante, el rango físico posible de cada signo, la
  última lectura válida de cada sensor y el estado de las demás señales del mismo
  paciente.
- **Qué debe deducir.** Para cada señal: válida, imposible, ausente o sospechosa de
  ruido. Y para cada paciente: si el problema es técnico, clínico o no se puede saber,
  considerando si las otras señales vuelven creíble un deterioro.
- **Qué debe contestar.** Tres respuestas distintas, «clínico», «técnico» y «no lo sé».
  Una falla técnica produce su propia alarma para quien repone el sensor: nunca silencio.
  Un puntaje calculado con señales ausentes se presenta como incompleto, no como bajo.
- **Por qué es lógica.** «No hay problema» y «no tengo cómo saberlo» no son lo mismo.

### Situación 3 — Lo normal de uno es alarma de otro

- **Qué pasa.** Un adulto con EPOC vive con una saturación que en otra persona
  preocuparía. Un niño tiene frecuencias normales distintas a las del adulto. Con los
  límites de adulto, el primero alarma sin parar (y su alarma se ignora) y el segundo
  puede deteriorarse sin que suene nada. A medianoche, el médico de guardia cambia los
  límites de un paciente.
- **Qué datos hay.** El perfil de cada paciente, los límites generales de adulto, los
  límites individuales con quién los fijó y cuándo, y las lecturas.
- **Qué debe deducir.** Qué límites rigen a cada paciente y de dónde salen, qué signos
  están fuera de ESOS límites y cómo cambia el puntaje con ellos.
- **Qué debe contestar.** La misma lectura con dos veredictos distintos, explicando qué
  límites se usaron. Si un perfil que exige límites propios no los tiene, la respuesta es
  «no lo sé», no un adulto por defecto.
- **Por qué es lógica.** La misma lectura significa cosas distintas según el contexto de
  quien la tiene; el contexto cambia las reglas, no solo los números.

### Situación 4 — La alarma que se prende y se apaga

- **Qué pasa.** La saturación de un paciente oscila justo sobre el límite: la alarma se
  activa y se limpia una y otra vez. El personal deja de hacerle caso (se reporta que una
  gran proporción de las alarmas clínicas es falsa o no accionable). Mientras tanto, la
  frecuencia respiratoria de ese mismo paciente sube despacio.
- **Qué datos hay.** El historial de activaciones y limpiezas con su instante, las
  lecturas recientes de todas las señales, los acuses anteriores.
- **Qué debe deducir.** Si lo que se ve es un rebote en el límite o un cambio de fondo,
  si detrás del ruido hay un deterioro que las demás señales confirman, y qué alarmas
  pueden agruparse en una sola.
- **Qué debe contestar.** Una alarma sostenida en lugar de muchas, con su razón; y cuál
  rebote NO se debe silenciar aunque parezca ruido. Cuánto tiempo cuenta como «repetido»
  lo decides tú y lo declaras.
- **Por qué es lógica.** Reducir falsas alarmas y no ocultar las reales chocan: la regla
  que silencia debe poder justificar a quién deja sin aviso y por qué es seguro.

### Situación 5 — Nadie acusa recibo

- **Qué pasa.** Una alarma clínica lleva rato sin acuse. La enfermera asignada atiende a
  varios pacientes y en este momento otro paciente suyo también está en alarma. Las dos
  tienen razón para reclamarla; atender a una es no atender a la otra. Además, una alarma
  ya acusada sigue sin ceder y el paciente empeora.
- **Qué datos hay.** Qué enfermera atiende a quién, la escalera de avisos (enfermera,
  supervisor, médico de guardia), instantes de alarma y acuse, y el nivel de cada alarma.
- **Qué debe deducir.** Qué alarmas siguen sin acuse, a quién corresponde el siguiente
  aviso, cuál de dos alarmas simultáneas pasa primero cuando una sola persona no alcanza,
  y si un acuse sigue valiendo después de que el paciente empeoró.
- **Qué debe contestar.** El orden de atención, a quién se escala y por qué; a cuál
  paciente se le falla momentáneamente y quién lo cubre. Los plazos de escalamiento los
  defines tú y los declaras.
- **Por qué es lógica.** Es un dilema real; la regla debe decidir y dejar escrito a quién
  se le falla. Acusar no es atender: eso hay que deducirlo.

## Por qué no basta un script

Con `if spo2 < 95: alarma()` resuelves un paciente sano con un sensor perfecto. Tu gemelo
debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿A quién atiendo primero ahora? | decisión |
| ¿Por qué la cama 4 es urgente si ningún signo está en rojo? | explicación |
| ¿Qué pacientes tienen una falla técnica en este momento? | todas las respuestas |
| ¿Qué tendría que cambiar para que el niño de la cama 5 no esté en alerta? | pregunta al revés |
| ¿Qué pasaría si el sensor de la cama 2 se reconecta y marca normal? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco consultas
sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el programa.

## Preguntas guía

1. ¿Cuándo una alarma es técnica y cuándo clínica, y cómo se trata cada una?
2. ¿Cómo reduces falsas alarmas sin ocultar las reales?
3. ¿Cómo distingue tu gemelo «el paciente está bien» de «no sé cómo está»?
4. ¿Qué parte de la explicación le sirve a la enfermera y qué parte es ruido?
5. ¿Qué evento de tu simulación en Erlang (un sensor que pierde señal, una alarma sin
   acuse) podría alimentar a este gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del piso, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar lecturas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 6 pacientes, 3 enfermeras, un supervisor y un médico de guardia,
  contra los 30 pacientes del escenario original. Los identificadores de los ejemplos
  («cama 4», «cama 5», «cama 2») son solo ilustrativos.
- El original habla de 4 señales por paciente y lista 5 signos en sus datos; aquí se usan
  los 5. Puedes reducirlos a 4 si lo declaras.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas se
  puedan repetir.
- Los puntos que aporta cada signo al puntaje, los límites de EPOC y de niño, el tiempo
  que cuenta como rebote y los plazos de escalamiento no vienen del original: los fijas
  tú, con fuente verificada, y los declaras.
- Qué paciente está en qué cama, quién lo atiende y cómo se ve el historial de alarmas
  son datos que defines en el escenario.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Cambio de turno: qué alarmas se heredan y cuáles se dan por cerradas.
- Alarmas de equipo (batería baja, cable flojo) frente a alarmas de paciente.
- Traslado de un paciente entre unidades con sus límites propios.
- Tendencia: avisar antes de que se alcance el límite.
- Sedación o procedimiento programado que justifica silenciar una alarma por un tiempo.

---
*Las cifras son de referencia y vienen del problema original. Verifica la fuente vigente
antes de citarlas en tu entrega.*
