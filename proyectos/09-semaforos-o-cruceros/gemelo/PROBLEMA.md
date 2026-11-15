# #9 — Semáforos o cruceros: gemelo digital con programación lógica

> Extensión del proyecto #9. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el crucero: un proceso por semáforo, un coordinador que
sincroniza fases, detectores que fallan y un modo intermitente cuando algo sale mal. Esa
simulación responde «¿en qué color está cada semáforo?». El ingeniero de tránsito
necesita algo más: «¿qué movimientos pueden ir juntos, a quién le toca esperar, a qué
detector le creo y qué sigue siendo seguro cuando se cae la comunicación?».

El gemelo digital es el **modelo lógico** del crucero: hechos que reflejan su estado y
reglas que reflejan cómo se decide en él. Se escribe en Prolog porque lo que hay que
resolver aquí no es cronometrar, sino acomodar movimientos sin contradicciones,
justificar a quién se le hace esperar y saber decir «no lo sé».

## El crucero que se clona

Un crucero de Tijuana con 4 aproximaciones, más dos cruceros vecinos aguas abajo que
forman con él una ola verde de 3. Se modela un crucero completo; los otros dos aportan
su estado y su desfase.

| Parte | Contenido |
|---|---|
| Entidades | crucero → aproximación → movimiento (de frente, vuelta a la izquierda); pasos peatonales; detectores; tramos entre cruceros |
| Estado por movimiento | qué indicación muestra (verde, amarillo, rojo, intermitente) y desde cuándo; cuánta demanda tiene |
| Estado por detector | su última lectura con instante y a qué aproximación sirve |
| Estado por crucero | plan de tiempos vigente, fase en curso, modo (normal, intermitente), si hay comunicación con sus vecinos |
| Eventos | llega una lectura, se pulsa un botón peatonal, una ambulancia pide preferencia, cambia el plan, se pierde la comunicación, el controlador se reinicia |
| Decisiones | ¿qué movimientos van juntos?, ¿cuánto dura cada fase?, ¿se atiende ya al peatón o a la ambulancia?, ¿a qué detector le creo?, ¿qué se mantiene sin comunicación? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original. Cada una añade un detalle derivado: los
movimientos de vuelta (1), el ancho de las calles (2), el peatón que aún cruza (3), las
otras fuentes del detector (4) y la distancia entre cruceros (5). En cada una, tu gemelo
debe llegar a una decisión **y poder explicarla**.

### Situación 1 — ¿Quién puede ir con quién?

- **Qué pasa.** En hora pico llegan 1,200 vehículos por hora a cada aproximación. El
  flujo de saturación es de unos 1,800 a 1,900 vehículos por hora por carril durante el
  verde. Un plan de fases debe agrupar movimientos que no se crucen, dejar el amarillo
  (3 a 4 s) y el despeje de todo rojo (1 a 2 s) entre fases conflictivas, y el ciclo
  debe quedar entre 60 y 120 s. Lo que parece lógico («norte y sur juntos») depende de
  qué haga cada auto al llegar al centro del crucero.
- **Qué datos hay.** Aproximaciones con su número de carriles, movimientos de cada una,
  demanda por aproximación y qué pares de movimientos se cruzan. Ningún dato dice
  «este plan es seguro» ni «este plan alcanza».
- **Qué debe deducir.** Qué conjuntos de movimientos pueden compartir verde, en qué
  orden pueden seguirse las fases y si alguna combinación cabe en el ciclo permitido
  con la demanda dada.
- **Qué debe contestar.** El plan completo (fases, verde, amarillo y despeje de cada
  una); por qué cada movimiento quedó en su fase y no en otra; si hay varios planes
  válidos, cuáles son; y si ninguno existe, que no hay y qué lo impide.
- **Por qué es lógica.** Es acomodar movimientos bajo restricciones a la vez, no hallar
  el mejor para uno. Y «ninguna solución» es una respuesta, no un error.

### Situación 2 — El peatón que necesita veinte metros

- **Qué pasa.** Un paso peatonal cruza una calle de 20 m. Un peatón camina a 1.0-1.2 m/s,
  así que necesita de 17 a 20 s de despeje peatonal. Los botones se presionan de forma
  aleatoria: pueden pulsarse tarde, dos veces o sin que nadie cruce. De ese tiempo
  dependen los vehículos que cruzan por ese paso, y de ellos el resto del ciclo.
- **Qué datos hay.** El ancho de cada paso, los eventos de botón con su instante, la
  fase en curso y el plan vigente. Nadie mide cuántos peatones hay ni qué tan lentos son.
- **Qué debe deducir.** En cadena: qué tiempo mínimo exige el paso, qué movimientos
  vehiculares quedan bloqueados mientras dura, qué fases se alargan por eso y si el
  ciclo resultante sigue dentro del máximo.
- **Qué debe contestar.** Si el peatón se atiende en este ciclo o en el siguiente, cuánto
  dura su fase y qué hay que ceder para que quepa; y qué pasaría con un paso más ancho.
- **Por qué es lógica.** Una decisión (atender al peatón) provoca otras en cadena, y
  cada una tiene que poder explicarse hacia atrás hasta el ancho de la calle.

### Situación 3 — La ambulancia y la persona que sigue en la calle

- **Qué pasa.** Una ambulancia solicita preferencia mientras un anciano sigue cruzando
  y su despeje peatonal no ha terminado. El *conflict monitor* de hardware pondrá el
  crucero en destellos rojos si ve dos verdes conflictivos, y el software no debe
  confiarse solo de sí mismo. Las dos partes tienen la razón: la ambulancia no puede
  esperar de más, y la persona no puede quedarse sin su tiempo.
- **Qué datos hay.** La fase en curso con su inicio, el despeje peatonal vigente, la
  aproximación y el movimiento de la ambulancia, y su solicitud con instante.
- **Qué debe deducir.** Qué hay que terminar antes de poder darle verde, cuánto falta, y
  si su movimiento ya es compatible con la fase en curso o exige cambiarla.
- **Qué debe contestar.** La secuencia de pasos hasta el verde de la ambulancia, a quién
  se le hace esperar y por qué esa parte y no la otra. Lo intuitivo es cortar todo de
  golpe y dar verde ya; es sospechoso porque ese atajo produce dos verdes conflictivos.
  La respuesta correcta puede ser distinta.
- **Por qué es lógica.** Hay secuencias válidas e inválidas de estados, y la regla debe
  elegir quién espera y dejarlo por escrito.

### Situación 4 — El detector que siempre dice «ocupado»

- **Qué pasa.** En una madrugada de fin de semana la demanda es casi cero, pero el lazo
  de una aproximación marca «ocupado» sin parar. Si se le cree, esa calle se queda con
  el verde y la transversal espera sin motivo. Si no se le cree y sí hay una fila
  detenida, alguien se queda esperando de verdad. Los detectores (lazos, cámaras,
  radar) pueden fallar.
- **Qué datos hay.** Lecturas con su instante de ese lazo, de la cámara de la misma
  aproximación y de otros lazos, los vehículos que contó el crucero vecino aguas abajo
  y el rango físico de cada variable.
- **Qué debe deducir.** Si hay fila, no la hay o no se puede saber; y cuánto aguanta la
  aproximación atendida antes de que la transversal tenga razón para quejarse.
- **Qué debe contestar.** Tres respuestas distintas: «sí hay fila», «no hay» y «no lo
  sé», con la evidencia. Una lectura sospechosa nunca decide un verde por sí sola.
- **Por qué es lógica.** «El lazo marca ocupado» y «hay autos» son afirmaciones
  distintas, y confrontar dos fuentes que se contradicen es razonar, no medir.

### Situación 5 — La ola verde que se queda sola

- **Qué pasa.** Tres cruceros consecutivos van coordinados con un desfase igual al
  tiempo de viaje (400 m a 40 km/h son unos 36 s). Se pierde la comunicación entre ellos, y el
  segundo se reinicia justo entonces: ¿en qué fase arranca, si no sabe en qué punto de
  la ola está? Además, el tercero ya había recibido un cambio de plan en pleno ciclo.
- **Qué datos hay.** Tramos con su distancia, modo y plan de cada crucero, eventos de
  comunicación perdida, de reinicio y de cambio de plan, con su instante. Ningún dato
  dice «la ola sigue coordinada».
- **Qué debe deducir.** Si la coordinación se mantiene, se degrada o se rompe; qué sigue
  siendo seguro aunque se pierda la ola; y con qué fase puede arrancar un controlador
  que ya no recuerda su estado sin quedar en conflicto con lo que muestran los vecinos.
- **Qué debe contestar.** Qué se mantiene y qué no en cada crucero, en qué fase arranca
  el reiniciado, qué cambio de plan se aplica y cuál se pospone, y a quién le tocará
  esperar. Todo con la razón; y lo que es suposición, marcado como tal.
- **Por qué es lógica.** La coordinación es una relación entre cruceros, no una variable
  de uno, y de varios hechos que no la miden se deduce si todavía existe.

## Por qué no basta un script

Con `if cola[norte] > 0: dar_verde(norte)` atiendes una aproximación con detector
perfecto y sin nadie más esperando. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué fase sigue en este crucero? | decisión |
| ¿Por qué no le toca ya a la ambulancia? | explicación |
| ¿Con qué otros movimientos puede ir el de frente al norte? | todas las respuestas |
| ¿Qué tendría que cambiar para que ese plan cupiera en 120 s? | la pregunta al revés |
| ¿Qué pasa si la calle del paso peatonal mide 30 m? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir un crucero en un instante?
2. ¿Qué estados son imposibles y dónde queda escrito que lo son?
3. Cuando la seguridad y la urgencia chocan, ¿dónde queda escrito cuál gana?
4. ¿Cómo distingue tu gemelo «no hay fila» de «no sé si hay fila»?
5. En Erlang cada semáforo es un `gen_statem` con un coordinador. ¿Qué de eso alimentaría
   a este gemelo, y qué decide el gemelo que el proceso no puede?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del crucero, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra el plan o la
  decisión con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para simular lecturas o graficar.

## Supuestos de esta extensión

- Escala reducida: un crucero completo con 4 aproximaciones y 2 vecinos descritos solo
  por su estado y distancia, contra los 3 cruceros simulados del escenario original.
- El «ahora» es un hecho del modelo, en segundos, no el reloj del sistema, para que las
  respuestas se puedan repetir.
- Tú defines: los carriles de cada aproximación, qué pares de movimientos se cruzan,
  cuántos autos giran a la izquierda, el ancho de cada paso (20 m es el ejemplo del
  original), la distancia de cada tramo (400 m a 40 km/h, ídem), cuánto tiempo
  «siempre ocupado» vuelve sospechoso a un detector, cuánto se tolera que la
  transversal espere, cuánto reloj puede derivar un crucero sin comunicación y cuándo
  entra un cambio de plan.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Fases exclusivas para peatones o ciclistas, y prioridad al transporte público.
- Obras o un accidente que cierran un carril y obligan a rehacer el plan.
- Auditoría: demostrar después de un choque por qué el crucero mostró lo que mostró.

---
*Las cifras vienen del problema original y son de referencia (órdenes de magnitud).
Verifica la fuente vigente antes de citarlas en tu entrega.*
