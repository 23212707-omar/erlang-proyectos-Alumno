# #33 — OEE de máquinas: gemelo digital con programación lógica

> Extensión del proyecto #33. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la planta: un proceso por máquina que acumula tiempo
operando y parado, piezas buenas y malas, y un calculador que saca el OEE
(Disponibilidad × Rendimiento × Calidad) por máquina y por turno. Esa simulación responde
«¿cuánto OEE tiene cada máquina?». El jefe de planta necesita algo más: «¿qué clase de
tiempo perdido es este, a quién se le carga, qué ataco primero, y por qué?».

El gemelo digital es el **modelo lógico** de la planta: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque lo difícil aquí
no es multiplicar tres porcentajes, sino decidir a qué clase pertenece cada tramo de
tiempo cuando las señales son ambiguas, justificarlo y saber decir «no lo sé».

## La planta que se clona

Una planta de manufactura reducida a 4 máquinas y 3 turnos. El tiempo se cuenta en
segundos. Las cinco situaciones salen del problema original; lo que se añade son
precisiones para poder razonarlas.

| Parte | Contenido |
|---|---|
| Entidades | planta → máquina; turno; operador y supervisor (quienes capturan el motivo de un paro) |
| Estado por máquina | señal (en marcha, paro, alarma), contador de piezas, contador de rechazos, velocidad nominal, motivo del paro si alguien lo capturó |
| Estado por turno | inicio, fin y tiempo planeado de producción |
| Estado de la planta | calendario de paros planeados (relevos, mantenimiento, ajustes programados) |
| Eventos | cambia la señal de una máquina, suena o cesa una alarma, llega una lectura de contadores, alguien captura un motivo, cambia el turno, una máquina deja de reportar |
| Decisiones | ¿a qué clase pertenece este tramo (produciendo, paro planeado, paro no planeado, velocidad reducida)?, ¿a qué turno se le carga?, ¿cuántas piezas se hicieron de verdad?, ¿dónde se pierde más tiempo?, ¿confío en este dato? |

## Situaciones que tu gemelo debe razonar

Las cinco parten del problema original: la 1, la 4 y la 5 son sus «casos difíciles»; la 2
y la 3 son su «escenario a simular». Lo que añade esta extensión (las fuentes en pugna, el
motivo capturado tarde, el orden de qué atacar) es complemento derivado de sus datos y de
su planteamiento. En cada una, tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — El paro que nadie explicó

- **Qué pasa.** A media mañana una máquina pasa de «en marcha» a «paro» y el campo de
  motivo se queda vacío. La señal de alarma estuvo activa un tramo del paro y no en el
  resto. El supervisor del turno dice que fue un cambio programado; mantenimiento dice
  que fue una falla. Si se carga como paro planeado, no baja el OEE y nadie responde;
  si se carga como no planeado, baja la disponibilidad y el área de mantenimiento queda
  señalada.
- **Qué datos hay.** Cambios de señal con su instante, alarma, calendario de paros
  planeados, motivo (vacío), y el catálogo de las seis grandes pérdidas. Ningún dato dice
  «falla» ni «cambio».
- **Qué debe deducir.** A qué clase y a qué gran pérdida pertenece cada tramo del paro
  (puede cambiar dentro del mismo paro) y con qué certeza; y, si todavía no se puede
  afirmar, qué falta y a quién le toca capturarlo.
- **Qué debe contestar.** La clasificación de cada tramo con su evidencia, marcada como
  provisional si lo es, qué dato la confirmaría y cómo cambia cuando llegue el motivo.
- **Por qué es lógica.** La clase no está en ningún dato: sale de que coincidan señal,
  alarma y calendario, y se revisa cuando llega un hecho nuevo.

### Situación 2 — La ráfaga que nadie anotó

- **Qué pasa.** En una sola máquina, durante 2 horas, la señal pasa a paro 30 s, vuelve a
  marchar y se repite. Cada paro es de menos de ~5 min, así que nadie lo anota a mano.
  Mirando un instante cualquiera, la máquina «está produciendo» casi todo el tiempo. En
  otra máquina la señal nunca baja, pero el contador avanza más lento de lo nominal. Si
  el gemelo no ve la ráfaga, el OEE baja y nadie sabe por qué; mantenimiento no recibe
  aviso y la planta sigue perdiendo piezas.
- **Qué datos hay.** Cambios de señal con instante, contador de piezas, velocidad nominal
  de cada máquina, rangos. No hay motivo capturado.
- **Qué debe deducir.** Que hay una ráfaga (varios paros cortos de la misma máquina en
  una misma ventana), cuánto tiempo suman, y a qué pérdida pertenece cada caso: microparo
  si la señal baja, velocidad reducida si la señal nunca baja y el ritmo sí.
- **Qué debe contestar.** Por máquina, si tiene un problema, la evidencia (los paros que
  componen la ráfaga o el ritmo observado), cuánto resta a disponibilidad y cuánto a
  rendimiento, y qué hechos moverían la clasificación. Lo intuitivo es decir que paros de
  30 s son ruido y que la máquina está bien porque casi siempre marcha. Es sospechoso:
  según el original, los microparos son gran parte de la pérdida real.
- **Por qué es lógica.** El problema es un patrón sobre varios hechos (repetición, misma
  máquina, misma ventana, señal contra contador), no un número comparado con un umbral.

### Situación 3 — El contador que volvió a cero

- **Qué pasa.** A mitad del turno el contador de piezas de una máquina baja de un valor
  alto a uno pequeño. El de rechazos no baja. Además, la señal de marcha parpadea un
  instante, como las señales ruidosas que describe el original. Si el gemelo toma la
  bajada como dato, la producción sale negativa o la calidad pasa de 100 %; si la ignora,
  pierde piezas reales del turno. Con esas cifras se decide un bono de turno y un reporte
  a un cliente.
- **Qué datos hay.** Lecturas de ambos contadores con su instante, la señal, los eventos
  de paro, el rango físico de cada contador.
- **Qué debe deducir.** Si la bajada es un reinicio (hay que sumar el tramo anterior y el
  posterior), un dato imposible o algo que no se puede saber; cuántas piezas buenas y
  malas hubo en el turno, y si el parpadeo cuenta como paro. Una pista que solo se ve
  juntando datos: un contador de rechazos mayor que el de piezas no puede ser verdad.
- **Qué debe contestar.** Tres respuestas distintas: «fue un reinicio», «no lo fue» y
  «no lo sé». La producción del turno con la condición de la que depende, y qué lectura
  la confirmaría.
- **Por qué es lógica.** «Dato inválido», «dato imposible» y «dato que no puedo juzgar»
  son estados distintos, y cada uno cambia lo que se concluye de lo que depende de él.

### Situación 4 — Un paro que cruza el cambio de turno

- **Qué pasa.** Un paro empieza hacia el final de un turno y sigue en el siguiente. El
  turno saliente no capturó motivo. El entrante lo captura ya avanzado su turno: faltaba
  material, algo ajeno a la máquina. Dentro del cruce hay además un tramo de relevo que
  el calendario marca como paro planeado. El turno saliente dice que su máquina no falló
  y que el motivo lo reporta el otro turno; el entrante dice que el paro ya venía y que
  no lo causó. Ambos tienen razón en algo, y cada uno responde por su OEE.
- **Qué datos hay.** Cambios de señal con instante, inicio y fin de cada turno, calendario
  con el relevo, y el motivo con el instante en que se capturó (no el de cuando ocurrió).
- **Qué debe deducir.** Qué parte del paro cae en cada turno, qué parte del relevo no
  cuenta, a qué clase pertenece el resto una vez conocido el motivo, y cómo queda el OEE
  de cada turno y del día. Es una cadena: el paro empezó, cruzó el relevo, el motivo llegó
  tarde, el motivo lo vuelve no planeado, y eso cambia la disponibilidad de dos turnos.
- **Qué debe contestar.** El reparto por turno con la regla que lo decidió, a quién se le
  falla y por qué no el reparto contrario, y cómo cambia cada OEE si el motivo hubiera
  llegado antes o no hubiera llegado.
- **Por qué es lógica.** Las prioridades entre turnos se declaran una vez y valen para
  todos los cruces; el mismo paro da veredictos distintos según cuándo se conoce.

### Situación 5 — La máquina que dejó de reportar, y qué atacar primero

- **Qué pasa.** Cierra el turno y el jefe pide el OEE por máquina y dónde se perdió más
  tiempo para decidir qué atacar primero. Una máquina dejó de enviar su señal hace rato,
  aunque su contador de piezas sigue llegando. Otra solo tiene datos de parte del turno.
  Si el jefe manda a mantenimiento a la máquina equivocada, se pierde un turno completo
  de la cuadrilla; si ignora la dudosa, puede dejar sin atender la peor.
- **Qué datos hay.** Las señales y contadores que sí llegaron, con su instante; el
  calendario; los motivos capturados; la velocidad nominal de cada máquina.
- **Qué debe deducir.** Qué se puede afirmar de la máquina sin señal a partir de lo que
  sí reporta (si el contador avanzó, no estuvo parada en ese tramo), qué no se puede
  afirmar, y si el orden de qué atacar entre las demás máquinas depende de lo que
  pasó en esa.
- **Qué debe contestar.** El OEE y las pérdidas de cada máquina, con la dudosa marcada y
  lo que se sabe de ella; y el orden de qué atacar, diciendo si vale «sea lo que sea que
  pasó en la máquina sin datos» o si no se puede decidir. Lo intuitivo es tratar el
  silencio como cero paros (la máquina parece la mejor de la planta) o como paro total.
  Ambas respuestas son sospechosas: faltar un dato no es ni bueno ni malo.
- **Por qué es lógica.** Hay que razonar sobre todas las posibilidades compatibles con lo
  que se sabe, y «no lo sé» también se propaga a lo que depende de ello.

## Por qué no basta un script

Con `if señal == "paro": minutos_parado += 1` cuentas el tiempo parado de una máquina con
señales perfectas. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué clase de pérdida es el paro de la máquina 2? | decisión |
| ¿Por qué es no planeado y no un cambio programado? | explicación |
| ¿Qué máquinas tienen hoy una ráfaga de microparos? | todas las respuestas |
| ¿Qué tendría que capturarse para que ese paro cuente como planeado? | la pregunta al revés |
| ¿Qué pasaría con el orden de qué atacar si la máquina 4 hubiera estado parada todo el turno? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir una máquina en un instante, y cuáles sacas de
   las señales en lugar de guardarlos?
2. Cuando la señal, la alarma y el calendario se contradicen, ¿dónde queda escrito cuál
   gana y cómo se revisa cuando llega un motivo?
3. ¿Cómo distingue tu gemelo «no hubo paro» de «no sé si hubo paro»?
4. ¿Cuál es el tiempo planeado, quién lo define, y qué cuentas como microparo y qué como
   producción a baja velocidad?
5. En tu simulación en Erlang, ¿qué acumulaba cada proceso de máquina, y qué sabría tu
   gemelo de una máquina si ese proceso se reinicia a mitad del turno?

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

- Escala reducida: 4 máquinas y 3 turnos, contra las 10 máquinas y 3 turnos del original.
  El original da un contador por segundo; tu gemelo puede trabajar con lecturas sueltas y
  con eventos de cambio de señal en vez de un registro por segundo. Tú generas los datos.
- El «ahora» es un hecho del modelo, en segundos desde el inicio de tu ventana, no el reloj
  del sistema.
- Lo siguiente es decisión tuya y debe quedar escrito como supuesto: el tiempo planeado de
  cada turno y quién lo define; la velocidad nominal de cada máquina; cuántos paros cortos
  hacen una ráfaga y en qué ventana (el original solo dice «menores a ~5 min»); cuánto
  silencio vuelve dudosa una señal; qué salto del contador cuenta como reinicio; quién
  captura el motivo y cuándo; qué hacer con un parpadeo de la señal; y cómo se reparte un
  paro entre dos turnos.
- Las duraciones concretas de cada caso, el motivo «falta de material» y los
  identificadores de los ejemplos («máquina 2», «máquina 4») son ilustrativos.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Defectos de arranque tras un cambio de producto o un paro largo.
- Un solo equipo de mantenimiento para dos paros no planeados a la vez.
- Motivos capturados que no cuadran con las señales, cuando hay un bono de por medio.
- Aprovechar un paro largo para adelantar el mantenimiento preventivo.
- Comparar cada máquina con el OEE de referencia que menciona el original.

---
*Las cifras de dominio (OEE como Disponibilidad × Rendimiento × Calidad, 10 máquinas y 3
turnos, contador por segundo, ráfaga de microparos de 30 s durante 2 horas, microparos de
menos de ~5 min, las seis grandes pérdidas) vienen del problema original. Los demás
números (4 máquinas y los ejemplos) son de esta extensión. Verifica la fuente vigente
antes de citarlas en tu entrega.*
