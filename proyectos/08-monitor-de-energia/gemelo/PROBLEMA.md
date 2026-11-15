# #8 — Monitor de energía: gemelo digital con programación lógica

> Extensión del proyecto #8. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste medidores que se consultan cada 5 s por un bus lento, con
fallas inyectadas, consumo por piso y alarmas. Esa simulación responde «¿qué marca cada
medidor?». El administrador necesita algo más: «¿qué pasará con mi cargo del mes, a qué
lectura le creo y de quién es este consumo?».

El gemelo digital es el **modelo lógico** del edificio: hechos que reflejan su estado y
reglas que reflejan cómo se decide en él. Se escribe en Prolog porque aquí no hay que
calcular una suma, sino deducir, justificar y distinguir lo que se sabe de lo que no.

## El edificio que se clona

Un edificio de tres pisos en un campus de Tijuana, reducido a 7 medidores en 2 buses
RS-485. La administración del campus paga la factura y reparte el costo entre áreas.

| Parte | Contenido |
|---|---|
| Entidades | edificio → piso → área → medidor; dos buses que se consultan medidor por medidor |
| Lugares | acometida; piso 1: taller (con tres motores: bomba de cisterna, compresor, extractor); piso 2: laboratorio y oficinas, que comparten un medidor; piso 3: aulas |
| Estado por medidor | V, A, kW, kVAr, kWh acumulado, Hz; instante de cada lectura; resultado de cada consulta (respuesta o timeout) |
| Estado por edificio | potencia promedio de la ventana de 15 min en curso, límite de demanda, topología eléctrica (qué medidor cuelga de cuál) |
| Eventos | llega una lectura o un timeout, arranca un motor, un medidor se reinicia, cambia la ventana |
| Decisiones | ¿avisar antes de rebasar?, ¿a qué lectura creerle?, ¿de quién es este consumo?, ¿a qué medidor aislar?, ¿de dónde viene esta alarma? |

## Situaciones que tu gemelo debe razonar

Cuatro salen directo del problema original (casos difíciles, escenario y pregunta guía
2). La 4 está construida con datos del original, que menciona la caída de voltaje y el
arranque de motores pero no plantea distinguir su causa. Las situaciones 1, 2 y 5 añaden
un detalle derivado, señalado en su texto. En cada una, tu gemelo debe llegar a una
decisión **y poder explicarla**.

### Situación 1 — El pico que todavía no ocurre

- **Qué pasa.** La demanda máxima se mide como promedio de potencia en ventanas de 15 min
  y un pico de unos minutos puede definir el cargo del mes. Los tres motores del taller
  van a arrancar casi juntos y el administrador quiere el aviso antes de que la ventana
  cierre arriba del límite. Si diferir un arranque salva el cargo, ¿cuál? La bomba de la
  cisterna, el compresor y el extractor no valen lo mismo (esa prioridad es un detalle
  derivado que defines tú).
- **Qué datos hay.** Potencia cada 5 s, el inicio de la ventana en curso, el límite y el
  arranque previsto de cada motor. Ningún medidor mide «cómo va a cerrar la ventana».
- **Qué debe deducir.** Con qué promedio cerraría la ventana, según lo ya consumido, lo
  que se consume ahora y lo que sumarían los arranques; y qué tan firme es si falta una
  lectura.
- **Qué debe contestar.** Si hay alarma anticipada y con cuánto margen; qué arranque
  conviene diferir y hasta cuándo se puede esperar; a quién se le falla con cada opción.
  Un pico muy alto pero brevísimo al inicio de la ventana y una carga moderada sostenida
  hacia el final no se parecen en riesgo; la intuición suele errar en cuál es peor.
- **Por qué es lógica.** Encadena lo acumulado, el tiempo que falta, la carga esperada y
  las prioridades; la misma regla vale al inicio, a la mitad y al final de la ventana.

### Situación 2 — El contador que vuelve a cero y el piso que no suma

- **Qué pasa.** El medidor de alumbrado del piso 1 deja de contestar un rato y luego
  reporta un kWh acumulado mucho menor que el anterior. Los kWh son un contador que
  puede reiniciarse o desbordarse, y el taller paga lo que marque el piso. El medidor
  general del piso, aguas arriba, sirve para cruzar datos (detalle derivado: el original
  no habla de medidores de cabecera).
- **Qué datos hay.** Lecturas de kWh con su instante, huecos de consulta, un posible
  evento de reinicio, el máximo del contador y el consumo del medidor general del piso y
  de los demás que cuelgan de él.
- **Qué debe deducir.** Si el salto es reinicio, desbordamiento o dato corrupto; cuánto
  consumo se perdió en el hueco, o entre qué valores pudo estar; y el consumo del piso.
- **Qué debe contestar.** El consumo del piso como «se sabe», «está entre tal y tal» o
  «no se puede saber», con las lecturas que sustentan cada una.
- **Por qué es lógica.** Ningún medidor reporta consumo perdido: se deduce de la
  diferencia entre medidores que no se ponen de acuerdo, y «no sé cuánto» no es «cero».

### Situación 3 — El medidor lento y los que pagan por él

- **Qué pasa.** En un bus los medidores se consultan uno por uno. Uno responde lento y
  los que vienen después en el ciclo llegan tarde, o con timeout. Los timeouts son
  frecuentes, así que no todo timeout es culpa de quien lo sufre. Si el medidor de
  motores llega tarde, pueden esconderse arranques justo cuando la demanda más importa.
- **Qué datos hay.** El orden de consulta en el bus, cuánto tardó cada respuesta, los
  timeouts y el instante real de cada lectura.
- **Qué debe deducir.** Cuál medidor causa el retraso y cuáles son víctimas; qué lecturas
  están viejas por culpa del bus; y qué alarmas o proyecciones se apoyan en ellas.
- **Qué debe contestar.** A cuál medidor aislar del ciclo, por qué él y no el que más
  timeouts tiene, y qué alarmas pasan a «no sé» mientras tanto.
- **Por qué es lógica.** La causa está en la posición dentro de una cadena, no en un solo
  valor, y una alarma sin lectura fresca no es una alarma apagada.

### Situación 4 — ¿La red o nuestros motores?

- **Qué pasa.** Cae el voltaje en el piso 1 justo cuando arrancan los motores. Si es la
  red de la CFE, hay que reportarla y proteger equipos; si son los motores propios, hay
  que escalonar los arranques. Equivocarse cuesta equipos dañados o un reporte falso.
- **Qué datos hay.** Voltaje y potencia de cada medidor con su instante, los eventos de
  arranque, qué medidor cuelga de cuál (acometida, tableros, pisos) y los timeouts.
- **Qué debe deducir.** Si la caída es de la red, de los arranques, de un solo medidor o
  indeterminada, según dónde se ve y cuándo: ¿cae la acometida?, ¿caen pisos sin
  motores?, ¿la potencia sube antes o después de la caída?
- **Qué debe contestar.** La causa más probable, qué evidencia la sostiene, qué otra
  explicación quedó descartada y qué dato faltante la cambiaría.
- **Por qué es lógica.** El umbral solo dice «voltaje bajo»; el diagnóstico sale de
  relaciones entre medidores y, con timeouts, a veces la respuesta honesta es «no sé».

### Situación 5 — Un medidor, dos áreas, un cargo

- **Qué pasa.** El laboratorio y las oficinas del piso 2 comparten un medidor, y la
  administración les reparte el recibo. El laboratorio tiene equipos que nunca se apagan,
  así que su consumo nocturno parece «inusual» a cualquier alarma de madrugada. También
  hay que repartir el cargo por demanda máxima y, si el factor de potencia baja de 0.90,
  la penalización (detalle derivado). Las dos áreas tienen argumentos válidos para pagar
  menos.
- **Qué datos hay.** Consumo y potencia del medidor compartido a lo largo del día, el
  horario de uso de cada área, sus equipos declarados y las ventanas de demanda.
- **Qué debe deducir.** Qué parte del consumo es del laboratorio y cuál de las oficinas,
  aunque nada las mida por separado; si la alarma de consumo nocturno es anomalía o es
  lo esperado; y quién contribuyó a la ventana máxima.
- **Qué debe contestar.** Un reparto con la regla que lo produjo y cuán firme es; a qué
  área se le falla si la regla se equivoca; y por qué quien más energía consume no es
  necesariamente quien más pesa en el cargo por demanda.
- **Por qué es lógica.** Hay que fijar criterios, declarar el desempate y explicar por
  qué ese reparto y no otro: es una política, no una división.

## Por qué no basta un script

Con `if kw > limite: alarma()` resuelves un medidor con datos perfectos. Tu gemelo debe
contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué hago con la ventana de demanda ahora? | decisión |
| ¿Por qué no me avisa del medidor de motores? | explicación |
| ¿Cuáles lecturas están viejas por culpa del bus? | todas las respuestas |
| ¿Qué tendría que cambiar para que no haya alarma de rebase? | la pregunta al revés |
| ¿Qué pasaría si el compresor arranca diez minutos después? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir un medidor y su lugar en el bus en un instante?
2. Cuando dos reglas chocan (aviso de demanda contra prioridad de un motor), ¿dónde queda
   escrito cuál gana?
3. ¿Cómo distingue tu gemelo «no hay alarma» de «no tengo lectura fresca para saberlo»?
4. ¿Qué parte de la explicación le sirve al administrador y qué parte es ruido?
5. ¿Qué parte de tu simulación en Erlang (el proceso por medidor, el agregador por piso,
   el evaluador de umbrales) podría alimentar a este gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del edificio, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar lecturas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 7 medidores en 2 buses y 3 pisos, contra los 30 medidores en 3 buses
  del escenario original. Se conservan la consulta cada 5 s y el horizonte de 24 h.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir.
- Los nombres (taller, laboratorio, oficinas, aulas, motores) y la distribución de
  medidores son de esta extensión, no del original.
- Los define el estudiante, porque el original no los da: el límite de demanda, la
  potencia de los motores, cuándo un medidor es «lento» y un voltaje «bajo», el máximo
  del contador, si la ventana de 15 min es fija o móvil, los horarios, el criterio de
  reparto y la prioridad entre motores.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Tarifas por periodo (base, intermedio, punta) y mover carga de un periodo a otro.
- Factor de potencia de todo el edificio y compensación con capacitores.
- Distorsión armónica (THD), calidad de la energía y generación propia con paneles
  solares restada a la demanda.
- Criterios de reparto alternos: por horas de uso, por área construida o con
  submedidores temporales.

---
*Las cifras son de referencia y vienen del problema original, que las da como órdenes de
magnitud. Verifica la fuente vigente antes de citarlas en tu entrega.*
