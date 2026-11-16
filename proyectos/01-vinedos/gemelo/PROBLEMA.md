# #1 — Viñedos: gemelo digital con programación lógica

> Extensión del proyecto #1. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el viñedo: sensores que reportan, procesos que fallan y
se reinician. Esa simulación responde «¿qué está pasando?». El viticultor necesita algo
más: «¿qué hago, y por qué?».

El gemelo digital es el **modelo lógico** de la finca: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque lo que hay que
resolver aquí no es calcular, sino deducir, justificar y descartar.

## El viñedo que se clona

Una finca del Valle de Guadalupe, reducida a 3 parcelas con 4 hileras cada una.

| Parte | Contenido |
|---|---|
| Entidades | finca → parcela → hilera → sensor; una válvula de riego por hilera |
| Estado por hilera | humedad de suelo (0-100 % VWC), temperatura del aire (°C), hoja mojada (0-15), largo del brote (cm), etapa de la planta |
| Estado por parcela | lluvia acumulada (mm), temperatura mínima (°C), posición alta o baja en el terreno |
| Eventos | llega una lectura, un sensor deja de reportar, llueve, se abre o cierra una válvula |
| Decisiones | ¿regar?, ¿proteger contra helada?, ¿aplicar fungicida?, ¿confiar en este dato? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original. Las personas (la viticultora, el capataz, la
enóloga) las pone esta extensión para que se vea quién pierde cuando el gemelo se
equivoca. En cada una, tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — El mildiu que nadie ve venir

- **Qué pasa.** Tras días húmedos, un hongo (*Plasmopara viticola*) infecta las hojas.
  Cuando se ven las manchas ya es tarde: el fungicida sirve antes, no después. Fumigar
  toda la finca «por si acaso» le cuesta a la viticultora producto y jornales; no fumigar
  la hilera correcta le cuesta la cosecha. Lo intuitivo es fumigar donde más llovió.
- **Qué datos hay.** Lluvia, temperatura mínima, largo del brote y horas de hoja mojada.
  Ningún sensor mide «hongo».
- **Qué debe deducir.** Qué hileras están en riesgo según la regla agronómica de «los
  tres 10» (unos 10 mm de lluvia, 10 °C de temperatura mínima y brotes de 10 cm) y según
  la hoja mojada continua por 6 a 8 horas o más con 18 a 25 °C.
- **Qué debe contestar.** Dónde aplicar fungicida y por qué; qué hileras están a un solo
  criterio de entrar en riesgo, y cuál es ese criterio; y por qué la hilera más mojada
  de la finca puede quedar fuera de la lista.
- **Por qué es lógica.** El riesgo nace de que varias variables coincidan, no de una
  sola que esté alta: la que más alarma a simple vista puede no cumplir las demás.

### Situación 2 — La helada depende de la etapa

- **Qué pasa.** Una noche la temperatura baja 1.5 °C por hora. Entre 0 y -2 °C se queman
  los brotes y se puede perder buena parte de la producción del año, pero solo si la
  planta ya brotó (marzo-abril). El capataz tiene una sola cuadrilla despierta y no
  alcanza a proteger toda la finca: cada hilera que protege de más es una que deja sin
  proteger. Lo intuitivo es mandarla a la hilera más fría.
- **Qué datos hay.** Temperatura por hilera con su hora, etapa de la planta, posición
  de la parcela (alta o baja) y la hora actual. No hay un dato que diga «en peligro».
- **Qué debe deducir.** En cadena: hacia dónde va la temperatura de cada hilera con el
  ritmo de la noche, luego si llegará a la franja que quema, luego si la planta de esa
  hilera tiene brotes que perder, y por último en qué orden atenderlas.
- **Qué debe contestar.** Qué hileras proteger primero, cuáles no y la razón de cada
  caso; por qué la más fría puede quedar al final; y a cuál se le falla si la cuadrilla
  no alcanza.
- **Por qué es lógica.** La misma lectura significa cosas distintas según la etapa, y la
  emergencia es una conclusión de varios hechos, no la lectura más baja.

### Situación 3 — Regar o no regar

- **Qué pasa.** Una hilera tiene el suelo seco y al mismo tiempo hay alerta de helada.
  El capataz quiere regarla ya: teme perder plantas. La enóloga quiere que siga seca: en
  vid de vino se riega por debajo de la demanda a propósito, y regar de más baja la
  calidad y desperdicia agua de un acuífero sobreexplotado. Los dos tienen razón. Para
  colmo, el sistema se reinició a mitad de un riego y nadie sabe si la válvula quedó
  abierta.
- **Qué datos hay.** Humedad, temperatura y etapa de la hilera; la última orden dada a
  la válvula con su hora y el instante del reinicio. No hay lectura del estado real de
  la válvula.
- **Qué debe deducir.** Qué regla manda cuando la sequía, la helada y el riego
  deficitario se contradicen; y si esa hilera está siendo regada, no lo está o no se
  puede saber.
- **Qué debe contestar.** La decisión, la regla que bloqueó a las otras, a quién se le
  falla (capataz o enóloga) y qué pierde; qué tendría que cambiar para poder regar; y,
  sobre la válvula, «abierta», «cerrada» o «no lo sé», con lo que habría que revisar.
- **Por qué es lógica.** Las prioridades se declaran una vez y valen para todos los
  casos, y la última orden enviada no es lo mismo que lo que la válvula hizo.

### Situación 4 — El dato que no se puede creer

- **Qué pasa.** Un sensor marca 400 % de humedad. Otro lleva horas sin reportar: los
  nodos fallan por batería, polvo y roedores. Un tercero reporta puntual, pero con un
  salto que ningún suelo da de una lectura a la siguiente. Si el gemelo riega o alerta
  por cualquiera de ellos, la viticultora paga agua o una noche de cuadrilla por nada;
  si los descarta todos, deja hileras sin cuidar.
- **Qué datos hay.** Lecturas con su hora, el rango físico de cada variable y la hora
  actual.
- **Qué debe deducir.** Si un dato es válido, imposible o viejo; si el silencio de un
  sensor es una falla o simplemente que nada cambió; y si el sensor que sí reporta es de
  fiar.
- **Qué debe contestar.** Tres respuestas distintas: «sí», «no» y «no lo sé». Nunca
  regar ni alertar por una lectura corrupta, y decir qué dato sacaría a la hilera de la
  duda.
- **Por qué es lógica.** «No se cumple» y «no tengo cómo saberlo» no son lo mismo, y el
  sensor más puntual no es por eso el más creíble.

### Situación 5 — La hilera callada y sus vecinas

- **Qué pasa.** El aire frío se acumula en las partes bajas: dos hileras a 200 m pueden
  diferir 2 o 3 °C. Esa noche, el 10 % de los sensores no reporta, y entre las calladas
  hay hileras ya brotadas. Tratarlas como «sin alerta» puede costar la cosecha de esa
  parcela; tratarlas todas como emergencia agota a la cuadrilla.
- **Qué datos hay.** Qué hileras son vecinas, cuáles están en zona baja, su etapa y las
  lecturas de las que sí reportan.
- **Qué debe deducir.** En cadena: qué vecinas tienen dato creíble, qué dicen de la
  hilera callada según su posición, y si con su etapa eso la vuelve una emergencia.
- **Qué debe contestar.** La inferencia, marcada como inferencia y no como lectura, con
  las vecinas que la sustentan; y cuándo la respuesta honesta es «no lo sé» porque las
  vecinas tampoco tienen dato o no se parecen a ella.
- **Por qué es lógica.** Es razonar sobre relaciones entre entidades, no sobre un valor.

## Por qué no basta un script

Con `if humedad < 30: regar()` resuelves una hilera con datos perfectos. Tu gemelo debe
contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué hago con la hilera 3? | decisión |
| ¿Por qué? | explicación |
| ¿Cuáles hileras se riegan hoy? | todas las respuestas |
| ¿Qué falta para poder regar la 3? | la pregunta al revés |
| ¿Qué pasaría si mañana llueven 15 mm? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir una hilera en un instante?
2. Cuando dos reglas se contradicen, ¿dónde queda escrito cuál gana?
3. ¿Cómo distingue tu gemelo «no hay helada» de «no sé si hay helada»?
4. ¿Qué parte de la explicación le sirve al viticultor y qué parte es ruido?
5. ¿Qué situación de tu simulación en Erlang podría alimentar a este gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del viñedo, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar lecturas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 3 parcelas y 12 hileras, contra las 5 parcelas, ~100 hileras y ~350
  sensores del escenario original.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir.
- Las etapas de la planta y la relación de vecindad entre hileras son datos que tú
  defines en el escenario.
- La viticultora, el capataz, la enóloga y la cuadrilla única son personas del
  ejercicio, no del problema original. Tú decides cuánto silencio vuelve sospechoso a un
  sensor, qué salto es imposible y qué regla gana en cada choque; decláralo.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Fungicida contra plazo de seguridad antes de la vendimia.
- Cuota de agua repartida entre hileras, y capacidad de la bomba.
- Válvula atorada: se ordenó regar y la humedad no sube.
- Condición Santa Ana, ola de calor o humo de incendios cerca de la cosecha.
- Otros hongos (oídio, botritis) con condiciones distintas al mildiu.

---
*Las cifras son de referencia y vienen del problema original. Verifica la fuente vigente
antes de citarlas en tu entrega.*
