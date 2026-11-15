# #36 — Mantenimiento predictivo: gemelo digital con programación lógica

> Extensión del proyecto #36. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste las máquinas: vibración y temperatura con ruido, un
rodamiento que se degrada, un sensor que se pega o se desconecta. Esa simulación responde
«¿qué están midiendo los sensores?». El jefe de mantenimiento necesita algo más: «¿qué
máquina intervengo primero, con cuánto margen, y por qué?».

El gemelo digital es el **modelo lógico** de la planta: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque lo que hay que
resolver aquí no es calcular, sino combinar evidencia, justificar y descartar.

## La planta que se clona

Una planta de autopartes (ficticia, ver «Supuestos») con 5 máquinas en 2 líneas, cada una
con un sensor de vibración y uno de temperatura.

| Parte | Contenido |
|---|---|
| Entidades | planta → línea → máquina → sensor; refacciones en almacén y una cuadrilla de mantenimiento |
| Estado por máquina | vibración (velocidad RMS en mm/s, pico, banda del defecto del rodamiento), temperatura, régimen de operación (carga y velocidad), línea base propia por régimen, nivel de alerta |
| Estado por línea | qué máquinas tienen respaldo, próxima ventana de paro programado |
| Eventos | llega una lectura, un sensor deja de reportar, cambia el régimen, se registra un golpe, se abre una orden de mantenimiento |
| Decisiones | ¿cuál es el nivel (normal, vigilancia, alarma, paro)?, ¿cuánto margen queda?, ¿a quién se interviene primero?, ¿confiar en este dato? |

## Situaciones que tu gemelo debe razonar

Las cinco parten del problema original (casos difíciles, escenario y datos del mundo
real); las situaciones 1, 4 y 5 añaden contexto derivado, que se señala en «Qué pasa».
En cada una, tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — El golpe que explica el pico, pero no la tendencia

- **Qué pasa.** La máquina 2 muestra un pico de vibración y la bitácora registra que un
  montacargas golpeó su base esa misma hora. Alertar por cualquier pico para la línea sin
  necesidad; descartar todo lo «explicado» deja pasar una falla. Los días anteriores, esa
  máquina ya venía subiendo poco a poco (el golpe en la bitácora es contexto derivado;
  distinguir golpe y degradación es un caso difícil del original).
- **Qué datos hay.** Lecturas con su hora (RMS, pico), la línea base de la máquina y los
  eventos registrados. Ningún sensor mide «golpe» ni «degradación».
- **Qué debe deducir.** Qué parte de lo observado es un suceso aislado y cuál es
  tendencia, y si el golpe tiene algo que ver con ella. Lo intuitivo («hay una explicación
  para el pico, se descarta todo») es sospechoso.
- **Qué debe contestar.** El nivel de la máquina, qué parte se atribuye al golpe y cuál a
  la tendencia, y cuántas lecturas más confirmarían o descartarían la degradación.
- **Por qué es lógica.** Hay una explicación válida para un dato y otra para otro; la
  conclusión sale de separarlas, no de promediarlas ni de compararlas con un umbral.

### Situación 2 — La carga cambió, ¿la máquina también?

- **Qué pasa.** La máquina 4 pasa por la mañana a una carga y velocidad mayores, y su
  vibración sube. Según la línea base de la carga anterior parece degradación; según la del
  nuevo régimen, es normal. Pero esa máquina, del tipo mediano, ya está en un rango de
  vibración donde la clasificación ISO 10816/20816 pide atención sin importar su historia
  (el original da 4.5-7 mm/s como alerta en máquinas medianas). Dos criterios válidos, dos
  veredictos.
- **Qué datos hay.** Lecturas, cambios de régimen con su hora, línea base por régimen,
  tipo de máquina.
- **Qué debe deducir.** Contra qué línea base debe compararse cada lectura según el régimen
  vigente en ese momento, y qué hacer cuando el criterio absoluto y el relativo discrepan.
  Lo intuitivo («subió, es degradación») puede estar mal, y «es normal para su régimen» también.
- **Qué debe contestar.** Nivel, el criterio que manda y por qué, y qué cambiaría el
  veredicto (por ejemplo, volver al régimen anterior). Si el cambio de régimen no tiene
  hora registrada, el gemelo debe decir que no sabe contra qué línea base comparar.
- **Por qué es lógica.** Una misma lectura significa algo distinto según el contexto, y
  las prioridades entre criterios se declaran una vez.

### Situación 3 — El rodamiento que se anuncia en la vibración y se confirma en la temperatura

- **Qué pasa.** En la máquina 1, la vibración de la banda del defecto del rodamiento crece
  cerca de 2 % por día desde hace semanas (el escenario del original); la temperatura aún
  está en su nominal. En la máquina 5 ocurre lo contrario: la temperatura está sobre la
  nominal, pero la vibración es normal. Antes de fallar, un rodamiento aumenta la
  vibración y luego la temperatura; y cada 10 °C sobre la nominal reduce a la mitad la vida
  del aislamiento del motor (regla de Montsinger).
- **Qué datos hay.** Lecturas de vibración y temperatura con su hora, línea base, temperatura
  nominal de cada motor. Ningún sensor mide «rodamiento degradado».
- **Qué debe deducir.** El estado probable del rodamiento y su etapa en cada máquina,
  combinando varias señales y su orden en el tiempo; y qué implica la temperatura sobre
  el aislamiento. Lo intuitivo («la temperatura está bien, la máquina está bien») es
  sospechoso, y «está caliente, es el rodamiento» también.
- **Qué debe contestar.** Para cada máquina, el diagnóstico, la etapa, la cadena de
  razones que lo sostiene y qué señal faltaría para escalar a alarma.
- **Por qué es lógica.** Cada diagnóstico encadena varias deducciones (tendencia, desvío de
  la línea base, orden de aparición de las señales, efecto sobre el aislamiento) y debe
  poder contarse paso a paso.

### Situación 4 — La lectura perfecta que no es de fiar

- **Qué pasa.** El sensor de vibración de la máquina 3 repite exactamente el mismo valor
  durante horas, el de una máquina sana (sensor pegado, caso del original), mientras su
  temperatura sí sube. El de la máquina 5 dejó de reportar, aunque el controlador de la
  línea dice que sigue produciendo (sensor desconectado, también del original). La
  máquina 4 también calla, pero tiene registrado un paro: su silencio es legítimo (el
  controlador y los eventos de paro son contexto derivado).
- **Qué datos hay.** Lecturas con su hora, el rango físico de cada variable, eventos de
  arranque y paro (derivados de esta extensión) y la señal del otro sensor de la máquina.
- **Qué debe deducir.** Si cada sensor es creíble, está pegado, está desconectado o calla
  con razón, y qué se puede concluir de la salud de la máquina cuando su sensor no es
  fiable. Lo intuitivo («una lectura estable es salud perfecta») es sospechoso: las
  señales reales traen ruido.
- **Qué debe contestar.** Tres respuestas distintas: «sí», «no» y «no lo sé». Para la
  máquina 3, no «normal», sino «sin información fiable de vibración», con la razón y la
  señal que obliga a revisar el sensor sin esperar.
- **Por qué es lógica.** «Todo bien» y «no tengo cómo saberlo» no son lo mismo, y la
  duda de un sensor se contrasta con el resto de la evidencia.

### Situación 5 — Una refacción, una ventana y dos máquinas

- **Qué pasa.** En la línea 1, la máquina 1 (con respaldo) está más cerca del límite que la
  máquina 2 (sin respaldo: si falla, la línea se detiene, y un paro no planeado en
  automotriz cuesta miles de dólares por minuto). Hay una sola refacción de rodamiento y
  una sola ventana de paro programado. Mantenimiento necesita anticipo para planear, no
  para correr. Ambas partes tienen razón: la urgente y la crítica (refacción, ventana y
  respaldos son contexto derivado; alertar a tiempo para planear es un caso difícil del
  original).
- **Qué datos hay.** Estado y tendencia de cada máquina, qué máquinas tienen respaldo,
  refacciones, ventana de paro y la hora actual.
- **Qué debe deducir.** Cuánto margen queda a cada máquina, a cuál ya no se le puede
  avisar «a tiempo para planear» y a quién se le da la refacción y la ventana.
- **Qué debe contestar.** El plan, con su justificación y a quién se le acepta el riesgo.
  Con más de un plan válido, los muestra todos. Si ninguno alcanza, lo dice y señala qué
  falta (otra refacción, otra ventana, más anticipo).
- **Por qué es lógica.** Una decisión que perjudica a alguien debe quedar escrita como
  política y poder justificarse, no resolverse en cada caso.

## Por qué no basta un script

Con `if rms > 7: alarma()` resuelves una máquina con un sensor perfecto. Tu gemelo debe
contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué nivel tiene la máquina 1? | decisión |
| ¿Por qué? | explicación |
| ¿Qué máquinas están hoy en vigilancia o peor? | todas las respuestas |
| ¿Qué tendría que pasar para que la 2 pase a alarma? | la pregunta al revés |
| ¿Qué pasaría si la refacción llega 12 horas más tarde? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué tan grande debe ser un cambio para ser una señal y no ruido? (del original)
2. ¿Cuánto adelanto necesita el equipo de mantenimiento para actuar? (del original)
3. ¿Cómo distingue tu gemelo «no hay degradación» de «no sé si hay degradación»?
4. ¿Qué parte de la explicación le sirve al jefe de mantenimiento y cuál es ruido?
5. ¿Qué parte de tu simulación en Erlang (el detector, el estado de salud, la deriva
   inyectada) podría alimentar a este gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la planta, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar lecturas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 5 máquinas en 2 líneas, contra las 20 máquinas del escenario original.
- La planta, el montacargas, el controlador de línea, la refacción única, la ventana de
  paro, los regímenes y los números de máquina de los ejemplos los plantea esta
  extensión; no vienen del original. Cada situación puede usar su propio conjunto de
  datos: sus máquinas no tienen por qué coincidir entre sí.
- Unidad del tiempo: la hora. El «ahora» es un hecho del modelo, no el reloj del sistema,
  para que las respuestas se puedan repetir.
- Tú defines: la línea base de cada máquina y régimen; cuántas lecturas hacen una tendencia
  y cuántas un pico aislado; cuántas lecturas idénticas hacen un sensor pegado; el anticipo
  que mantenimiento necesita (el original no lo da); cuál criterio manda entre la línea
  base y la zona ISO; qué máquinas son críticas; los niveles intermedios entre vigilancia,
  alarma y paro. El original solo da el ejemplo de 4.5-7 mm/s para máquinas medianas.

## Extensiones posibles

Estas situaciones no vienen del problema original: investiga y cita tus fuentes antes de
fijar cifras.

- Análisis del espectro (FFT): qué frecuencia delata cada defecto.
- Otras fallas además del rodamiento (desalineación, desbalance, lubricación).
- Costo de paro frente a costo de intervenir antes de tiempo.
- Aprendizaje de la línea base de una máquina nueva sin historial.
- Estimación del tiempo restante con una tendencia que se acelera.

---
*Las cifras de dominio (zonas ISO 10816/20816 y el rango de 4.5-7 mm/s, regla de
Montsinger de 10 °C, crecimiento de 2 % por día, 20 máquinas, costos de paro por minuto) son
de referencia y vienen del problema original. Lo demás es de esta extensión. Verifica la
fuente vigente antes de citarlas en tu entrega.*
