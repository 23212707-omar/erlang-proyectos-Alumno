# #56 — Sismos: gemelo digital con programación lógica

> Extensión del proyecto #56. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la ingesta: reportes de varias fuentes, procesos que los
deduplican y un despachador de alertas por nivel. Esa simulación responde «¿qué llegó y
qué se envió?». Protección Civil necesita algo más: «¿qué tan fuerte se sentirá donde me
importa, a quién aviso, y debo corregir lo que ya dije?».

El gemelo digital es el **modelo lógico** de la vigilancia sísmica: hechos que reflejan
lo que reportan las fuentes y reglas que reflejan cómo se decide un aviso. Se escribe en
Prolog porque aquí no se calcula: se deduce, se justifica y se distingue lo que se sabe
de lo que no.

## La vigilancia que se clona

Una oficina de vigilancia sísmica de Baja California, reducida a 3 fuentes de datos, 4
ubicaciones de interés (un hospital en Mexicali, una escuela en Tecate, el puerto de
Ensenada y Protección Civil en Tijuana) y unos cuantos sismos sobre las fallas citadas.

| Parte | Contenido |
|---|---|
| Entidades | fuente → reporte → sismo (la identidad que el gemelo deduce); ubicación de interés; aviso enviado |
| Estado por reporte | fuente, revisión, origen (hora y lugar), magnitud, profundidad (puede faltar), llegada |
| Estado por ubicación | coordenadas, tipo de suelo, tipo (hospital, escuela, puerto) |
| Estado por fuente | reportando, caída o atrasada |
| Eventos | llega un reporte o una revisión, una fuente se cae o vuelve, se envía un aviso |
| Decisiones | ¿mismo sismo?, ¿qué tanto se siente aquí?, ¿avisar a quién y con qué nivel?, ¿rectificar?, ¿creer este silencio? |

## Situaciones que tu gemelo debe razonar

Las cinco parten de casos, datos o preguntas del problema original; la profundidad, el
suelo y el tipo de ubicación son complementos que esta extensión añade y se listan en
«Supuestos». En cada una, tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — ¿Un sismo o dos?

- **Qué pasa.** Lo que llega son reportes, no sismos. Tres fuentes cuentan lo mismo con
  hora, lugar y magnitud algo distintos, y sus revisiones se cruzan. Dos reportes casi
  idénticos pueden ser dos sismos (una réplica tras el principal); dos que discrepan
  pueden ser uno. Avisar doble gasta la confianza de la gente; fundir dos en uno deja
  sin aviso al lugar que sintió el segundo.
- **Qué datos hay.** Reportes con su fuente, revisión, hora de llegada, hora y lugar de
  origen, magnitud y, cuando la traen, profundidad.
- **Qué debe deducir.** A qué sismo pertenece cada reporte. Es una cadena: A se parece
  a B, B se parece a C, ¿son A y C el mismo? Nadie mide «este es el sismo».
- **Qué debe contestar.** Los sismos distintos, los reportes de cada uno, en qué datos
  coinciden y en cuáles discrepan; por qué dos reportes parecidos se separaron; y «no
  lo sé» cuando la evidencia no alcanza (entonces ni se avisa doble ni se calla).
- **Por qué es lógica.** La identidad es una relación entre reportes que se razona con
  evidencia. Lo intuitivo, «misma magnitud y casi la misma hora son el mismo sismo», es
  sospechoso: puede ser una réplica. Y discrepar en magnitud no hace distintos a dos.

### Situación 2 — La revisión que llega después del aviso

- **Qué pasa.** Un M6.5 cercano se revisa tres veces en diez minutos y la magnitud
  inicial puede cambiar en 0.3 o más. Ya salieron avisos a algunas ubicaciones. Si la
  revisión baja, mantener el aviso fuerte es falsa alarma; si sube, quedarse con el
  viejo es silencio. Ambas partes tienen razón. Además, la última revisión en llegar no
  siempre es la vigente: una fuente atrasada puede traer una anterior.
- **Qué datos hay.** Revisiones con su fuente y su llegada, avisos enviados (ubicación,
  nivel, instante) y el efecto probable en cada ubicación (situación 3).
- **Qué debe deducir.** Qué revisión manda, qué nivel le toca ahora a cada ubicación y
  cómo se compara con lo ya enviado. Cadena: revisión vigente → efecto aquí → nivel →
  diferencia con el aviso → acción. Nadie mide «hay que rectificar».
- **Qué debe contestar.** Por ubicación: no hacer nada, aclarar, escalar o rectificar,
  con la razón. También a quién se le falla con esa política y qué revisión haría
  cambiar la respuesta.
- **Por qué es lógica.** Los niveles y las prioridades se declaran una vez. Una misma
  corrección es ruido en una ubicación y obliga a avisar de nuevo en otra, y lo obvio
  («si bajó, retiro el aviso») no siempre es lo correcto.

### Situación 3 — Cuánto se siente aquí

- **Qué pasa.** Un M4 a 20 km se siente; uno a 800 km no. La magnitud sola no dice qué
  pasa en un lugar: importan la distancia, la profundidad y el suelo. Y el aviso solo es
  «temprano» si llega antes de las ondas S (las destructivas); después es información
  para la respuesta. Avisar de más hace que un hospital suspenda operaciones por nada;
  callar le quita segundos a quien podía protegerse.
- **Qué datos hay.** Magnitud, profundidad (puede faltar), lugar de origen, coordenadas,
  suelo y tipo de cada ubicación, velocidades de las ondas P y S y cuánto tardó el
  aviso en salir desde el origen.
- **Qué debe deducir.** El efecto probable en cada ubicación y si el aviso llegaría
  antes o después de las S. Ningún sensor mide «se sentirá fuerte en el hospital».
- **Qué debe contestar.** Por ubicación: se sentirá fuerte, leve, nada o «no lo sé»; y
  aviso temprano, informativo o ninguno. Con profundidad desconocida, «no lo sé» con lo
  que habría que saber, no un valor inventado.
- **Por qué es lógica.** Lo intuitivo, «el sismo más grande es el que más afecta», está
  mal: uno menor, cercano y somero puede pesar más que uno mayor lejano. El efecto
  sale de combinar varios hechos y se explica citándolos.

### Situación 4 — La fuente que se calla

- **Qué pasa.** Una fuente se cae y otra manda eventos atrasados. Sin reportes nuevos
  parece que todo está tranquilo, pero si la fuente caída era la única que cubría una
  zona, el silencio es ceguera. Un reporte atrasado de un sismo ya avisado no es aviso
  nuevo; el de uno nunca visto sí importa para la respuesta, aunque ya no sea temprano.
  Paga el error quien no se entera, o quien recibe aviso doble de algo que ya pasó.
- **Qué datos hay.** Hora de origen y hora de llegada de cada reporte, cuándo cayó y
  volvió cada fuente, y qué reportó cada una antes de callar.
- **Qué debe deducir.** Qué reportes son atrasados, si están ya contados en un sismo
  conocido (situación 1) y si el estado «sin sismos» es verdad o solo falta de datos.
  Cadena: caída de fuente → reportes atrasados → identidad → efecto sobre el aviso.
- **Qué debe contestar.** Tres respuestas: «hay sismo», «no hay sismo» y «no lo sé»; y
  para cada reporte atrasado qué se hace con él y por qué.
- **Por qué es lógica.** «No hay reportes» y «no me enteré» no son lo mismo. Lo
  intuitivo, «sin reportes, sin sismo», es falso cuando una fuente está caída.

### Situación 5 — Réplicas y enjambre

- **Qué pasa.** Tras el M6.5 llegan decenas de eventos pequeños, dentro de un flujo de
  unos 50 por hora. Unos son réplicas del principal; otros, un enjambre aparte. Avisar
  cada uno satura y la gente deja de hacer caso; callarlos puede ocultar la réplica que
  en Tecate se sintió más que el principal. Dos partes con razón.
- **Qué datos hay.** Los sismos ya identificados (situación 1), su hora y lugar con
  respecto al principal, el efecto en cada ubicación y los avisos vigentes.
- **Qué debe deducir.** Qué eventos son réplicas de cuál principal, si un grupo es
  enjambre y cuál evento, por lo que produce en alguna ubicación, merece aviso propio.
  Cadena: identidad → relación con el principal → efecto aquí → comparación con lo
  avisado → aviso o resumen.
- **Qué debe contestar.** Por evento: aviso propio, incluido en un resumen o sin aviso,
  con la razón; y cuál evento rompió la regla general y por qué.
- **Por qué es lógica.** Evitar el silencio y evitar la falsa alarma se contradicen, y
  la regla debe decidir y justificar a quién se le falla.

## Por qué no basta un script

Con `if magnitud > UMBRAL: enviar_alerta()` resuelves un reporte aislado y confiable.
Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué aviso mando al hospital de Mexicali por este sismo? | decisión |
| ¿Por qué no se avisó de la réplica de las 3? | explicación |
| ¿A qué ubicaciones se avisa ahora? | todas las respuestas |
| ¿Qué tendría que reportar la fuente B para avisar a Tecate? | la pregunta al revés |
| ¿Qué pasaría si la próxima revisión sube la magnitud? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Cuál es la identidad de un sismo si las fuentes discrepan, y qué puede discrepar sin
   que deje de ser el mismo?
2. ¿Cuándo una revisión amerita volver a avisar y cuándo solo corregir el dato?
3. ¿Dónde queda escrito que un sismo mayor y lejano puede pesar menos que uno menor y
   cercano?
4. ¿Cómo distingue tu gemelo «no hubo sismos» de «no me enteré de ninguno»?
5. ¿Qué parte de tu simulación en Erlang (ingesta, deduplicación, despachador) podría
   alimentar a este gemelo con reportes y avisos como hechos?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la vigilancia, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar reportes simulados o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 3 fuentes, 4 ubicaciones y unos cuantos sismos, contra las varias
  redes y los 50 eventos por hora del original.
- El «ahora» es un hecho del modelo, en segundos, no el reloj del sistema, para que las
  respuestas se puedan repetir.
- Lugares, coordenadas, suelos, tipo de ubicación, número de niveles de alerta y los
  identificadores de los ejemplos («fuente B», «las 3») los defines tú. Profundidad,
  suelo y tipo de ubicación son complementos de esta extensión; el original no les da
  cifras.
- Estos umbrales tampoco los da el original; son tuyos y los documentas: cuánta
  diferencia de hora, lugar y magnitud hace «el mismo» a dos reportes; qué revisión
  obliga a avisar; desde qué efecto se avisa; cuánto silencio o retraso vuelve
  sospechosa a una fuente; cuántos eventos forman un enjambre.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Tsunami tras un sismo bajo el mar frente a la costa.
- Aviso a infraestructura (válvulas, transporte) con el costo de un falso positivo.
- Daño estimado según tipo de construcción y no solo según suelo.
- Probabilidad de réplicas mayores en las horas siguientes.

---
*Las cifras (velocidades de ondas, 13 s a 100 km, 0.3 de revisión, M4 a 20 km, 50 eventos
por hora, M6.5 con tres revisiones) vienen del problema original; escalas, lugares y
umbrales del escenario son de esta extensión. Verifica la fuente vigente antes de citar.*
