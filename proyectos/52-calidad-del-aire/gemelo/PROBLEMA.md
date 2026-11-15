# #52 — Calidad del aire: gemelo digital con programación lógica

> Extensión del proyecto #52. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang montaste la red: un proceso por sensor, un calculador de promedios,
un estado de alerta, lecturas absurdas que se descartan y se cuentan. Esa simulación
responde «¿cuánto vale el índice?». Quien cuida la salud de una ciudad necesita algo más:
«¿puedo creerle a este dato, hay de verdad un episodio, y qué le recomiendo a quién?».

El gemelo digital es el **modelo lógico** de la red: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque aquí no se
promedia: se deduce, se justifica y se sabe decir «no lo sé».

## La red que se clona

Una ciudad fronteriza como Tijuana, reducida a 4 zonas (norte, este, oeste y sur), 8
sensores de bajo costo y una estación oficial de referencia; la zona sur no tiene sensor
propio. Dos escuelas (en la zona este y en la sur) y una clínica (en la sur) son los
puntos a proteger. Las zonas, los sensores y los puntos son ejemplos de esta extensión;
la red real es la del original (25 sensores, una lectura cada 2 minutos).

| Parte | Contenido |
|---|---|
| Entidades | ciudad → zona → sensor; una estación de referencia; puntos a proteger (escuela, clínica) dentro de una zona |
| Estado por sensor | PM2.5 (µg/m³), humedad relativa (%), instante de cada lectura, tiempo en servicio, qué sensores y zonas tiene cerca |
| Estado por zona | sus sensores, si tiene o no sensor propio, y qué zonas son vecinas |
| Referencias | OMS (2021): 15 µg/m³ en 24 h y 5 anual; NOM-025-SSA1-2021: 33 µg/m³ en 24 h y 10 anual |
| Categorías (EPA 2024, µg/m³) | Bueno 0-9.0 · Moderado 9.1-35.4 · Dañino para grupos sensibles 35.5-55.4 · Dañino 55.5-125.4 · Muy dañino 125.5-225.4 |
| Eventos | llega una lectura, un sensor se queda pegado o sin reportar, sube la humedad, arranca un incendio |
| Decisiones | ¿confío en esta lectura?, ¿hay un episodio real?, ¿qué nivel tiene la zona?, ¿qué recomiendo y a quién? |

## Situaciones que tu gemelo debe razonar

Cuatro de las cinco salen del problema original. La 5 es derivada: toma del original
que se interpola entre sensores y las categorías, y del foco del eje, que el nivel de
contaminación lleva una recomendación; las escuelas y la clínica son complementos. En
cada una, tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — El sensor pegado y el que miente en silencio

- **Qué pasa.** El sensor 7 marca 999 µg/m³ lectura tras lectura, mientras sus vecinos
  están en niveles bajos. El sensor 3 repite siempre el mismo valor, perfectamente
  creíble. Otro manda un valor negativo. Si una alerta sale por el 999, se suspende el
  recreo de una escuela por nada y la gente deja de creer en los avisos. Si nadie nota
  que el 3 está pegado, durante un incendio seguirá diciendo «todo bien».
- **Qué datos hay.** Lecturas con su instante, el rango físico de cada variable, qué
  sensores son vecinos y cuánto tiempo llevan en servicio. Ningún dato dice «este
  sensor está pegado».
- **Qué debe deducir.** Qué lecturas son válidas, imposibles o viejas; qué sensores
  están pegados, en qué momento empezó y si hay base para afirmarlo cuando también sus
  vecinos casi no cambian. Lo intuitivo es que el 999 es el sensor peligroso; es
  sospechoso porque se descarta con solo verlo, y lo que engaña es el valor creíble que
  no se mueve.
- **Qué debe contestar.** Tres respuestas: «sí», «no» y «no lo sé» para cada sensor;
  cuáles lecturas se descartan y cuántas; y qué sensor sale de los promedios y de las
  alertas, por qué y desde cuándo. Nunca avisar por una lectura imposible.
- **Por qué es lógica.** «Está pegado» no se mide: se deduce de que algo no cambia
  cuando todo a su alrededor sí, y «no cambia pero nada cambia» es otro caso.

### Situación 2 — Un incendio que el índice de 24 horas no ve

- **Qué pasa.** Un incendio cercano dispara el PM2.5 de la zona este de 10 a 150 µg/m³
  en una hora; un humo puede subir diez veces en 20 minutos. El promedio de 24 h sigue
  bajo porque la mañana fue limpia, y la escuela de la zona tiene a los niños en el
  patio. Dos sensores de la zona suben juntos. Un tercero, de otra zona, sube solo. El
  sensor 8 está en el extremo de la ciudad, sube y no tiene vecinos cerca. Si se avisa
  tarde, niños con asma respiran humo; si se avisa en falso, se cierran clases y se
  pierde la confianza.
- **Qué datos hay.** Lecturas válidas con su instante, qué sensores son vecinos y las
  categorías de la EPA. Ningún dato dice «hay un episodio».
- **Qué debe deducir.** Si hay un episodio real, a partir de cuántos sensores coinciden,
  qué tan rápido suben y si son sensores de confianza; cuáles zonas alcanza; y qué
  promedio sirve para un aviso rápido, que no es el de 24 h. Lo intuitivo es obedecer el
  índice de 24 h, que dice «Bueno»; es sospechoso porque promedia una mañana limpia con
  una tarde de humo y llega tarde.
- **Qué debe contestar.** Si se avisa ya o se espera confirmación, con los sensores que
  lo sustentan y la categoría que corresponde; qué le faltaría al sensor 8 para
  confirmarse; y a quién se le falla con cada decisión, porque las dos partes tienen
  razón. Un sensor aislado que sube es «no puedo confirmarlo», no «no hay episodio».
- **Por qué es lógica.** «Real» se construye con coincidencia, tendencia, vecindad y
  confianza a la vez, y la prioridad entre avisar rápido y avisar seguro se declara
  una vez.

### Situación 3 — Niebla que parece humo, humo que parece niebla

- **Qué pasa.** Amanece con humedad muy alta en la zona oeste y tres sensores baratos
  suben. Estos sensores se sobrestiman con la humedad y se degradan con el tiempo, así
  que sus lecturas necesitan corrección. En otra mañana la humedad también es alta, pero
  hay humo de una quema, y la corrección que limpia la niebla también esconde el humo.
  Corregir de más deja sin aviso a quien respira humo; no corregir da falsas alarmas
  cada madrugada.
- **Qué datos hay.** PM2.5 y humedad de cada sensor con su instante, la estación de
  referencia, el tiempo en servicio y qué sensores son vecinos. Ningún dato dice
  «esto es niebla» ni «esto es humo».
- **Qué debe deducir.** En cadena: la humedad alta vuelve dudosa la lectura; una lectura
  dudosa debe contrastarse con la referencia y con sensores de aire más seco; si estos
  también suben, el episodio es real aunque el valor corregido sea menor; y entonces la
  categoría de la zona sale del valor corregido, no del crudo. Lo intuitivo es que mucha
  humedad significa dato falso; es sospechoso porque la humedad y el humo pueden
  coincidir, y esa suposición apaga justo el aviso que importa.
- **Qué debe contestar.** Por zona: si es artefacto de humedad, episodio real o «no lo
  sé»; el nivel con la corrección, marcado como estimado; y la evidencia que lo apoya,
  separando lo medido de lo corregido.
- **Por qué es lógica.** Corregir sin ocultar es un equilibrio entre evidencias
  independientes, y cada paso de la cadena debe poder mostrarse.

### Situación 4 — Veinticuatro horas con huecos

- **Qué pasa.** Al final del día, quien cuida la calidad del aire debe informar si la
  zona este cumplió las normas de 24 horas, la de la OMS y la mexicana. Un sensor estuvo
  caído varias horas de la tarde, justo cuando el vecino marcó humo; otro tuvo lecturas
  descartadas por pegado. Si se dice «cumplimos» sin base, la gente queda sin protección;
  si se dice «excedimos» sin base, se pierde credibilidad ante la autoridad.
- **Qué datos hay.** Las lecturas válidas de cada sensor con su instante, cuáles se
  descartaron y por qué, y las dos referencias de 24 h. Ningún dato dice «cumple».
- **Qué debe deducir.** Si el promedio de 24 h puede considerarse válido con las horas
  que hay; qué horas faltan; y, con lo que sí se sabe, qué se puede afirmar de cada
  norma. Lo intuitivo es que con datos incompletos nunca se puede decir nada; es
  sospechoso porque lo que sí hay puede bastar para un lado de la respuesta y no para
  el otro.
- **Qué debe contestar.** Para cada norma: «cumple», «excede» o «no lo sé», con las
  horas con datos y las que faltan; que una zona puede cumplir una norma y exceder la
  otra, y las dos respuestas son ciertas; y qué tendrían que haber medido las horas
  faltantes para cambiar el veredicto.
- **Por qué es lógica.** Un dato faltante no es un cero ni un «bueno»: el modelo
  distingue lo que se sabe, lo que no se sabe y lo que se puede garantizar sin saberlo.

### Situación 5 — Una colonia sin sensor y una escuela con asmáticos

- **Qué pasa.** La zona sur no tiene sensor propio. Su vecina del norte está en
  «Moderado» y la del este, en «Dañino para grupos sensibles». En la zona hay una escuela
  con niños, algunos con asma, y una clínica con pacientes del corazón. Avisar a toda la
  zona con restricciones agota la paciencia de todos; avisar solo a quienes están en
  riesgo es proporcional, pero deja sin aviso a quien aún no sabe que lo está.
- **Qué datos hay.** Los niveles de las zonas vecinas con sus promedios, qué zonas son
  vecinas, las categorías de la EPA y qué puntos a proteger hay en cada zona. Ningún
  dato mide el aire de la zona sur.
- **Qué debe deducir.** El nivel probable de la zona sin sensor a partir de sus vecinas,
  marcado como inferencia y con qué tan cerca está de cambiar de categoría; y la
  recomendación que corresponde a cada audiencia (población general, grupos sensibles,
  escuela, clínica) según el promedio vigente y no la lectura de un instante. Lo
  intuitivo es que a igual nivel toca igual recomendación para todos; es sospechoso
  porque la misma categoría exige cosas distintas a quien tiene asma o del corazón.
- **Qué debe contestar.** El nivel inferido con las zonas que lo sustentan; qué se
  recomienda a cada audiencia y por qué; y si la inferencia cae a ambos lados de una
  frontera de categoría, la respuesta honesta y a quién se le falla con cada elección.
- **Por qué es lógica.** Es razonar sobre relaciones entre zonas y sobre quién está en
  riesgo, no sobre un número, y la inferencia nunca se presenta como lectura.

## Por qué no basta un script

Con `if pm25 > 35.4: alertar()` resuelves una lectura con datos perfectos. Tu gemelo debe
contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué recomiendo en la zona este? | decisión |
| ¿Por qué? | explicación |
| ¿Qué zonas están hoy en «Dañino» o peor? | todas las respuestas |
| ¿Qué tendría que cambiar para no avisar en la zona oeste? | la pregunta al revés |
| ¿Qué pasaría si se cae el sensor 5 en pleno humo? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir un sensor y su zona en un instante?
2. ¿Cuántos sensores deben coincidir para considerar real un episodio, y dónde queda
   escrito?
3. ¿Cuánto tiempo de datos requiere cada promedio para ser válido?
4. ¿Cómo distingue tu gemelo «no hay episodio» de «no sé si hay episodio»?
5. ¿Qué parte de tu simulación en Erlang (las lecturas descartadas y contadas, los
   sensores que no reportan) podría alimentar a este gemelo?

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

- Escala reducida: 4 zonas (una sin sensor) y 8 sensores contra los 25 del escenario
  original. Los nombres, números de sensor, las escuelas y la clínica son ejemplos de
  esta extensión.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir.
- La humedad de cada sensor es un dato que añade esta extensión: el original dice que
  la humedad sobrestima, pero no da cuánto ni a partir de cuándo.
- Defines tú, con su fuente: el valor máximo posible de una lectura, cuánto tiempo sin
  cambio vuelve «pegado» a un sensor, cuántos sensores deben coincidir, la humedad que
  vuelve dudosa una lectura y su corrección, cuántas horas validan un promedio de 24 h,
  qué ventana de 1 a 12 h usas para el aviso rápido y qué es «vecino».
- El original no da categorías por encima de 225.4 µg/m³: decide cómo tratar ese caso.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Hacia dónde viaja el humo según el viento y qué zonas alcanzará después.
- Cuándo se levanta un aviso y se evita que parpadee entre dos categorías.
- Calibración periódica de cada sensor contra la estación de referencia.
- Promedio anual de una zona contra los límites anuales de la OMS y la norma mexicana.
- Polvo, quemas o episodios de Santa Ana como otras fuentes con firmas distintas.

---
*Las cifras son de referencia y vienen del problema original. Verifica la fuente vigente
antes de citarlas en tu entrega.*
