# #2 — Invernadero: gemelo digital con programación lógica

> Extensión del proyecto #2. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el clima del invernadero: sensores que reportan, un
controlador que pasa de enfriar a calentar o a modo seguro, actuadores que obedecen o no.
Esa simulación responde «¿en qué modo está el clima?». Quien cuida el cultivo necesita
más: «¿qué muevo ahora, qué dato puedo creer, y por qué?».

El gemelo digital es el **modelo lógico** del invernadero: hechos que reflejan su estado y
reglas que reflejan cómo se decide en él. Se escribe en Prolog porque lo difícil aquí es
arbitrar: metas que compiten, datos que se contradicen y actuadores desobedientes.

## El invernadero que se clona

Un invernadero de tomate en Baja California, reducido a 2 naves con 2 zonas cada una.

| Parte | Contenido |
|---|---|
| Entidades | nave → zona → sensor; por nave, 4 actuadores (ventanas cenitales, ventanas laterales, nebulización y calefacción), compartidos por sus dos zonas, y una meta de CO2 |
| Estado por zona | temperatura (°C), humedad relativa (%), CO2 (ppm), con el instante de cada lectura |
| Estado por actuador | lo último que se le ordenó, si está en automático o en manual, y su historia de órdenes y de energía |
| Estado por nave | si es de día o de noche, si hay viento fuerte, si hay energía |
| Eventos | llega una lectura, un sensor calla, sopla viento, se ordena mover un actuador, se corta la energía y regresa, alguien pone un actuador en manual |
| Decisiones | ¿ventilar, nebulizar o calentar?, ¿enriquecer con CO2?, ¿creerle a este sensor?, ¿entrar a modo seguro?, ¿qué actuador se puede mover sin estropearlo? |

## Situaciones que tu gemelo debe razonar

Las cuatro primeras salen del problema original (casos difíciles, escenario y
planteamiento); la quinta se construye con sus datos y con el modo manual/automático del
diseño OTP sugerido en el `README.md`. En cada una, tu gemelo debe llegar a una decisión
**y poder explicarla**.

### Situación 1 — Una noche, dos zonas, una sola ventana

- **Qué pasa.** Cerrar para calentar sube la humedad; abrir para ventilar enfría. Esa
  noche la zona norte está tan fría que el crecimiento se detiene (debajo de ~10 °C) y la
  sur lleva horas sobre ~90 % de humedad, que favorece botrytis y cenicilla. Las
  ventanas son las mismas para las dos.
- **Qué datos hay.** Temperatura y humedad de cada zona con su historia, ventanas,
  calefacción y que es de noche.
- **Qué debe deducir.** Qué pide cada zona, qué daño no se deshace, y si alguna
  combinación de actuadores no sacrifica a ninguna.
- **Qué debe contestar.** La orden para la nave, a qué zona se le falla y por qué, y qué
  tendría que cambiar para no fallarle a nadie.
- **Por qué es lógica.** Las dos zonas tienen razón. Quién gana es una prioridad entre
  metas que se escribe una vez y debe poder justificarse.

### Situación 2 — El sensor que miente con buena cara

- **Qué pasa.** Es una ola de calor con sol. De los 6 sensores de la nave, cinco marcan
  temperaturas peligrosas (arriba de ~32 °C hay aborto de flores) y el sexto marca una
  cómoda, dentro del rango óptimo de día, sin moverse desde hace horas. Si el controlador
  le cree, no ventila y se pierde producción.
- **Qué datos hay.** Las lecturas con su instante, el rango físico de cada variable y
  cada cuánto reporta un sensor (10 a 60 s). Ningún dato dice «sensor pegado».
- **Qué debe deducir.** Qué sensores se pueden creer, cuáles no y cuáles quedan en duda,
  comparándolos entre sí y con el tiempo; y si la nave pasa a modo seguro.
- **Qué debe contestar.** Por sensor: «creíble», «no creíble» o «no lo sé». La
  temperatura de la zona, marcada como estimada si no hay lectura creíble, con los
  sensores que la sustentan. Y qué hace la nave si no confía en ninguna lectura.
- **Por qué es lógica.** La credibilidad no es un dato de ningún sensor: se concluye
  comparando varios. Y lo intuitivo (creerle al que está «en orden») es lo sospechoso.

### Situación 3 — El viento y todo lo que se mueve con él

- **Qué pasa.** En un día soleado llega viento repentino y hay que cerrar las ventanas
  laterales. Cambian varias cosas a la vez: cuánto se puede ventilar, si tiene sentido
  enriquecer con CO2 (800-1000 ppm de día solo sirve con las ventanas cerradas) y qué
  usar para bajar la temperatura sin que la humedad pase de ~90 %.
- **Qué datos hay.** El viento con su instante, las ventanas, la temperatura y la
  humedad de las zonas, la meta de CO2 y que es de día.
- **Qué debe deducir.** Qué queda bloqueado y qué metas dejan de ser alcanzables,
  encadenando: del viento a las laterales, a la ventilación, y de ahí al calor, la
  humedad y el CO2.
- **Qué debe contestar.** El plan con su cadena, qué meta se sacrifica y cuál se protege,
  y qué se reabre al calmarse el viento.
- **Por qué es lógica.** Un evento externo cambia muchas reglas: se declara una vez y sus
  consecuencias se deducen, sin programar cada combinación.

### Situación 4 — Se ordenó abrir y nada cambió

- **Qué pasa.** Se ordenó abrir una ventana cenital y la temperatura no baja: puede
  estar atorada, la orden pudo no llegar, o basta esperar. Además hubo un corte de energía
  y su regreso: ¿en qué estado quedó cada actuador? Abrir y cerrar cada 10 s los destruye,
  y algunos no deben operar a la vez.
- **Qué datos hay.** Las órdenes con su instante, las lecturas posteriores, los cortes y
  regresos de energía. Ningún sensor mide la posición real de las ventanas.
- **Qué debe deducir.** Si el actuador obedeció, no obedeció o no se puede saber; qué
  órdenes admite ahora sin estropearse ni chocar con otro actuador.
- **Qué debe contestar.** Por actuador: «obedeció», «no obedeció» o «no lo sé», con la
  evidencia; con qué otros se compensa uno atorado; y los siguientes pasos válidos desde
  donde está, no solo el que conviene.
- **Por qué es lógica.** Orden y efecto son cosas distintas, y «qué puede seguir a qué»
  sirve igual para revisar una historia que para proponer el siguiente paso.

### Situación 5 — ¿Quién dejó que se quemaran las flores?

- **Qué pasa.** Tras una tarde calurosa hay aborto de flores en una zona. La bitácora
  muestra que alguien puso las ventanas cenitales en manual «para probar», una lectura
  dudosa y un corte de energía. El dueño quiere saber de quién fue la falla; el operador
  teme una sanción.
- **Qué datos hay.** Los eventos de la nave con su instante (incluido cuándo cada
  actuador pasó a manual o a automático) y las lecturas de las zonas.
- **Qué debe deducir.** Si la temperatura peligrosa pudo evitarse y qué la dejó pasar: el
  modo manual, un sensor engañoso, un actuador que no obedeció, o varias a la vez.
- **Qué debe contestar.** La cadena de causas con su evidencia, separando lo sabido de lo
  inferido y diciendo «no lo sé» si los datos no alcanzan; y qué habría pasado con las
  ventanas en automático.
- **Por qué es lógica.** Rendir cuentas es preguntarle al mismo modelo «qué pasó» y «qué
  habría pasado» cambiando un hecho; y el modo manual y el cultivo tienen su razón.

## Por qué no basta un script

Con `if temperatura > 32: abrir_ventanas()` resuelves una zona con sensores honestos y
actuadores obedientes. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué hago con la nave 1 ahora? | decisión |
| ¿Por qué no abres las ventanas laterales? | explicación |
| ¿Qué actuadores puedo mover hoy sin estropearlos? | todas las respuestas |
| ¿Qué tendría que pasar para poder enriquecer con CO2? | la pregunta al revés |
| ¿Qué pasaría si el sensor 3 deja de reportar? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué prioridad tienen las metas climáticas entre sí, y dónde queda escrito quién arbitra?
2. ¿Cuánto debe pasar entre dos cambios de un actuador, y cómo lo sabe tu gemelo sin reloj?
3. ¿Qué hace tu gemelo cuando no confía en ninguna lectura?
4. ¿Cómo distingue «el actuador no obedeció» de «no sé si obedeció»?
5. En Erlang el modo seguro era un estado de un `gen_statem`. ¿Qué decide el gemelo que
   ese estado no puede explicar?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del invernadero, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en ella.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para simular lecturas o graficar.

## Supuestos de esta extensión

- Escala reducida: 2 naves, 2 zonas por nave, 6 sensores por nave (3 por zona, uno de
  ellos con CO2) y 4 actuadores por nave, contra las 4 naves de ~1 ha del original. Los
  números de los ejemplos (cuántos sensores marcan qué) son ilustrativos.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir.
- Tú defines lo que el original no da: la prioridad entre metas, el tiempo mínimo entre
  dos cambios de un actuador, cuánto silencio o lectura inmóvil vuelve sospechoso a un
  sensor, cuántas horas son «varias» de humedad alta, qué es viento fuerte y qué hace
  cada actuador en modo seguro. Decláralos como supuestos.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Fertirriego: conductividad y pH de la solución nutritiva, cruzados con el clima.
- Déficit de presión de vapor como meta, en lugar de temperatura y humedad por separado.
- Mallas de sombra y térmicas como actuadores adicionales.

---
*Las cifras son de referencia y vienen del problema original. Verifica la fuente vigente
antes de citarlas en tu entrega.*
