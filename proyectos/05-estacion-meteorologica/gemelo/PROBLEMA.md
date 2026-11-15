# #5 — Estación meteorológica: gemelo digital con programación lógica

> Extensión del proyecto #5. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la red: sensores que mandan muestras, una tabla con
ventanas de promedios, un agregador que calcula, procesos que fallan y se reinician. Esa
simulación responde «¿cuánto vale el promedio?». El encargado de avisos de Protección
Civil necesita otra cosa: «¿emito el aviso, y puedo creerle a lo que me llega?».

El gemelo digital es el **modelo lógico** de la red: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque lo difícil aquí
no es promediar, sino decidir cuándo un promedio vale, cuándo un sensor miente y qué
se le puede afirmar a la gente con datos incompletos.

## La red que se clona

Tres estaciones en dos zonas de aviso de Tijuana. Los nombres son un ejemplo de esta
extensión, no estaciones reales.

| Parte | Contenido |
|---|---|
| Entidades | zona de aviso → estación → sensor; las estaciones vecinas comparten zona o cercanía |
| Estaciones | «Costa» (red oficial, zona Costa), «Loma» (red oficial, zona Cañón) y «Secundaria» (escolar, zona Cañón) |
| Sensores por estación | cinco: viento (anemómetro), temperatura, humedad, presión y pluviómetro |
| Estado por sensor | valor, instante de la medición, instante en que llegó al gemelo |
| Estado por estación | si está encendida, qué muestras tiene en su ventana, qué avisos se emitieron en su zona |
| Eventos | llega una muestra, una estación se apaga y regresa, llega un lote atrasado, se emite o se retira un aviso |
| Decisiones | ¿emito aviso en esta zona?, ¿puedo creerle a esta estación?, ¿qué sabía yo en ese momento? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original: su escenario, sus casos difíciles, sus datos del
mundo real y su pregunta guía 1. La 5 añade un elemento derivado: qué red pesa más (se
declara en «Supuestos»). En cada una, tu gemelo debe llegar a una decisión **y poder
explicarla**.

### Situación 1 — Santa Ana: nadie la mide

- **Qué pasa.** Es temporada de Santa Ana. En la zona Cañón el viento se triplicó y la
  humedad se desplomó; hay colonias pegadas a la maleza. Si el aviso llega tarde, hay
  fuego y evacuaciones; si se emite sin razón, la gente deja de hacerle caso.
- **Qué datos hay.** Muestras de viento, humedad y temperatura de varias estaciones, el
  instante de cada una y la temporada. Ningún sensor mide «Santa Ana».
- **Qué debe deducir.** Si hay condición Santa Ana en la zona y, de ahí, si hay riesgo
  de incendio. Eso exige encadenar: qué promedios tienen muestras suficientes para
  valer, si el viento sostenido y las ráfagas son de las que se esperan (del orden de
  60 a 100 km/h en ráfaga), si la humedad cayó a menos de 15 %, si la temporada
  corresponde, y de ahí el aviso.
- **Qué debe contestar.** Aviso sí o no para la zona, la cadena completa de razones y qué
  eslabón es el más frágil (el que, si cambia, tumba el aviso).
- **Por qué es lógica.** La condición es una conclusión de varias conclusiones, y la
  explicación es la cadena misma.

### Situación 2 — Promedio de diez minutos con tres muestras

- **Qué pasa.** El enlace de Loma se cayó y volvió. En la ventana de los últimos diez
  minutos del anemómetro solo hay tres muestras. En un caso las tres son bajas; en otro,
  una de las tres es una ráfaga fuerte. El encargado pregunta: «¿tengo viento fuerte o
  no?».
- **Qué datos hay.** Las muestras de la ventana con su instante y el «ahora».
- **Qué debe deducir.** Si el promedio de esa ventana vale como dato, y qué se puede
  afirmar o negar con tan poca evidencia. Lo «obvio» (promediar lo que hay y comparar)
  está mal en uno de los dos casos.
- **Qué debe contestar.** «Sí», «no» o «no lo sé» para cada caso, con las muestras que
  lo sustentan y qué faltaría para poder cambiar la respuesta.
- **Por qué es lógica.** Que no se pueda negar algo no impide afirmarlo, y «no lo sé» es
  una respuesta distinta de «no».

### Situación 3 — Cero fijo: ¿calma o roto?

- **Qué pasa.** El anemómetro de Costa marca cero desde hace rato. En la costa, con
  neblina, la calma es creíble; también lo es un anemómetro atascado por sal o por un
  ave. Mientras tanto, Loma reporta viento y la presión de Costa se mueve. Si está roto
  y nadie lo sabe, Costa seguirá reportando «calma» en plena Santa Ana.
- **Qué datos hay.** Las muestras de todos los sensores de Costa y de sus vecinas.
  Ningún sensor dice «atascado».
- **Qué debe deducir.** Si el cero es calma, es falla, o no se puede saber, cruzando lo
  que dicen los demás sensores de la estación y lo que dicen las vecinas. Lo «obvio»
  (cero es calma, es decir, todo en orden) es el veredicto más peligroso.
- **Qué debe contestar.** Las tres respuestas posibles con su evidencia, y qué pasa con
  el resto de las conclusiones que usaban ese viento (por ejemplo, la situación 1).
- **Por qué es lógica.** Una conclusión sobre un sensor se apoya en lo que dicen los
  demás, y al retirarla caen todas las que dependían de ella.

### Situación 4 — La estación que vuelve con datos viejos

- **Qué pasa.** Secundaria estuvo apagada 40 minutos y regresa mandando todo lo que midió
  en ese lapso, con marcas de tiempo viejas. Durante esos 40 minutos la zona Cañón solo
  tuvo a Loma. Ahora el lote atrasado dice que hubo viento fuerte y humedad baja, y
  Protección Civil pregunta por qué no se avisó. Una de las marcas del lote cae en la
  hora en que cambió el reloj local.
- **Qué datos hay.** Las muestras del lote con su instante de medición y de llegada, los
  avisos emitidos y los eventos de apagado y encendido.
- **Qué debe deducir.** Qué sabía el gemelo en cada momento de esos 40 minutos y qué se
  sabe ahora, qué marcas son de fiar y cuáles son ambiguas, y si ahora corresponde un
  aviso.
- **Qué debe contestar.** Si el aviso de entonces se pudo haber emitido con lo que se
  sabía, si ahora hay que emitir algo, y a quién se le cuenta qué.
- **Por qué es lógica.** Distingue lo que era cierto entonces de lo que se descubrió
  después y exige justificar cada afirmación con lo que se tenía en ese instante.

### Situación 5 — Dos estaciones, dos versiones

- **Qué pasa.** En la zona Cañón, Secundaria (escolar) reporta humedad por debajo de
  15 %; Loma (oficial), a poca distancia, reporta humedad mucho más alta. Los microclimas
  de la región existen, pero también un sensor de humedad que deriva o uno recalentado por
  el sol. Si hay Santa Ana y no se avisa, hay riesgo de incendio; si no la hay y se
  avisa, se movilizan recursos y la gente deja de creer.
- **Qué datos hay.** Las muestras de ambas estaciones, su red y lo que dicen sus demás
  sensores.
- **Qué debe deducir.** Si las dos pueden tener razón, si una de las dos probablemente
  está mal y por qué, y qué aviso corresponde con esa duda.
- **Qué debe contestar.** La decisión para la zona, a quién se le falla si la regla se
  equivoca y por qué se prefiere ese error. Que la estación oficial gane siempre no es
  una respuesta justificada.
- **Por qué es lógica.** Dos fuentes que no se ponen de acuerdo se resuelven declarando
  una vez qué pesa más y por qué, y esa regla debe poder explicarse.

## Por qué no basta un script

Con `if viento_promedio > umbral: alerta()` resuelves una estación con todos sus datos y
sin fallas. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Emito aviso en la zona Cañón? | decisión |
| ¿Por qué sí, o por qué todavía no? | explicación |
| ¿Qué estaciones no merecen confianza ahora? | todas las respuestas |
| ¿Qué tendría que pasar para poder avisar? | la pregunta al revés |
| ¿Qué pasaría si Secundaria hubiera regresado 20 minutos antes? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio: es el programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir una estación y sus muestras en un instante?
2. Cuando dos estaciones se contradicen, ¿dónde queda escrito cuál pesa más?
3. ¿Cómo distingue tu gemelo «no hay viento fuerte» de «no sé si hay viento fuerte»?
4. ¿Qué parte de la explicación le sirve al encargado de avisos y qué parte es ruido?
5. ¿Qué parte de tu simulación en Erlang (ingesta, ventanas de promedios, agregador)
   podría alimentar a este gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la red, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar muestras simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 3 estaciones, 2 zonas de aviso y 5 sensores por estación, contra las
  5 estaciones y 8 sensores del escenario original.
- Los nombres de estaciones y zonas, y que Loma y Secundaria compartan zona, son de esta
  extensión.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas se
  puedan repetir. Tú eliges su unidad.
- Tú decides, y anotas: cuántas muestras bastan para una ventana, cuánto tiempo sin
  variar vuelve sospechoso a un sensor, qué cuenta como vecindad, cuánto retraso invalida
  un lote, a qué hora cambió el reloj, y qué red (oficial o escolar) pesa más y cuándo.
- La temporada de Santa Ana (otoño-invierno), la humedad por debajo de 15 %, las
  ráfagas de 60 a 100 km/h, los diez minutos de la ventana, las tres muestras y los 40
  minutos de apagón vienen del original. Los «20 minutos antes» de la tabla de preguntas
  y el que la estación apagada sea Secundaria son ejemplos de esta extensión.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Presión reducida a nivel del mar para comparar estaciones a distintas altitudes.
- Lluvia intensa y riesgo de deslaves a partir de la cuenta de vuelcos por tiempo.
- Neblina costera, helada y sensación térmica como avisos adicionales.
- Cuánta historia conservar y a qué resolución, y qué pierde cada decisión de poda.

---
*Las cifras son de referencia y vienen del problema original. Verifica la fuente vigente
antes de citarlas en tu entrega.*
