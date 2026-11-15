# #79 — Acuacultura (atún, ostión): gemelo digital con programación lógica

> Extensión del proyecto #79. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la granja: boyas que reportan cada 5 minutos, una noche
con poco oxígeno, una boya que se queda sin señal. Esa simulación responde «¿qué está
pasando?». Quien administra la granja necesita algo más: «¿qué hago, y por qué?». Si
enciende la aireación y no hacía falta, gasta; si no la enciende y sí hacía falta,
pierde meses de engorda.

El gemelo digital es el **modelo lógico** de la granja: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque lo que hay que
resolver aquí no es calcular, sino deducir, justificar y descartar.

## La granja marina que se clona

Una granja frente a Ensenada (atún aleta azul en jaulas flotantes) y en la Bahía de San
Quintín (ostión en líneas de cultivo), reducida a pocas jaulas, pocas líneas y pocas
boyas. Las boyas miden en el mar; las decisiones se toman sobre las jaulas y las líneas.

| Parte | Contenido |
|---|---|
| Entidades | granja → jaula de atún (con lote, biomasa, fecha de ingreso y plan de alimentación) y línea de ostión (con lote y fecha de ingreso); boyas con sensores |
| Estado por boya | oxígeno disuelto (mg/L), temperatura del agua (°C), salinidad, clorofila, corriente; cuándo se limpió el sensor y cuándo fue su último reporte |
| Estado por unidad | qué boya(s) la representan, alimento suministrado contra el plan, si hay aireación encendida |
| Eventos | llega una lectura, una boya deja de reportar, se limpia un sensor, se enciende o apaga la aireación, se alimenta una jaula, se cosecha una línea |
| Decisiones | ¿airear?, ¿alimentar y cuánto?, ¿suspender cosecha y venta?, ¿confiar en este dato? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original (escenario, casos difíciles, preguntas guía y
datos del mundo real); lo que añado yo va marcado como «complemento». En cada una, tu
gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — La noche que se come el oxígeno

- **Qué pasa.** De noche la fotosíntesis se detiene y el oxígeno cae; con agua cálida y
  poco movimiento cae más. El escenario del original trae dos jaulas que llegan a
  3.5 mg/L, dentro de la franja de estrés (~3-5 mg/L). Airear cuesta; llegar tarde
  cuesta peces, y en una jaula hay miles.
- **Qué datos hay.** Lecturas de oxígeno, temperatura y corriente con su minuto, qué
  boya cubre cada jaula y a qué hora de la noche estamos. Ningún sensor mide «se va a
  acabar el oxígeno».
- **Qué debe deducir.** Qué jaulas van hacia la mortalidad aunque todavía no la hayan
  alcanzado, combinando franja de la noche, tendencia, temperatura del agua y movimiento
  del agua. Aquí se encadenan tres o más pasos.
- **Qué debe contestar.** Qué jaulas airear ya, cuáles vigilar y cuáles dejar; por
  cada una, la cadena de razones y qué tendría que cambiar para que la decisión sea otra.
  Y cuántas lecturas anormales bastan para gastar (pregunta guía 1 del original).
- **Por qué es lógica.** Lo obvio es atender la jaula con la lectura más baja. Aquí esa
  intuición es sospechosa: una jaula con mejor lectura puede estar en peor situación que
  otra con 3.5. El riesgo nace de que varias cosas coincidan, no de un número bajo.

### Situación 2 — El sensor que se ensució sin avisar

- **Qué pasa.** El mar corroe y ensucia: la bioincrustación hace que un sensor de
  oxígeno derive sin fallar. Sigue reportando a tiempo, dentro de rango, y cada vez
  miente un poco más (caso difícil del original).
- **Qué datos hay.** Lecturas con su minuto, el rango físico de cada variable, el
  historial de limpiezas del sensor y lo que reportan las otras boyas de la misma agua.
- **Qué debe deducir.** Si la lectura es creíble, dudosa o contradicha por el resto, sin
  que la regla de rango la delate, y qué decisiones dependen de ella.
- **Qué debe contestar.** Tres respuestas distintas: «sí es creíble», «no» y «no lo sé».
  Qué decisiones quedan en pausa por esa duda y qué evidencia (una limpieza, una
  comparación) permitiría volver a confiar.
- **Por qué es lógica.** «Dato válido en forma» no es «dato cierto», y «no se cumple» no
  es «no tengo cómo saberlo». La credibilidad se deduce de relaciones entre datos. Si el
  gemelo se equivoca, se airea sin motivo o se deja morir una jaula.

### Situación 3 — La boya que no habla por la jaula

- **Qué pasa.** Una boya se queda sin señal toda la noche (escenario del original). La
  jaula que dependía de ella queda a ciegas, y la boya más cercana quizá no mide la misma
  agua que la jaula (caso difícil del original).
- **Qué datos hay.** Qué boya cubre qué unidad y qué tan bien, las corrientes, las
  lecturas de las boyas que sí reportan y el minuto del último reporte de la callada.
  (El complemento: que el silencio puede ser falla de energía, de señal o del equipo.)
- **Qué debe deducir.** El estado probable de la jaula sin boya confiable a partir de
  las que sí reportan, sabiendo cuáles de ellas sirven y cuáles no aunque estén cerca.
- **Qué debe contestar.** La inferencia, marcada como inferencia y no como lectura, con
  las boyas que la sustentan; «no lo sé» si ninguna representa a la jaula. Silencio no es
  buena noticia.
- **Por qué es lógica.** Es razonar sobre relaciones entre entidades (qué mide a qué), no
  sobre un valor. La respuesta honesta a veces es «no sé», y esa también es una decisión.

### Situación 4 — ¿Come poco o se mide mal?

- **Qué pasa.** Una jaula comió menos de lo planeado. Si es apetito (temperatura fuera de
  16-20 °C, poco oxígeno), recortar el alimento ahorra: la conversión alimenticia es tan
  alta que cada kilo de más pesa en el costo. Si es la medición, recortar frena la
  engorda. Quien cuida el costo y quien cuida los peces tienen razón (caso difícil del
  original).
- **Qué datos hay.** El plan de alimentación, lo suministrado, la biomasa, la
  temperatura y el oxígeno de la boya que la cubre, y cuánta confianza merecen esos
  datos según las situaciones 2 y 3.
- **Qué debe deducir.** Si hay base para atribuir la baja de consumo al apetito, a la
  medición o a ninguna de las dos, y qué ración queda justificada con lo que se sabe.
- **Qué debe contestar.** Alimentar completo, reducido o diferir, a quién se le falla con
  esa decisión y qué dato permitiría decidir mejor. Lo intuitivo («come menos, dale
  menos») es sospechoso; el veredicto correcto depende de la causa que se pueda sustentar.
- **Por qué es lógica.** Hay un dilema legítimo y la regla debe declarar la prioridad una
  vez y justificarla en cada caso. La explicación debe nombrar qué parte se sacrifica.

### Situación 5 — Marea roja: la línea que parece sana

- **Qué pasa.** La clorofila sube en una boya. La marea roja (algas tóxicas) obliga a
  suspender la cosecha y la venta del ostión, y un ostión tarda ~12-18 meses en llegar a
  talla comercial. Ningún sensor mide toxina, y la clorofila también sube por otras
  razones. Un cliente espera su pedido.
- **Qué datos hay.** Clorofila y corrientes por boya, qué boya cubre cada línea, hacia
  dónde se mueve el agua, la fecha de ingreso de cada línea y los lotes ya cosechados o
  en camino. (El complemento: el sentido de la corriente y el aviso al comprador.)
- **Qué debe deducir.** Qué líneas corren riesgo aunque su propia boya no marque nada,
  cuáles están en talla de cosecha y qué lotes ya salieron y deben rastrearse. Es una
  cadena: clorofila, agua que se mueve, línea alcanzada, cosecha en talla, lote vendido.
- **Qué debe contestar.** Suspender o permitir por línea, con la razón y con lo que se
  sabe frente a lo que solo se sospecha; y la hipótesis «¿qué pasaría si la corriente
  cambia de sentido esta noche?».
- **Por qué es lógica.** Es un dilema: el ostionero con el pedido listo y quien compra
  tienen razón. «Su boya está tranquila» no prueba que la línea esté a salvo, y «la
  clorofila subió» no prueba la marea roja.

## Por qué no basta un script

Con `if oxigeno < 4: encender_aireacion()` resuelves una jaula con datos perfectos. Tu
gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué hago con la jaula 2 esta noche? | decisión |
| ¿Por qué? | explicación |
| ¿Cuáles jaulas se airean ahora? | todas las respuestas |
| ¿Qué falta para poder alimentar la jaula 3 completa? | la pregunta al revés |
| ¿Qué pasaría si la boya 2 sigue callada hasta el amanecer? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para saber qué boya habla por qué jaula o línea?
2. ¿Dónde queda escrito qué vuelve dudosa una lectura que parece normal?
3. ¿Cómo distingue tu gemelo «el oxígeno está bien» de «no sé cómo está el oxígeno»?
4. ¿Qué parte de la explicación le sirve a quien decide gastar en aireación y qué parte
   es ruido?
5. ¿Qué proceso de tu simulación en Erlang (el de cada jaula, la alarma, la aireación de
   respaldo) podría alimentar a este gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la granja, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar lecturas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 3 jaulas de atún, 3 líneas de ostión y 3 boyas, contra las 8 jaulas,
  20 líneas y 6 boyas del escenario original. Los identificadores («jaula 2», «boya 2»)
  son del ejercicio.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir.
- Tú defines el mapa (qué boya cubre qué unidad, hacia dónde corre el agua) y qué horas
  son «noche».
- El original no da estos valores y no los invento: cuántas lecturas anormales justifican
  airear, cuánta deriva vuelve dudoso a un sensor, cuánto silencio vuelve sospechosa a una
  boya, qué clorofila preocupa, cuánta ración se recorta y qué pesa más, costo o engorda.
  Son decisión tuya; anótalos y justifícalos.
- Los cargos y pedidos de los ejemplos son ilustrativos.

## Extensiones posibles

Para quien quiera ir más lejos. No vienen del original: investiga y cita fuentes
antes de fijar cifras.

- Tormenta o mar de fondo: mover o ajustar las jaulas, y qué sale primero.
- Energía y señal de las boyas: qué mantener vivo cuando la batería no alcanza.
- Fecha de embarque del atún: engorda contra fecha comprometida.

---
*Las cifras (~3-5 mg/L, 16-20 °C, 3.5 mg/L, ~12-18 meses, lecturas cada 5 min) vienen del
problema original, que las da como orden de magnitud. Verifica la fuente vigente antes de
citarlas en tu entrega. Lo demás son supuestos de la escala reducida.*
