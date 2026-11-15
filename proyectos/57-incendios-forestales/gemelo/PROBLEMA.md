# #57 — Incendios forestales: gemelo digital con programación lógica

> Extensión del proyecto #57. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la vigilancia: un proceso por sensor, un evaluador de
riesgo por zona, un estado que pasa de vigilancia a sospecha y a incendio confirmado.
Esa simulación responde «¿qué dicen los sensores?». Quien decide a quién avisar necesita
algo más: «¿hay fuego, hacia dónde va, y por qué creo lo que creo?».

El gemelo digital es el **modelo lógico** de la vigilancia: hechos que reflejan su estado
y reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque aquí no se
promedia ni se compara con un umbral: se deduce, se justifica y se sabe decir «no lo sé».

## La vigilancia que se clona

Una sierra como la de los cañones de Tijuana, reducida a 4 cañones con 10 sensores, una
fuente satelital y dos lugares expuestos (una colonia al pie de un cañón y un rancho
junto a otro). El original tiene 40 sensores en 5 cañones; los cañones, sensores y
lugares de aquí son ejemplos de esta extensión.

| Parte | Contenido |
|---|---|
| Entidades | cañón → sensor; enlaces entre cañones colindantes; lugares expuestos; fuente satelital |
| Estado por sensor | temperatura, humo, humedad relativa, viento, combustible muerto (según tipo), instante, si calló |
| Estado por cañón | sus sensores, hacia dónde se abre, cañones colindantes y pendiente hacia cada uno |
| Fuentes externas | puntos de calor satelitales (hora de detección y de llegada); quemas autorizadas |
| Eventos | llega una lectura, un sensor calla o vuelve, llega un punto de calor, cambia el viento |
| Decisiones | ¿vigilar, confirmar o alertar?, ¿a quién?, ¿confío en esta fuente?, ¿hacia dónde avanza? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original; en varias, algún complemento (el registro de
quemas, los lugares expuestos, los rumbos) es de esta extensión. En cada una, tu gemelo
debe llegar a una decisión **y poder explicarla**.

### Situación 1 — Bandera roja, pero no en todos los cañones

- **Qué pasa.** Día de Santa Ana: humedad relativa de 10 % y viento de 60 km/h. La bandera
  roja pide humedad ≤ 15 % y viento ≥ ~40 km/h durante varias horas. Pero un cañón está al
  abrigo del viento, otro tiene un sensor de clima callado y solo uno mide la humedad del
  combustible muerto (bajo ~8-10 % el fuego se propaga con facilidad). Declarar riesgo
  extremo en todos lados dispersa la vigilancia; omitir el cañón peligroso deja nacer el
  primer fuego sin ojos encima.
- **Qué datos hay.** Humedad relativa y viento por sensor con su instante, humedad del
  combustible donde existe, hacia dónde se abre cada cañón. Ningún dato dice «riesgo».
- **Qué debe deducir.** El riesgo por cañón a partir de criterios que deben coincidir y
  durar; cuáles están a un solo criterio de entrar; y el combustible donde nadie lo mide.
  Lo intuitivo es que la lectura más extrema marca el cañón más riesgoso; es sospechoso
  porque una lectura aislada, o un viento que no entra al cañón, no sostienen el riesgo.
- **Qué debe contestar.** Por cañón: «en riesgo», «no» o «no lo sé», con los criterios que
  cumple, el que le falta y desde cuándo; y cuáles merecen vigilancia reforzada.
- **Por qué es lógica.** El riesgo nace de condiciones que coinciden en el tiempo, y un
  evento externo (el clima) cambia a la vez las reglas de todos los cañones.

### Situación 2 — Dos sensores dicen fuego, tres vecinos dicen que no

- **Qué pasa.** Dos sensores de un cañón reportan temperatura alta y humo; tres vecinos no
  ven nada anormal. Puede ser un incendio naciente, una fogata, una quema agrícola
  autorizada, un reflejo o polvo. Alertar pronto evacúa una colonia por nada y gasta la
  confianza; alertar tarde la deja sin tiempo. Quien pide esperar y quien pide actuar
  tienen razón.
- **Qué datos hay.** Lecturas con su instante, qué sensores son vecinos y de qué cañón, el
  registro de quemas autorizadas y el estado de los demás sensores.
- **Qué debe deducir.** Cuántas fuentes independientes coinciden y cuáles repiten la misma
  evidencia; qué vecinos podrían ver ese punto (cresta, rumbo, distancia) y cuáles no; y
  si una quema autorizada explica lo observado. Lo intuitivo es contar votos, tres contra
  dos; es sospechoso porque tres sensores que no ven ese punto no son tres votos en contra.
- **Qué debe contestar.** El nivel (vigilar, pedir confirmación, alertar) con las fuentes
  que cuentan y las que no, y a quién se le falla si se espera y a quién si se alerta.
- **Por qué es lógica.** Es un dilema: la regla decide y justifica a quién se le falla, y
  el peso de cada fuente depende de dónde está, no de cuántas hay.

### Situación 3 — El sensor que se calla

- **Qué pasa.** Un sensor deja de reportar en plena tarde de Santa Ana. Pudo quedarse sin
  batería o sin señal (LoRa o celular, lejos de la energía) o pudo destruirlo el fuego.
  Tomarlo por falla deja a la colonia sin aviso; tomarlo por quemado sin base dispara una
  evacuación por un sensor viejo.
- **Qué datos hay.** Sus últimas lecturas y su instante, los eventos de cuándo calló, los
  vecinos que sí reportan y qué otros sensores del cañón callaron.
- **Qué debe deducir.** Si el silencio es falla, destrucción o no se sabe, según cómo
  venían las lecturas, qué dicen los vecinos y si callaron varios a la vez. Lo intuitivo
  es que un sensor sin datos no aporta; es sospechoso porque callar tras subir la
  temperatura es evidencia, y callar junto con toda su red apunta a otra causa.
- **Qué debe contestar.** «Falla», «quemado» o «no lo sé», con la evidencia, y qué cambia
  en la alerta del cañón por ese silencio.
- **Por qué es lógica.** «No se cumple» y «no tengo cómo saberlo» no son lo mismo, y el
  silencio significa distinto según el contexto.

### Situación 4 — Hacia dónde y a qué hora llega

- **Qué pasa.** Hay un fuego confirmado en un cañón. Los cañones colindantes están
  enlazados por laderas de distinta pendiente (la velocidad se duplica aproximadamente
  cada 10°) y el viento de Santa Ana cambia de rumbo a media tarde. Con el avance mal
  estimado se avisa a la colonia equivocada y la amenazada se entera sin camino de salida.
- **Qué datos hay.** Origen del fuego, enlaces y pendientes entre cañones, viento con su
  rumbo en cada instante, sensores vivos y lugares expuestos de cada cañón.
- **Qué debe deducir.** Qué cañones y lugares son alcanzables y en qué orden, y cuáles ya
  no tienen sensor que confirme el avance. Cadena: viento → rumbo → pendiente → rapidez
  relativa → cañón siguiente → lugar expuesto. Lo intuitivo es que el lugar más cercano
  cae primero; es sospechoso porque uno más lejano, cuesta arriba y con viento a favor,
  puede llegar antes.
- **Qué debe contestar.** El orden probable de llegada, marcado como estimación y no como
  dato; a quién avisar primero si dos lugares compiten por una sola brigada; y qué cambia
  si el viento gira.
- **Por qué es lógica.** Es razonar sobre una red de cañones y cascadas de consecuencias;
  la misma estructura contesta «adónde» y «qué pasaría si».

### Situación 5 — El satélite y los sensores no coinciden

- **Qué pasa.** Un punto de calor satelital llega horas después de detectado, sobre un
  cañón sin sensores; el vecino, con sensores, no ve nada. En otro cañón no hay humo ni
  punto de calor, pero hay una quema autorizada vigente. Atender un punto viejo manda
  brigadas donde el fuego ya se movió; ignorarlo deja arder el cañón que nadie vigila.
- **Qué datos hay.** Puntos de calor con hora de detección y de llegada, cobertura de
  sensores por cañón, registro de quemas y lecturas de los cañones vecinos.
- **Qué debe deducir.** Qué tan vigente es cada punto, dónde puede estar el fuego ahora,
  qué cañón no tiene ojos propios y qué fuente pesa más según dónde y cuándo. Lo
  intuitivo es obedecer la fuente en tiempo real; es sospechoso porque sin sensor no hay
  tiempo real y «sin alerta» solo prueba que nadie mira.
- **Qué debe contestar.** Por cañón: hay fuego, no hay o no lo sé; a qué fuente se le creyó
  y por qué; y dónde falta vigilancia.
- **Por qué es lógica.** Dos sistemas con desfases distintos no se promedian: se razona
  sobre quién puede saber qué y cuándo.

## Por qué no basta un script

Con `if temperatura > UMBRAL and humo > UMBRAL: alertar()` resuelves un sensor con datos
perfectos. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué hago con el cañón 2? | decisión |
| ¿Por qué no se alertó a la colonia con dos sensores en alarma? | explicación |
| ¿Qué cañones están hoy en riesgo? | todas las respuestas |
| ¿Qué tendría que reportar el sensor 6 para confirmar el fuego? | la pregunta al revés |
| ¿Qué pasaría si el viento gira hacia el sur? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Cuántas fuentes deben coincidir para escalar una alerta, y de qué depende que una
   fuente cuente?
2. ¿Qué significa que un sensor dejó de reportar en medio de un incendio, y cómo lo
   distingue tu gemelo de una falla?
3. ¿Dónde queda escrito que un punto de calor viejo pesa menos que un sensor en vivo, y
   cuándo ocurre lo contrario?
4. ¿Cómo distingue tu gemelo «no hay fuego» de «no hay quién lo vea»?
5. ¿Qué parte de tu simulación en Erlang (sensores, evaluador de riesgo, estado de
   vigilancia a confirmado) podría alimentar a este gemelo con lecturas como hechos?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la vigilancia, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar lecturas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 4 cañones, 10 sensores y 2 lugares expuestos, contra los 40 sensores
  en 5 cañones del original.
- El «ahora» es un hecho del modelo, en minutos, no el reloj del sistema, para que las
  respuestas se puedan repetir.
- Los enlaces entre cañones, sus rumbos y pendientes, los lugares expuestos, el registro
  de quemas autorizadas, la cobertura de sensores y los identificadores de los ejemplos
  («cañón 2», «sensor 6») los defines tú; son complementos de esta extensión.
- Estos umbrales tampoco los da el original; son tuyos y los documentas: cuántas horas
  son «varias», cuántas fuentes bastan para alertar, qué distancia hace «vecino» a un
  sensor, cuánto silencio vuelve sospechoso a un sensor, qué tan viejo es un punto de
  calor para dejar de valer, y cuánto pesa el viento frente a la pendiente.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Rutas de evacuación y su saturación cuando dos colonias salen a la vez.
- Asignar brigadas, helicópteros y pipas a varios frentes con recursos limitados.
- Humo y calidad del aire en la ciudad aunque el fuego esté lejos.
- Coordinación con las autoridades del otro lado de la frontera.
- Reencendido de un incendio dado por controlado.

---
*Las cifras (humedad ≤ 15 % con viento ≥ ~40 km/h, velocidad que se duplica cada 10° de
pendiente, combustible por debajo de ~8-10 %, 40 sensores en 5 cañones, 10 % de humedad y
60 km/h) vienen del problema original; escalas, lugares y umbrales del escenario son de
esta extensión. Verifica la fuente vigente antes de citar.*
