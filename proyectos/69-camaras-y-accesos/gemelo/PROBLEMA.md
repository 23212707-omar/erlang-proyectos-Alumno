# #69 — Cámaras y accesos: gemelo digital con programación lógica

> Extensión del proyecto #69. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang ingeriste eventos de puertas y cámaras y los buscaste por rango de
tiempo. Esa simulación responde «¿qué dice la bitácora?». Quien responde por la seguridad
de una planta necesita algo más: «¿a quién se le abre, qué registro es creíble, qué se
puede borrar y quién tiene derecho a mirar?».

El gemelo digital es el **modelo lógico** de la planta y de su bitácora: hechos que
reflejan su estado y reglas que reflejan cómo se decide en ella. Se escribe en Prolog
porque aquí no se busca más rápido: se concede o se niega, se justifica y se dice «no sé».

## La planta que se clona

«Manufacturas Mesa de Otay» es una planta de componentes electrónicos en Tijuana, con
tres edificios. **No existe: es un escenario planteado por esta extensión**, no por el
problema original (que solo habla de «una empresa o campus»). Se reduce a 3 edificios,
9 puertas con lector, 6 cámaras con analítica, unas 12 personas y unas horas de eventos.

| Parte | Contenido |
|---|---|
| Entidades | edificios A (producción), B (almacén con una bóveda de componentes de alto valor) y C (oficinas); puertas, lectores, sensores de puerta, cámaras y paneles de alarma |
| Personas | personal de planta, contratistas, guardias, la jefa de seguridad, el auditor, la oficial de privacidad y los jefes directos de cada quien |
| Estado | por dispositivo: edificio, sentido de la puerta, si está en línea, desfase del reloj y cuándo se midió; por persona: credencial, nivel, capacitación, turno, jefe directo |
| Eventos | tarjeta leída, puerta abierta o cerrada, movimiento en cámara, alarma de incendio que inicia o termina, se abre o cierra un incidente, llega una solicitud, se aprueba o se rechaza |
| Decisiones | ¿abrir?, ¿cuál es la hora real?, ¿se puede borrar?, ¿qué pasó en la puerta?, ¿quién puede consultar? |
| Reglamento (inventado) | las reglas (a)-(h) de abajo |

**Reglamento de la planta (inventado; son datos del ejercicio, no leyes):**
- (a) Entrar a la bóveda exige credencial vigente, nivel B-3, capacitación vigente y turno.
- (b) Un contratista entra solo con escolta de planta, nivel B-3, que conste dentro del
  edificio; cada escolta responde por 2 contratistas como máximo.
- (c) Quien consta dentro de un edificio no puede registrar otra entrada a él.
- (d) Con alarma de incendio en un edificio, sus puertas de salida se liberan; las de
  entrada siguen controladas.
- (e) Plazos: eventos de puerta y de alarma, 1 año; eventos de analítica de cámara, 90 días.
- (f) Un incidente abierto retiene los eventos de su ventana y edificios hasta cerrarse.
- (g) Consulta por edificio, dispositivo o tipo: un guardia hasta 1 día de ventana, la
  jefatura hasta 30; más, solo con incidente abierto. Consulta por persona: motivo y dos
  aprobaciones de personas distintas; no valen la del solicitante, la del consultado ni
  la de su jefe directo.
- (h) Quien trabaja o trabajó en la planta puede pedir que se retire su identidad de los
  eventos ya vencidos.

## Situaciones que tu gemelo debe razonar

Las cinco las plantea esta extensión. La 2, la 3 y la 5 retoman casos del problema
original (reloj desajustado, borrado de lo vencido, consulta por persona); la 1 y la 4
salen del foco «reglas de acceso». En cada una, decide **y explica la decisión**.

### Situación 1 — El técnico y la escolta que quizá ya salió

- **Qué pasa.** A las 2:10 un técnico contratista pide entrar a la bóveda del edificio B.
  Su escolta pasó la tarjeta en B a la 1:50, pero la puerta lateral de salida de B lleva
  una hora sin reportar. Si lo dejan pasar sin escolta, hay mercancía de valor expuesta;
  si lo niegan sin razón, una reparación urgente se detiene.
- **Qué datos hay.** Lecturas de tarjeta con instante y sentido de puerta, credenciales,
  turnos, lectores en línea y contratistas de cada escolta. Nadie mide «está adentro».
- **Qué debe deducir.** Dónde consta cada persona; si la escolta cuenta como presente,
  ausente o «no se sabe»; si es escolta válida; y con eso, si el técnico es elegible.
- **Qué debe contestar.** Permitir, negar o condicionar, con la cadena de razones, y qué
  dato sacaría a la escolta de la duda.
- **Por qué es lógica.** Cada conclusión depende de otra, y «no consta que salió» no es
  «sigue adentro».

### Situación 2 — Cuatro minutos que cambian quién llegó primero

- **Qué pasa.** La alarma de B suena a las 2:13 y el reloj del panel está al día. El
  lector lateral registra a un trabajador a las 2:11: parece que llegó antes y que pudo
  provocarla. Pero ese lector atrasa 4 minutos. A la aseguradora hay que entregarle los
  eventos del rango 2:10 a 2:25, y alguien será sancionado o librado según el orden.
- **Qué datos hay.** Eventos con el instante del dispositivo y el de llegada; el desfase
  medido de cada reloj y cuándo (dos dispositivos nunca se midieron); un evento que llegó
  tarde con marca antigua; y el reporte que se entregó ayer.
- **Qué debe deducir.** El instante probable de cada evento, con su margen; el orden de
  dos eventos como antes, después o indeterminable; qué eventos entran o salen del rango
  al corregir los relojes; y qué cambió entre el reporte de ayer y el de hoy.
- **Qué debe contestar.** La lista del rango, el veredicto de orden con su razón y los
  eventos que cambiaron de lado. Lo intuitivo, ordenar por la marca del registro, es
  justo lo sospechoso.
- **Por qué es lógica.** La hora real no es un campo: es una conclusión con margen, y un
  mismo modelo contesta «¿qué sabíamos ayer?» y «¿qué sabemos hoy?».

### Situación 3 — Lo vencido que no se puede borrar

- **Qué pasa.** Vencen los eventos de puerta de hace un año y un exempleado pide que se
  retire su identidad de ellos. Pero algunos caen en la ventana de un incidente abierto de
  la bóveda, la bitácora debe seguir sirviendo como evidencia sin alteraciones (cada
  registro se encadena al anterior con un hash) y el auditor tiene una consulta en curso
  sobre ese tramo. La oficial de privacidad y la jefa de seguridad tienen razón.
- **Qué datos hay.** Eventos con tipo e instante, plazos, incidentes con ventana y estado,
  consultas en curso y la solicitud. Los hash los calcula otra parte: el gemelo solo
  recibe si cada tramo se verificó, falló o no se ha verificado.
- **Qué debe deducir.** Qué eventos están vencidos (el plazo depende del tipo), cuáles
  retiene un incidente (ningún evento lo dice), cuáles usa una consulta y cuáles se
  liberan al cerrarse cada incidente.
- **Qué debe contestar.** Por evento: borrar hoy, no borrar y por qué, o aplazar hasta
  qué cierre; al exempleado: a quién se le falla, qué se le ofrece y cuándo.
- **Por qué es lógica.** «Vencido» no implica «borrable»; los derechos se declaran una
  vez y el aplazamiento se deduce de cada caso.

### Situación 4 — La puerta que se abrió sin tarjeta

- **Qué pasa.** A las 3:02, durante un simulacro de incendio en C, el sensor de una puerta
  lateral marca «abierta» sin lectura previa y la cámara 4 detecta movimiento. En otra
  puerta, un lector concedió acceso a una tarjeta válida y su sensor nunca marcó apertura.
  Si es intrusión y se ignora, hay un robo; si es evacuación y se despacha un guardia,
  se estorba la salida y se culpa a quien dio la alarma.
- **Qué datos hay.** Lecturas de tarjeta con su resultado, estado de cada sensor, analítica
  de cámaras, inicio y fin de la alarma, sentido de cada puerta y quién está en línea.
  Ningún dato dice «forzada» ni «evacuación».
- **Qué debe deducir.** Para cada apertura: salida de evacuación, entrada forzada, puerta
  retenida o falla del sensor; y qué evidencia falta para decidir.
- **Qué debe contestar.** Un veredicto por puerta (intrusión, evacuación, falla o «no se
  sabe»), si se alerta, y a quién se le falla si se alerta de más o de menos.
- **Por qué es lógica.** La misma lectura significa cosas distintas según el contexto, y
  dos sistemas que no coinciden no se promedian: se razona cuál historia es posible.

### Situación 5 — Quién puede preguntar por una persona

- **Qué pasa.** Tras el robo en la bóveda, un jefe de turno quiere los movimientos de su
  propio subordinado de las últimas tres semanas, y la jefatura pide una consulta por
  edificio de las mismas semanas. Pueden aprobar la jefa de seguridad, el auditor y la
  oficial de privacidad, que está de vacaciones y dejó una delegación cuya vigencia no consta.
- **Qué datos hay.** El organigrama (jefes directos), las solicitudes con motivo y ventana,
  las aprobaciones y rechazos, los incidentes abiertos y las delegaciones.
- **Qué debe deducir.** Qué aprobaciones cuentan (según quién las da y a quién se consulta),
  qué ventana permite cada rol y qué parte de cada solicitud es elegible hoy.
- **Qué debe contestar.** Elegible, no elegible o «falta» con quién podría completarla;
  qué se puede entregar ya; y el registro de quién consultó qué.
- **Por qué es lógica.** La elegibilidad se concluye de relaciones entre personas, y una
  política se declara una vez para todas las solicitudes.

## Por qué no basta un script

Con `if tarjeta.vigente(): abrir()` resuelves un empleado con la bitácora y los relojes
perfectos. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Puede entrar el técnico a la bóveda ahora? | decisión |
| ¿Por qué no se puede borrar este evento? | explicación |
| ¿Qué eventos se pueden borrar hoy? | todas las respuestas |
| ¿Qué tendría que reportar el lector lateral para que la escolta cuente? | la pregunta al revés |
| ¿Qué pasaría si el plazo de la analítica bajara a la mitad? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para saber quién está dentro de un edificio en un instante?
2. Si el reloj de un dispositivo no es de fiar, ¿qué pasa con «antes» y «después»?
3. Si «borrar lo vencido» choca con «no tocar la evidencia», ¿dónde queda escrito quién gana?
4. ¿Cómo distingue tu gemelo «no consta que salió» de «sigue adentro»?
5. En Erlang indexaste eventos por tiempo y viste cámaras fuera de línea. ¿Qué de eso
   alimentaría a este gemelo, y qué decide el gemelo que una bitácora no?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la planta, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar eventos o graficar.

## Supuestos de esta extensión

- Inventado por esta extensión: «Manufacturas Mesa de Otay», sus edificios, personas,
  organigrama, el simulacro y el reglamento (a)-(h) con sus números (nivel B-3, 2
  contratistas por escolta, 1 año y 90 días, 1 y 30 días, dos aprobaciones). Son datos del
  ejercicio, no estadísticas; los plazos caen dentro de los rangos del original.
- Vienen del original: el edificio B, el rango 2:10 a 2:25, el reloj con 4 minutos de
  atraso, los eventos tardíos, el borrado de lo vencido, los hashes y la consulta por
  persona. Las horas y cantidades de los ejemplos (1:50, 2:13, 3:02, «cámara 4», tres
  semanas) son de ilustración.
- Escala reducida: 9 puertas y 6 cámaras, contra 100 puertas, 200 cámaras y 150 eventos/s.
  El «ahora» es un hecho del modelo, no el reloj del sistema; no se calculan hashes.
- Tú defines y declaras: el margen de error de un reloj sin medir o medido hace mucho,
  cuánto silencio vuelve dudoso a un lector, cómo se mide un «turno», qué cuenta como
  ventana de un incidente y qué regla gana en cada choque.

## Extensiones posibles

Para ir más lejos. Estas situaciones no vienen del original: cita tus fuentes antes de
fijar cifras.

- Dos incidentes abiertos cuyas ventanas se traslapan y retienen los mismos eventos.
- Reparto de espacio de almacenamiento entre bitácora y video cuando ya no alcanza.
- Credencial revocada mientras un lector está fuera de línea con su lista vieja.

---
*Las cifras de referencia vienen del problema original; el escenario y su reglamento los
inventa esta extensión. Verifica la fuente vigente antes de citar cualquier cifra.*
