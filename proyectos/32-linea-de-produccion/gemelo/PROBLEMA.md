# #32 — Línea de producción: gemelo digital con programación lógica

> Extensión del proyecto #32. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la línea: una estación por proceso (esperando,
procesando, bloqueada, en falla), buffers con cola acotada entre ellas y una prueba de
caos en la que una estación muere y las anteriores se frenan por contrapresión. Esa
simulación responde «¿qué está pasando en la línea?». El jefe de producción necesita algo
más: «¿qué estación nos limita, hasta dónde llega este paro, a quién atiendo primero, y
por qué?».

El gemelo digital es el **modelo lógico** de la línea: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque lo que hay que
resolver aquí no es calcular una cifra de producción, sino seguir causas a lo largo de una
cadena de estaciones, justificar cada conclusión y saber decir «no lo sé».

## La línea que se clona

Una línea de manufactura de una maquiladora de Tijuana: 8 estaciones en serie, con un
buffer entre cada par. El tiempo se cuenta en segundos. Cuatro de las cinco situaciones
vienen del problema original; la tercera la plantea esta extensión.

| Parte | Contenido |
|---|---|
| Entidades | estación, buffer entre dos estaciones, pieza, modelo, técnico de mantenimiento |
| Estado por estación | su lugar en la línea, ciclo nominal, modelo vigente, estado reportado (esperando, procesando, bloqueada, en falla), pieza en mano, historia de entradas y salidas |
| Estado por buffer | capacidad (5 piezas) y nivel, que puede ser dudoso |
| Estado de la planta | turno y demanda, modelo en curso y desde cuándo, dónde está el técnico |
| Eventos | entra o sale una pieza, una estación para o reanuda, cambia el modelo, la calidad rechaza una pieza, llega el técnico, se hace un conteo físico |
| Decisiones | ¿qué estación limita ahora?, ¿hasta dónde llega un paro?, ¿a cuál paro se atiende primero?, ¿dónde está esta pieza?, ¿es normal este tiempo? |

## Situaciones que tu gemelo debe razonar

Cuatro parten del problema original (cuello de botella que se mueve, paro que se propaga,
reanudar sin perder ni duplicar, cambio de modelo con variación de tiempos); la 3 es
derivada: el original nombra la falla de máquina y la calidad como causas de paro pero no
dice quién las atiende. En cada una, tu gemelo debe llegar a una decisión **y poder
explicarla**.

### Situación 1 — El cuello de botella que se mudó

- **Qué pasa.** En la línea manda la estación más lenta. Con 7.5 h netas de turno y 900
  unidades por turno, el takt es de 30 s; si una estación tarda 40 s, esa es la capacidad
  real, no los 30. Pero el cuello no es fijo: los ciclos varían ±10 %, un cambio de modelo
  alarga una estación y un paro cambia quién espera a quién. Si el jefe de producción
  refuerza la estación equivocada, gasta horas extra y la línea sigue sin llegar a 900.
- **Qué datos hay.** Ciclo nominal y modelo de cada estación, estado reportado, niveles de
  buffer, y entradas y salidas de piezas con su instante. Ningún dato dice «cuello».
- **Qué debe deducir.** Qué estación limita hoy, separando la que tarda de la que solo
  espera (bloqueada o sin piezas), qué estaciones están a poco de relevarla y si la línea
  alcanza el takt con esa limitante.
- **Qué debe contestar.** La estación limitante con su evidencia, las que le siguen de
  cerca, y qué tendría que cambiar para que otra pase a limitar. Lo intuitivo es señalar la
  de ciclo más largo en su ficha o la que más se ve detenida; ambas son sospechosas, porque
  una estación que espera también se ve detenida.
- **Por qué es lógica.** «Limita» no es propiedad de una estación sino de su relación con
  las que la rodean, y se pregunta en los dos sentidos.

### Situación 2 — Tres minutos en la estación 4

- **Qué pasa.** La estación 4 falla durante 3 minutos. Hacia atrás, su buffer de entrada
  se llena y las estaciones anteriores se bloquean una tras otra; hacia adelante, el buffer
  de salida se vacía y las siguientes quedan sin piezas. Los buffers de 5 piezas absorben
  parte del golpe. Un paro de 5 minutos en el cuello pierde 5 minutos de toda la línea;
  el mismo paro en otra estación puede no costar nada a la salida. Con ello, el supervisor
  decide si llama al técnico ya o primero reacomoda el material.
- **Qué datos hay.** Ciclo y estado de cada estación, capacidad y nivel de cada buffer,
  el instante de la falla y los 3 minutos del escenario.
- **Qué debe deducir.** Qué estaciones llegan a bloquearse y cuáles a quedarse sin piezas,
  en qué orden y en qué instante, y si el efecto alcanza la salida de la línea. Cada paso
  depende del anterior: falla, buffer que se llena, estación bloqueada, la de atrás, y por
  el otro lado, buffer que se vacía, estación sin piezas, la de adelante.
- **Qué debe contestar.** La cascada por estación con su razón, si la salida se detiene o
  solo baja, y la pregunta al revés: qué duración de paro llegaría a la estación 1 y qué
  buffer habría que agrandar. Lo intuitivo es que el paro más largo es el más caro y que la
  estación detenida causa todo lo que se ve detenido; ambas son sospechosas.
- **Por qué es lógica.** Cada efecto es consecuencia de otro a lo largo de la red, y se
  puede recorrer hacia atrás, hacia adelante o desde el efecto hasta la causa con los
  mismos hechos.

### Situación 3 — Un técnico, dos estaciones detenidas

- **Qué pasa.** Con la 4 en falla de máquina, la 6 se detiene por calidad: salió una pieza
  fuera de especificación y no se sabe desde cuándo. Hay un solo técnico y atiende un paro
  a la vez. El jefe de producción pide la 4: es el cuello y cada minuto cuesta a toda la
  línea. El de calidad pide la 6: cada pieza que pasa puede estar mal y los defectos se
  descubren tarde. Los dos tienen razón y alguien se queda esperando.
- **Qué datos hay.** Los dos paros con su causa y su hora, el nivel de los buffers, dónde
  está el técnico, cuánto tarda en llegar y en resolver cada causa, y las piezas que pasaron
  por la 6 desde la última vez que se sabe que estaba bien.
- **Qué debe deducir.** Para cada orden de atención, cuánta salida se pierde y cuántas
  piezas quedan en riesgo, y qué parte del daño de un paro ya la paga el otro. Nada de eso
  lo mide un dato.
- **Qué debe contestar.** El orden elegido, a quién se le falla y qué se paga por ello, y
  qué tendría que cambiar para invertirlo. Lo intuitivo es atender primero el cuello; es
  sospechoso porque los dos paros se traslapan en el tiempo.
- **Por qué es lógica.** Es un dilema: la prioridad se declara una vez y decide y
  justifica a quién se le falla, para esta situación y para cualquier otra.

### Situación 4 — La pieza que estaba a medias

- **Qué pasa.** Cuando una estación falla, una pieza queda a medias. Al reanudar hay que
  retomarla, repetirla o sacarla, sin perderla ni duplicarla. Una pieza perdida es una
  unidad que falta en el pedido; una duplicada, una unidad que sale dos veces. En un
  dispositivo médico, una pieza sin trazabilidad no se puede enviar.
- **Qué datos hay.** Entradas y salidas de cada estación con su instante, los contadores
  que cada estación reporta, el nivel de los buffers y quién reinició cuándo. Algunos
  reportes llegan tarde o no coinciden.
- **Qué debe deducir.** Dónde está cada pieza (en una estación, en un buffer, ya salió, se
  retiró) a partir de lo que entró y salió, qué pieza pudo perderse o contarse dos veces y
  qué se puede reanudar sin riesgo. Ningún dato dice «pieza perdida».
- **Qué debe contestar.** Por pieza, tres respuestas: «está en tal lugar», «no está» y «no
  se sabe», con el conteo físico que resolvería la duda. Y qué se reanuda ya y qué se
  verifica antes. Lo intuitivo es dar por buena la línea si lo que entró menos lo que
  salió coincide con lo que se ve; es sospechoso porque un error puede tapar a otro.
- **Por qué es lógica.** «No está» y «no sé si está» no son lo mismo, y un hecho que llega
  tarde (el conteo) cambia las conclusiones sin cambiar las reglas.

### Situación 5 — El mismo tiempo, dos veredictos

- **Qué pasa.** A mitad del turno cambia el modelo y la estación 6 suma 20 % a su ciclo.
  Lo que antes era lento ahora es normal, y lo que antes era normal puede ser raro. Si la
  6 sigue tardando lo de antes cuando debía tardar más, quizá se saltó una operación. Y el
  tablero dice «procesando» mientras su salida no se mueve: puede estar trabajando, estar
  bloqueada o tener el reporte pegado. Una señal mal leída detiene la línea sin motivo o
  deja pasar un defecto.
- **Qué datos hay.** Modelo vigente y desde cuándo, ciclo nominal, la variación de ±10 %,
  estado reportado, instantes de salida de cada estación y nivel del buffer siguiente.
- **Qué debe deducir.** El tiempo esperado de cada pieza según el modelo con que entró a
  la estación (incluida la que estaba en proceso al cambiar), y si el tiempo observado es
  variación normal, lentitud real, bloqueo o un dato que no se puede creer.
- **Qué debe contestar.** Por estación, «normal», «anómala» o «no se sabe», con la razón.
  Lo intuitivo es marcar la estación más lenta; es sospechoso porque la que tarda lo mismo
  después de un cambio que debía alentarla también merece atención.
- **Por qué es lógica.** La misma lectura significa cosas distintas según el contexto, y
  cuando el estado reportado contradice lo que ocurre, la respuesta es «no se sabe».

## Por qué no basta un script

Con `if estacion.ciclo == max(ciclos): cuello = estacion` resuelves la línea con datos
perfectos y sin esperas. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué estación limita a la línea ahora? | decisión |
| ¿Por qué la 4 y no la 6? | explicación |
| ¿Qué estaciones se bloquean o se quedan sin piezas con este paro? | todas las respuestas |
| ¿Qué tendría que cambiar para que el paro no llegue a la estación 1? | la pregunta al revés |
| ¿Qué pasa si el paro de 5 minutos fuera en la estación 2? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Cómo distingue tu gemelo una estación lenta de una que solo espera?
2. Cuando dos paros piden al mismo técnico, ¿dónde queda escrito cuál gana?
3. ¿Qué hechos necesitas para saber dónde está una pieza que estaba a medias, y cómo
   distingue tu gemelo «no está» de «no sé»?
4. ¿Qué parte de la explicación le sirve al jefe de línea y qué parte es ruido?
5. ¿Qué estados y mensajes de las estaciones y los buffers de tu simulación en Erlang
   podrían alimentar a este gemelo con sus hechos?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la línea, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar lecturas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: la línea conserva sus 8 estaciones y sus buffers de 5, pero no
  simulas el turno de 7.5 h ni las 900 unidades: trabajas con una ventana corta del turno
  y unas decenas de piezas numeradas. Tú fijas cuánto dura.
- Los ciclos concretos de cada estación (dentro del rango de 25 a 40 s del original), los
  modelos de producto y cuál estación está en qué estado al empezar son datos inventados
  que defines tú. No son cifras de una planta real.
- La situación 3 la plantea esta extensión: que haya un solo técnico, el paro por calidad
  en la estación 6, y los tiempos de llegada y de reparación son datos del ejercicio.
- El «ahora» es un hecho del modelo, en segundos desde el inicio de tu ventana, no el reloj
  del sistema.
- Quedan a decisión del estudiante: cuánta discrepancia entre un contador y otro vuelve
  dudoso un dato, qué tan cerca debe estar una estación de la limitante para avisarlo,
  cuánto pesa una pieza en riesgo frente a un minuto de salida perdida, y cuánto tarda
  cada causa de paro en resolverse.
- Los identificadores de los ejemplos («estación 2», «pieza 14», «paro de 5 minutos en la
  2») son ilustrativos.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Falta de material en la primera estación y qué proveedor lo causa.
- Retrabajo: piezas rechazadas que regresan a una estación anterior.
- Relevos de turno y operadores que cubren más de una estación.
- Mantenimiento preventivo programado contra producción en curso.
- Inventario en proceso y su relación con el tiempo que una pieza pasa en la línea.

---
*Las cifras de dominio (8 estaciones, ciclos de 25 a 40 s con ±10 %, takt de 30 s con 27,000
s netos y 900 unidades por turno, buffers de 5 piezas, falla de 3 minutos en la estación 4,
+20 % en la 6, paro de 5 minutos en el cuello) vienen del problema original. Verifica la
fuente vigente antes de citarlas en tu entrega.*
