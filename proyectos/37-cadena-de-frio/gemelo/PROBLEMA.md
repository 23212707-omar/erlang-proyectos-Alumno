# #37 — Cadena de frío: gemelo digital con programación lógica

> Extensión del proyecto #37. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste los camiones y las cámaras: sondas que reportan cada pocos
minutos, un compresor que falla, un camión que pierde la señal y reporta todo al volver.
Esa simulación responde «¿qué temperatura hubo?». El responsable de calidad necesita algo
más: «¿qué hago con este lote, y puedo demostrarlo?».

El gemelo digital es el **modelo lógico** de la operación: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque lo que hay que
resolver aquí no es calcular, sino deducir, justificar y descartar.

## La cadena de frío que se clona

Una distribuidora de Tijuana (ficticia, ver «Supuestos») que lleva vacunas, medicinas y
mariscos a clínicas, hospitales y mercados de Baja California, con 3 camiones y 2 cámaras
de bodega. Es una simulación planteada por esta extensión sobre el problema original.

| Parte | Contenido |
|---|---|
| Entidades | unidad (camión o cámara) → sondas; lote de producto con su rango de temperatura; envío con destinatario y fecha límite |
| Estado por unidad | temperatura de cada sonda, punto de ajuste del compresor, puerta abierta o cerrada, señal presente o perdida |
| Estado por sonda | su verificación más reciente y el error que se le encontró |
| Estado por lote | por qué unidades pasó y en qué horas, tiempo acumulado fuera de rango |
| Eventos | llega una lectura (medida en un instante, recibida en otro), se pierde o vuelve la señal, se abre o cierra la puerta, falla el compresor, se verifica una sonda, un cliente pide el lote |
| Decisiones | ¿puerta o falla?, ¿cuánto tiempo acumuló el lote?, ¿confío en esta sonda?, ¿qué destino tiene el lote? |

## Situaciones que tu gemelo debe razonar

Las cinco parten del problema original (datos del mundo real, escenario a simular, casos
difíciles y «el problema»); la 1, la 4 y la 5 añaden contexto derivado, que se señala en «Qué
pasa». En cada una, tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — ¿Descarga o compresor?

- **Qué pasa.** El camión 2 descarga en una clínica y la temperatura de la caja sube. El
  original pide distinguir una apertura de puertas de una falla del equipo. Si se toma por
  apertura algo que es falla, se pierde el aviso a tiempo; si se toma por falla una
  descarga normal, se cancela una entrega y se mueve producto sin necesidad. El registro de
  la puerta lo captura el chofer, y a veces se olvida (contexto derivado).
- **Qué datos hay.** Lecturas de la caja con su hora, el estado de la puerta cuando alguien
  lo anotó, lo que reporta el compresor y cuándo se cerró la puerta. Ninguna sonda mide
  «falla del compresor».
- **Qué debe deducir.** Si lo observado es una apertura que se recupera, una falla en curso
  o las dos encimadas, y qué debería verse después de cerrar la puerta para cada caso. Lo
  intuitivo («hay una descarga anotada, es la puerta») es sospechoso: una falla puede
  empezar en plena descarga y quedar escondida detrás de ella.
- **Qué debe contestar.** El diagnóstico (apertura, falla o «no se sabe»), si avisa o no, y
  qué observación o cuánta espera lo aclararía, con la evidencia que lo sustenta.
- **Por qué es lógica.** La falla no está en ningún dato; sale de comparar lo que se vio
  contra lo que cada explicación predice, y de cuál queda en pie.

### Situación 2 — Dos horas que se reparten

- **Qué pasa.** Un lote de mariscos viaja en el camión 1, espera en la cámara B y sigue en
  el camión 3. En cada tramo hubo una subida; la regla general del original es no pasar
  más de 2 horas acumuladas entre 4 °C y 60 °C. Si se vende, alguien puede enfermar; si se
  descarta de más, la distribuidora pierde el lote y, con él, a su cliente.
- **Qué datos hay.** El recorrido del lote (en qué unidad estuvo y de qué hora a qué hora)
  y las lecturas de cada unidad con su hora. Ningún dato dice «el lote acumula tanto».
- **Qué debe deducir.** En qué momentos estuvo el **lote** en la zona de peligro (no la
  unidad entera), cuánto suma entre todas las excursiones, qué tramo gastó más margen y si
  el lote sigue siendo utilizable. Encadena el recorrido, las excursiones, el acumulado y
  el veredicto. Lo intuitivo es mirar la peor excursión o la temperatura de hoy;
  es sospechoso porque el límite es acumulado y una excursión de la unidad puede ser
  anterior a que el lote subiera.
- **Qué debe contestar.** El tiempo acumulado, el veredicto, el tramo responsable y
  cuánto margen le quedaba al lote antes de cada tramo.
- **Por qué es lógica.** La respuesta sale de cruzar dos historias (la del lote y la de la
  unidad) y de sumar con ellas; no de un valor ni de un umbral.

### Situación 3 — Tres horas sin señal

- **Qué pasa.** El camión 3 cruza una zona rural sin señal durante 3 horas y al volver
  reporta lo que guardó (el original lo plantea y pide reconstruir el historial con
  lecturas atrasadas). El hospital que espera las vacunas pregunta si hubo excursión. Una
  alerta falsa lo deja sin lote; liberarlo sin evidencia expone a la distribuidora, porque
  el registro de temperaturas es evidencia legal.
- **Qué datos hay.** Cada lectura con el instante en que se midió y el instante en que se
  recibió, el intervalo esperado entre lecturas y los eventos de pérdida y recuperación de
  señal.
- **Qué debe deducir.** Qué periodos están cubiertos por lecturas y cuáles no, y para los
  no cubiertos, qué se puede descartar y qué no. La respuesta cambia al llegar lecturas
  atrasadas: lo que era «no sé» puede volverse «no hubo».
- **Qué debe contestar.** Tres respuestas distintas: «hubo excursión», «se demuestra que no
  hubo» y «no se sabe», con los huecos señalados y qué tendría que llegar para cerrar la
  duda. Lo intuitivo (lecturas buenas antes y después del hueco) es sospechoso: no
  demuestran lo que pasó entre una y otra.
- **Por qué es lógica.** «No se cumple» y «no tengo cómo saberlo» no son lo mismo, y la
  segunda puede resolverse después.

### Situación 4 — La sonda que miente dos grados

- **Qué pasa.** La caja del camión 1 lleva dos sondas; en la última verificación, una
  resultó con 2 °C de error (caso difícil del original) sin que se anotara hacia qué lado.
  El compresor se gobierna con una de ellas. Si gobierna la mala, el equipo cree estar en
  el punto de ajuste y la caja está más caliente o más fría. Las dos sondas y su rol son
  contexto derivado.
- **Qué datos hay.** Lecturas de las dos sondas con su hora, el punto de ajuste, cuál
  sonda gobierna el compresor y la fecha y resultado de la verificación de cada una.
- **Qué debe deducir.** Cuál sonda es sospechosa (ninguna dice «estoy descalibrada»; sale
  de compararlas y de su verificación), entre qué valores pudo estar la temperatura real y
  si alguna lectura basta para afirmar que el producto estuvo dentro de rango. Lo intuitivo
  es restar 2 °C a la lectura y seguir; es sospechoso porque no se sabe en qué sentido va
  el error.
- **Qué debe contestar.** Para cada lectura relevante: dentro, fuera o «no se puede
  afirmar», con el margen que se usó, qué sonda se prefiere y qué lotes quedan afectados.
- **Por qué es lógica.** El sistema (punto de ajuste, compresor) y la realidad (la sonda
  buena) se contradicen; solo se resuelve razonando sobre cuál fuente es creíble.

### Situación 5 — El lote que el hospital necesita

- **Qué pasa.** Un lote de vacunas llegó con evidencia incompleta (un hueco como el de la
  situación 3, con lecturas buenas alrededor). El hospital tiene una campaña mañana y no
  tiene otro lote; calidad dice que sin evidencia no se libera. Ambos tienen razón: si se
  retiene, la gente se queda sin vacunar; si se libera y estaba dañado, se aplica un
  producto ineficaz y la distribuidora responde ante la normatividad (el original pide
  decidir si un lote sigue siendo utilizable; el dilema y los destinos son contexto
  derivado).
- **Qué datos hay.** El producto y su rango, el historial reconstruido del lote, quién lo
  pide y para cuándo, las existencias alternas y la evidencia que aún puede llegar.
- **Qué debe deducir.** Qué destinos son elegibles (liberar, liberar con condición,
  retener en espera de evidencia o rechazar) según el producto y lo que se sabe de él, y a
  quién se le falla con cada uno.
- **Qué debe contestar.** El destino con su justificación, a quién se le falla y por qué,
  qué evidencia cambiaría el veredicto y, si hay más de un destino válido, todos.
- **Por qué es lógica.** Una decisión que perjudica a alguien debe quedar escrita como
  política y poder justificarse, no resolverse a criterio en cada caso.

## Por qué no basta un script

Con `if temperatura > 8: alerta()` resuelves una sonda sin huecos, sin error y sin cambio
de unidad. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué destino tiene el lote de vacunas del camión 3? | decisión |
| ¿Por qué? | explicación |
| ¿Qué lotes están hoy retenidos o en riesgo? | todas las respuestas |
| ¿Qué tendría que llegar para poder liberar el lote? | la pregunta al revés |
| ¿Qué pasaría si la sonda 2 resulta estar bien? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué es una excursión y cuándo se vuelve un lote perdido? (del original)
2. ¿Cómo demuestras que no hubo excursión durante el hueco de datos? (del original)
3. ¿Cómo distingue tu gemelo «no hubo excursión» de «no sé si la hubo»?
4. ¿Qué parte de la explicación le sirve al responsable de calidad y cuál es ruido?
5. ¿Qué parte de tu simulación en Erlang (el gen_statem de la cadena, la bitácora de
   excursiones, el tiempo límite de «sin dato») podría alimentar a este gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la operación, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar lecturas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 3 camiones y 2 cámaras, contra los 12 camiones y 4 cámaras del
  escenario original.
- La distribuidora, el hospital, el chofer que anota la puerta, las dos sondas por caja,
  los lotes, los tramos y los números de unidad de los ejemplos los plantea esta
  extensión; no vienen del original. Cada situación puede usar su propio conjunto de datos.
- Unidad del tiempo: el minuto. El «ahora» es un hecho del modelo, no el reloj del sistema,
  para que las respuestas se puedan repetir.
- Tú defines: cuánto dura una apertura normal antes de ser sospechosa; qué tolerancia de
  tiempo fuera de rango admite cada producto salvo la regla de 2 horas del original; cuántas
  lecturas faltantes hacen un hueco; qué producto admite «liberar con condición»; a quién
  se favorece en un dilema y por qué. El original no da esas cifras.

## Extensiones posibles

Estas situaciones no vienen del problema original: investiga y cita tus fuentes antes de
fijar cifras.

- Carga mixta con rangos incompatibles en la misma caja.
- Costo del producto contra costo de la retención o del rechazo.
- Cadena de custodia: quién tuvo el lote y quién firmó cada cambio de unidad.
- Producto congelado que se descongela y se vuelve a congelar.
- Elegir la ruta o la cámara de paso que minimiza el riesgo.

---
*Las cifras de dominio (rangos de 2-8 °C, -70 °C y -18 °C, zona de peligro de 4 a 60 °C
con 2 horas acumuladas, lecturas cada 2 min, 3 horas sin señal, 2 °C de error, 12 camiones y
4 cámaras) son de referencia y vienen del problema original. Lo demás es de esta
extensión. Verifica la fuente vigente antes de citarlas en tu entrega.*
