# #54 — Gestión de agua: gemelo digital con programación lógica

> Extensión del proyecto #54. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang montaste la red: un proceso por sensor o medidor, un agregador por
colonia y un detector de fugas que levanta una alerta. Esa simulación responde «¿qué está
midiendo cada cosa y cuándo suena la alarma?». El organismo operador del agua necesita
algo más: «¿hay una fuga, dónde, cuánta certeza tengo, y a dónde mando la única cuadrilla
que tengo?».

El gemelo digital es el **modelo lógico** de la red: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque aquí no se resta
un caudal de otro: se deduce, se justifica y se sabe decir «no lo sé».

## La red de agua que se clona

Una zona de Tijuana, reducida a 4 colonias de una ciudad de colinas: dos en la parte alta
y dos en la baja. Cada colonia tiene un macromedidor de entrada, 3 sensores de presión
(uno por tramo de tubería) y tomas domiciliarias, unas con medidor inteligente (reporta
cada hora) y otras con medidor tradicional (se lee una vez al mes). Dos colonias cuelgan
de la misma línea. Una colonia recibe el agua por tandeo y otra tiene una clínica. Hay
una sola cuadrilla. Los nombres, la clínica y la línea compartida son ejemplos de esta
extensión; la presión, el flujo nocturno y los medidores son los del original.

| Parte | Contenido |
|---|---|
| Entidades | línea → colonia → tramo con sensor de presión; macromedidor; tomas; clínica; cuadrilla |
| Estado por colonia | caudal de entrada (cada 5 min), presión por sensor, posición alta o baja, si hay tandeo |
| Estado por toma | consumo reportado (inteligente: por hora; tradicional: última lectura mensual) |
| Eventos | llega una lectura (a veces tarde o fuera de orden), vuelve el tandeo, hay un evento público, un vecino reporta que no sube el agua, llega la cuadrilla |
| Decisiones | ¿es fuga o consumo?, ¿cuánta pérdida es segura?, ¿ruptura o sensor mentiroso?, ¿a dónde va la cuadrilla? |

## Situaciones que tu gemelo debe razonar

Cuatro de las cinco salen del problema original. La 5 es derivada: toma del original el
balance de pérdidas, las fugas y las tomas clandestinas, y del foco del eje, que hay que
juzgar una fuga probable con presión y consumo; ubicar el tramo por sensor es un
complemento. En cada una, tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — Caudal alto de madrugada: ¿fuga o tinacos?

- **Qué pasa.** Entre las 2 y las 4 a. m. casi nadie consume, así que un caudal de entrada
  alto delata una fuga. Esa noche dos colonias entran por encima de lo habitual, algo
  como el 15 % del escenario original. En una de ellas el tandeo devolvió el agua
  pasada la medianoche y los tinacos se están llenando; la otra no tiene tandeo, y el
  calor de la semana solo explica el consumo de la tarde. Si mandas la cuadrilla a la
  equivocada, la fuga real sigue tirando agua y alguien duerme sin presión.
- **Qué datos hay.** Caudal de entrada de cada colonia cada 5 minutos, consumo por hora de
  las tomas inteligentes, eventos de la noche (regreso del tandeo, calor) y cuántas tomas
  de cada colonia reportan de verdad esa noche.
- **Qué debe deducir.** En qué colonia el exceso nocturno es consumo legítimo, en cuál es
  fuga probable y en cuál no alcanza la evidencia. Ningún sensor mide «fuga».
- **Qué debe contestar.** «Fuga probable», «consumo legítimo» o «no lo sé», con los
  hechos que lo sustentan y qué observación cambiaría la respuesta.
- **Por qué es lógica.** La misma lectura significa cosas distintas según el contexto de
  la colonia; lo intuitivo (el caudal nocturno más alto es la fuga) es justo lo que hay
  que desconfiar.

### Situación 2 — El balance que no cierra

- **Qué pasa.** El agua que entra menos la suma de lo medido en las tomas es la pérdida.
  Pero esta hora, en una colonia baja, tres tomas son tradicionales (última lectura de
  hace semanas), una inteligente no ha reportado y la lectura de otra llegó después de
  una más reciente. El informe de agua no contabilizada del organismo sale con esa cifra.
- **Qué datos hay.** Entrada del macromedidor, lecturas de las tomas con su instante de
  medición y su instante de llegada, y el tipo de medidor de cada una.
- **Qué debe deducir.** Cuánta pérdida es segura aunque lo que falta fuera lo peor
  posible, cuánta es aparente por datos faltantes, y qué lecturas no se pueden comparar
  todavía por llegar fuera de orden.
- **Qué debe contestar.** «Hay pérdida» (aun suponiendo lo más favorable), «no hay» o
  «no se puede saber con lo que llegó», nunca «hay fuga» por una resta incompleta. Lo
  intuitivo, tratar lo que falta como consumo cero, convierte cada hueco en una fuga.
- **Por qué es lógica.** «No hay dato» y «el dato es cero» no son lo mismo; el balance
  parcial acota la respuesta pero no la fija.

### Situación 3 — Caída de presión: ¿ruptura o sensor mentiroso?

- **Qué pasa.** Un sensor de una colonia baja marca desde hace días una presión distinta
  a la de sus hermanos: está descalibrado y los operadores ya lo ignoran. Hoy, a media
  tarde, la presión de esa colonia cae de golpe, sube el caudal de entrada y, desde la
  colonia alta que cuelga de la misma línea, llega un aviso de que no sube el agua. Una
  ruptura mayor se mide en minutos: calle inundada, colonia sin agua y una clínica en la
  parte alta.
- **Qué datos hay.** Lecturas de presión de los 3 sensores de cada colonia, el caudal de
  entrada, los avisos de vecinos, la línea compartida y la bitácora de qué sensor se
  sospecha descalibrado.
- **Qué debe deducir.** Qué sensores son confiables y para qué, si hay ruptura mayor
  probable y de qué lado de la línea.
- **Qué debe contestar.** «Ruptura probable», «sensor descalibrado» o «no lo sé», qué
  hacer en los próximos minutos y con qué evidencia. Un sensor sospechoso no se trata
  igual para todos los usos: el gemelo dice para qué sirve aún y para qué no.
- **Por qué es lógica.** Lo que dice el sistema (esa lectura nunca es confiable) choca
  con lo que pasa (caudal y avisos coinciden); la regla decide a quién se le cree.

### Situación 4 — Una cuadrilla, cinco fugas

- **Qué pasa.** Hay cinco fugas sospechadas y una sola cuadrilla. La de mayor pérdida está
  ya confirmada en una colonia baja, pero no afecta a nadie. Otra, más pequeña, deja con
  poca presión a la clínica de la colonia alta. Una tercera es dudosa y solo se ubica
  hasta un tramo. La cuarta está en la colonia de tandeo, y regresa el agua pronto. La
  quinta está reportada, sin pruebas, por tercera vez. Cualquier orden le falla a alguien.
- **Qué datos hay.** Cada fuga con su evidencia y su certeza (salidas de las situaciones
  1 a 3 y 5), colonia, instalaciones críticas afectadas, dónde está la cuadrilla y cuánto
  tarda en llegar a cada colonia.
- **Qué debe deducir.** Un orden de atención y por qué cada fuga cede su lugar a la
  siguiente.
- **Qué debe contestar.** El orden completo, la razón de cada lugar, a quién se le falla
  con ese orden y qué tendría que cambiar para que otra fuga pasara primero.
- **Por qué es lógica.** Es un dilema real donde dos partes tienen razón (volumen perdido
  contra riesgo para una clínica); las prioridades se declaran una vez, y la fuga que más agua pierde no
  tiene por qué ir primero.

### Situación 5 — La fuga que nadie ve

- **Qué pasa.** Una colonia baja pierde agua por el balance de la madrugada, pero no hay
  alarma: la presión está dentro de rango. La pérdida puede ser una fuga en la tubería o
  una toma clandestina, y mandar a la cuadrilla de fugas no sirve si es lo segundo.
  Además, de noche la presión sube sola porque casi nadie consume, y eso engaña.
- **Qué datos hay.** Entrada nocturna, consumo de las tomas inteligentes, presión de los
  3 sensores de la colonia comparada con su propio comportamiento normal y con las
  colonias vecinas, y a qué hora ocurre la pérdida.
- **Qué debe deducir.** Si la pérdida es real o aparente, en qué tramo de tubería es más
  probable una fuga, y cuál sensor no tiene dato esa noche. Son al menos tres pasos
  encadenados, y ninguno es una lectura directa.
- **Qué debe contestar.** «Fuga probable en el tramo X», «pérdida aparente» (consumo no
  medido) o «no lo sé», marcada como inferencia y con los sensores y las tomas que la
  sustentan. Lo intuitivo, «presión normal quiere decir que no hay fuga», no es válido.
- **Por qué es lógica.** Es razonar sobre relaciones entre entidades: tramos, sensores,
  tomas y horas. Una fuga baja la presión local, pero la demanda baja la sube.

## Por qué no basta un script

Con `if caudal_nocturno > promedio * 1.15: mandar_cuadrilla()` resuelves una colonia con
datos perfectos. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué hago con Valle Bajo esta madrugada? | decisión |
| ¿Por qué lo de Mesa Norte no es fuga? | explicación |
| ¿Qué colonias tienen hoy una fuga probable? | todas las respuestas |
| ¿Qué tendría que llegar para afirmar que no hay pérdida en Valle Bajo? | la pregunta al revés |
| ¿Qué pasaría si el sensor 2 de Valle Bajo dejara de reportar? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para decir cuánta agua debería entrar a una colonia a las 3 a. m.?
2. Si el balance no cierra por datos que no llegaron, ¿qué afirma tu gemelo y qué deja
   como «no lo sé»?
3. ¿Cómo distingue tu gemelo un sensor descalibrado de una caída real de presión?
4. Con una sola cuadrilla, ¿dónde queda escrito quién cede y cómo se le explica?
5. En tu prueba de caos matas el proceso de un sensor de presión: mientras se reinicia
   no hay lecturas. ¿Qué diferencia tu gemelo entre ese silencio y una presión que de
   verdad no cambió?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la red, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar lecturas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 4 colonias (2 altas, 2 bajas), 3 sensores de presión por colonia, un
  macromedidor por colonia y unas pocas tomas por colonia, contra las 12 colonias y los
  5 sensores por colonia del original. El original menciona un macromedidor; aquí cada
  colonia tiene el suyo para poder hacer balance por zona.
- Los nombres de las colonias, la clínica, la línea compartida, el tandeo en una colonia
  concreta, los avisos de vecinos, la cuadrilla única y los tiempos de traslado son
  ejemplos de esta extensión. El «sensor 2» y las cinco fugas son identificadores de los
  ejemplos. Las tomas clandestinas y la fuga como causa de pérdidas vienen del original.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir; la unidad que más sirve es el minuto desde la medianoche.
- Defines tú, con su fuente: cuánto caudal nocturno es normal por colonia, cuánta
  diferencia lo vuelve anormal (el 15 % es del escenario simulado, no una regla),
  cuánto retraso vuelve dudosa una lectura, cuánto sesgo vuelve descalibrado a un sensor,
  el rango físico válido de cada sensor, qué es una instalación crítica, cuánto pesa
  cada criterio para ordenar la cuadrilla, y los minutos de traslado.
- El original no da cuántas tomas tiene una colonia ni cuánto consume una toma
  clandestina: si una regla lo necesita, es tu supuesto, con fuente.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Cerrar válvulas de sector para aislar una ruptura y cuántas colonias se quedan sin agua.
- Costo de reparar contra costo del agua que se sigue perdiendo.
- Calidad del agua: qué pasa con el riesgo de contaminación cuando cae la presión.
- Proyección de consumo para planear el suministro de la semana siguiente.
- Presión mínima para que el agua llegue a los pisos altos y qué colonias la incumplen.

---
*Las cifras de dominio (presiones de 10 a 50 m de columna de agua, flujo mínimo nocturno
entre las 2 y las 4 a. m., 15 % más de caudal nocturno, lecturas cada 5 minutos, medidores
inteligentes cada hora contra lectura mensual, unos 40 % de agua no contabilizada, 150 a 250
litros por persona al día) vienen del problema original y son de referencia; verifica la
fuente vigente antes de citarlas. Las colonias, la clínica y la línea compartida son de
esta extensión.*
