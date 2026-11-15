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

Las cinco salen del problema original. En cada una, tu gemelo debe llegar a una decisión
**y poder explicarla**.

### Situación 1 — El mildiu que nadie ve venir

- **Qué pasa.** Tras días húmedos, un hongo (*Plasmopara viticola*) infecta las hojas.
  Cuando se ven las manchas ya es tarde: el fungicida sirve antes, no después.
- **Qué datos hay.** Lluvia, temperatura mínima, largo del brote y horas de hoja mojada.
  Ningún sensor mide «hongo».
- **Qué debe deducir.** Qué hileras están en riesgo según la regla agronómica de «los
  tres 10» (unos 10 mm de lluvia, 10 °C de temperatura mínima y brotes de 10 cm) y según
  la hoja mojada continua por 6 a 8 horas o más con 18 a 25 °C.
- **Qué debe contestar.** Dónde aplicar fungicida y por qué; qué hileras están a un solo
  criterio de entrar en riesgo, y cuál es ese criterio.
- **Por qué es lógica.** El riesgo nace de que varias variables coincidan, no de una
  sola que esté alta.

### Situación 2 — La helada depende de la etapa

- **Qué pasa.** Una noche la temperatura baja 1.5 °C por hora. Entre 0 y -2 °C se queman
  los brotes y se puede perder buena parte de la producción del año, pero solo si la
  planta ya brotó (marzo-abril).
- **Qué datos hay.** Temperatura por hilera y etapa de la planta.
- **Qué debe deducir.** En qué hileras la helada es una emergencia y en cuáles no importa.
- **Qué debe contestar.** Qué hileras proteger, cuáles no, y la razón de cada caso.
- **Por qué es lógica.** La misma lectura significa cosas distintas según el contexto.

### Situación 3 — Regar o no regar

- **Qué pasa.** Una hilera tiene el suelo seco y al mismo tiempo hay alerta de helada.
  Además, en vid de vino se riega por debajo de la demanda a propósito: regar de más
  baja la calidad y desperdicia agua de un acuífero sobreexplotado.
- **Qué datos hay.** Humedad, temperatura y etapa.
- **Qué debe deducir.** Qué regla manda cuando dos se contradicen.
- **Qué debe contestar.** La decisión, la regla que la bloqueó y qué tendría que cambiar
  para poder regar.
- **Por qué es lógica.** Las prioridades se declaran una vez y valen para todos los casos.

### Situación 4 — El dato que no se puede creer

- **Qué pasa.** Un sensor marca 400 % de humedad. Otro lleva horas sin reportar: los
  nodos fallan por batería, polvo y roedores.
- **Qué datos hay.** Lecturas con su hora y el rango físico de cada variable.
- **Qué debe deducir.** Si un dato es válido, imposible o viejo; y si el silencio de un
  sensor es una falla o simplemente que nada cambió.
- **Qué debe contestar.** Tres respuestas distintas: «sí», «no» y «no lo sé». Nunca
  regar ni alertar por una lectura corrupta.
- **Por qué es lógica.** «No se cumple» y «no tengo cómo saberlo» no son lo mismo.

### Situación 5 — La hilera callada y sus vecinas

- **Qué pasa.** El aire frío se acumula en las partes bajas: dos hileras a 200 m pueden
  diferir 2 o 3 °C. Esa noche, el 10 % de los sensores no reporta.
- **Qué datos hay.** Qué hileras son vecinas, cuáles están en zona baja y las lecturas
  de las que sí reportan.
- **Qué debe deducir.** El estado probable de una hilera sin dato a partir de sus vecinas.
- **Qué debe contestar.** La inferencia, marcada como inferencia y no como lectura, con
  las vecinas que la sustentan.
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
