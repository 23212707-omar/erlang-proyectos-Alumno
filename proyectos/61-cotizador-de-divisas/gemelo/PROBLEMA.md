# #61 — Cotizador de divisas: gemelo digital con programación lógica

> Extensión del proyecto #61. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el cotizador: fuentes que se consultan cada 30 segundos,
un histórico, alertas de usuarios y una fuente que se cae. Esa simulación responde
«¿cuál fue el último valor y a quién le toca un aviso?». Quien opera el cotizador necesita
algo más: «¿qué cotización puedo llamar actual, a quién le debo un aviso y qué le digo a
quien reclama?».

El gemelo digital es el **modelo lógico** del cotizador: hechos que reflejan su estado y
reglas que reflejan cómo se decide en él. Se escribe en Prolog porque lo difícil aquí no
es calcular un número, sino decidir qué dato es creíble, qué alerta le toca a quién y
poder justificarlo ante el usuario.

## El cotizador que se clona

El cotizador peso/dólar de una casa de cambio de Tijuana, reducido a 2 fuentes de mercado,
el FIX de Banxico, 3 casas de cambio, 6 usuarios y 8 alertas.

| Parte | Contenido |
|---|---|
| Entidades | fuentes (2 de mercado y el FIX); casas de cambio; usuarios → alertas |
| Estado por cotización | valor (pesos por dólar), fuente, instante en que se tomó |
| Estado por casa | precio de compra, precio de venta e instante en que los publicó |
| Estado por alerta | de quién es, sobre qué fuente, condición (baja de o sube de un umbral) e historia: cruces, avisos enviados, confirmaciones |
| Estado del sistema | si el mercado está abierto o cerrado, si cada fuente responde, cuántas consultas lleva gastadas de su límite |
| Eventos | llega una cotización, una fuente cae o vuelve, el mercado abre o cierra, se envía o se confirma un aviso, una casa publica |
| Decisiones | ¿cuál es la cotización actual?, ¿avisar?, ¿consultar la fuente?, ¿creerle a esta casa?, ¿qué decirle al usuario? |

## Situaciones que tu gemelo debe razonar

Cuatro salen del problema original (1, 2, 3 y 5); la 4 usa sus datos del mundo real
(compra y venta separadas, diferencial o *spread*) para plantear algo que el original no
pide: decidir qué ofertas de casas de cambio son creíbles y cuál conviene. En cada una,
tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — ¿Cuál es la cotización «actual»?

- **Qué pasa.** Dos fuentes dan valores distintos. Una trae minutos u horas de retraso y a
  veces devuelve un valor absurdo (un cero o un 1700). El sábado el mercado está cerrado
  y el último valor del viernes sigue vigente hasta el lunes. El FIX se publica cerca de
  las 12:00, solo en días hábiles. Quien cambia dólares con un valor viejo presentado
  como actual pierde dinero.
- **Qué datos hay.** Cada cotización con su fuente y su instante, lo que se considera
  plausible, y si el mercado está abierto o cerrado y desde cuándo. Ningún dato dice
  «esta es la actual» ni «esta fuente va atrasada».
- **Qué debe deducir.** Qué cotización está vigente según su fuente, su edad frente al
  estado del mercado, su plausibilidad y lo que diga la otra fuente; y cuándo esas razones
  no alcanzan para escoger entre dos.
- **Qué debe contestar.** Tres respuestas: la vigente, con su fuente y su edad; la
  obsoleta, marcada como tal; y «no lo sé» cuando dos fuentes discrepan y ninguna se
  puede descartar. Lo intuitivo es «la más reciente»; sospéchalo: la más reciente puede
  ser el cero, y la del viernes puede ser la correcta un sábado.
- **Por qué es lógica.** «Actual» no es un dato, es una conclusión que depende del
  contexto: la misma edad es atraso un martes al mediodía y es vigencia un sábado.

### Situación 2 — La alerta que rebota

- **Qué pasa.** Ana pidió «avísame cuando baje de 17.50». El precio cruza hacia abajo,
  sube, vuelve a bajar, varias veces en pocos minutos. Si avisas cada cruce, Ana recibe
  cien mensajes y deja de creerte; si avisas una vez y callas para siempre, se pierde la
  caída real de horas después. Y un cero espurio «baja» de cualquier umbral.
- **Qué datos hay.** Las alertas con su condición, su umbral y su fuente; las
  cotizaciones con su instante; la historia de cada alerta: avisos enviados y
  confirmados. Ningún dato dice «ya avisé» ni «esta alerta está armada».
- **Qué debe deducir.** Si hubo un cruce de verdad (con una cotización vigente, no con el
  cero); si la alerta estaba armada o ya había avisado y no se ha rearmado; y por tanto si
  este cruce es un aviso nuevo, un rebote del anterior o ninguno de los dos.
- **Qué debe contestar.** Si se avisa o no, con las razones. Cuando el precio está bajo el
  umbral y la respuesta es «no avisar», la explicación debe ser tan clara como la de «sí».
- **Por qué es lógica.** «Ya avisé» es una conclusión de la historia, no un campo que
  alguien actualiza. Encadena la cotización vigente, el cruce, el estado de la alerta y
  el aviso: si falla un eslabón, cambia la decisión.

### Situación 3 — El salto del 2 % y la cuota de la fuente

- **Qué pasa.** En diez minutos el dólar se mueve 2 %, cuando en un día normal se mueve
  entre 0.5 y 1 %. Muchas alertas cruzan a la vez y muchos usuarios consultan. Las APIs
  públicas limitan las peticiones al mes. Si consultas la fuente a cada rato, te quedas
  sin cuota antes de fin de mes; si no, sirves precios viejos justo cuando más importan.
  Una fuente tiene casi agotada su cuota y la otra va atrasada.
- **Qué datos hay.** Cotizaciones con su instante, la cuota gastada y el límite de cada
  fuente, cuánto falta para que el periodo se reinicie y cuántas alertas están cerca de
  cruzar. Ningún dato dice «hay un salto».
- **Qué debe deducir.** Si hay un movimiento brusco; cuánto vale ahora una consulta
  nueva; qué fuente conviene gastar, si alguna; y con qué etiqueta se sirve lo guardado.
- **Qué debe contestar.** Consultar tal fuente, o no consultar y servir lo guardado
  marcado como atrasado, con la regla que decidió y qué tendría que cambiar para decidir
  otra cosa. Es un dilema: a quien consulta hoy durante el salto o a quien consultará el
  resto del mes sin cuota, a alguien se le falla.
- **Por qué es lógica.** Un evento externo cambia varias reglas a la vez (cuánta edad se
  tolera, cuánta urgencia hay, cuánto cuesta gastar cuota), y esos cambios no deben
  reescribirse una regla por una.

### Situación 4 — La casa de cambio que paga más

- **Qué pasa.** Las casas publican precio de compra y de venta, y la diferencia es su
  *spread*, típicamente de 0.10 a 0.40 pesos. Alguien quiere vender dólares y ve que una
  casa paga más que las demás. Pero esa oferta se publicó hace horas, mientras el
  mercado saltó; o su compra quedó por encima de su venta (un error de captura); o su spread es
  muy distinto del de las otras. Quien llega con ese precio puede toparse con otro en
  el mostrador.
- **Qué datos hay.** Las ofertas con su compra, su venta y su instante; la cotización
  vigente de la situación 1; y si el usuario compra o vende dólares. Ningún dato dice
  «esta oferta es creíble».
- **Qué debe deducir.** Qué ofertas son creíbles hoy, qué spread es normal en el
  contexto (en un salto, ensancharse es esperable) y cuál conviene al usuario según su
  lado; si dos empatan, cuál gana y por qué.
- **Qué debe contestar.** La oferta recomendada con sus razones, las descartadas con la
  razón de cada una, y «no lo sé» si ninguna se puede avalar. Lo intuitivo es «la que
  paga más»; aquí puede estar mal. El dilema: la oferta fresca pero peor contra la vieja
  pero mejor; recomendar la vieja puede costarle un viaje inútil al usuario, descartarla
  injustamente le falla a la casa.
- **Por qué es lógica.** Primero la elegibilidad, después el orden; el «mejor» depende
  del lado, y el desempate se declara una vez en vez de decidirse caso por caso.

### Situación 5 — «No me avisaron»

- **Qué pasa.** Un usuario reclama que su alerta debió sonar anoche y no le llegó. En la
  noche una fuente se cayó, la otra devolvió un cero, y hay un aviso enviado sin
  confirmación de entrega. Su alerta pudo estar pausada o ligada al FIX, que no sale en
  fin de semana. Un aviso perdido es dinero para el usuario y confianza para ti.
- **Qué datos hay.** Los eventos de la alerta con su instante, las cotizaciones y el
  estado de las fuentes en esa ventana, y si cada aviso se envió, se confirmó o falló.
- **Qué debe deducir.** Si, con lo que se sabía **en aquel momento**, la alerta debió
  sonar; y si debió y no sonó, por qué; si salió pero no se sabe si llegó.
- **Qué debe contestar.** «Debió avisar y no lo hizo», «no debía avisar», con la razón,
  o «avisó y no sé si llegó». Y qué se hace ahora: reenviar tiene el riesgo de duplicar.
- **Por qué es lógica.** Rendir cuentas es repetir la deducción con el «ahora» de
  entonces, no el de hoy. Y «no sé» no es una excusa: es un resultado que se informa.

## Por qué no basta un script

Con `if precio < 17.50: avisar(usuario)` resuelves una alerta con una fuente que nunca
falla y un precio que nunca rebota. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Le aviso a Ana ahora? | decisión |
| ¿Por qué no se avisó anoche al usuario 3? | explicación |
| ¿Qué alertas se disparan con la cotización vigente? | todas las respuestas |
| ¿Qué tendría que pasar para que la alerta 4 vuelva a sonar? | la pregunta al revés |
| ¿Qué pasaría si la fuente B también se cae? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir una cotización en un instante, además de su valor?
2. ¿Qué significa «cotización actual» cuando una fuente está caída y la otra discrepa?
3. ¿Cómo evitas que una alerta se dispare cien veces por un valor que oscila, sin perder
   la caída real que viene después?
4. ¿Cómo distingue tu gemelo «no debía avisar» de «no sé si debía avisar»?
5. En Erlang el cotizador, el histórico y el evaluador de alertas son procesos
   supervisados. ¿Qué de eso podría alimentar a este gemelo, y qué decide el gemelo que
   un proceso no puede?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del cotizador, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar cotizaciones simuladas
  o graficar el histórico.

## Supuestos de esta extensión

- Escala reducida: 2 fuentes de mercado (como el original) más el FIX, 3 casas de cambio,
  6 usuarios y 8 alertas, contra las 5,000 alertas y las 300 consultas por segundo del
  escenario original. Las casas y los usuarios son del ejercicio, no negocios reales.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir. El retraso de una fuente, un valor absurdo o una consulta que falla
  entran como hechos; las reglas no sortean nada.
- Los números de los ejemplos («alerta 4», «usuario 3») y la cuota de las fuentes en tu
  escenario son del ejercicio, no estadísticas. Qué días son hábiles también lo fijas tú.
- Tú defines, y lo declaras como supuesto: qué valores son plausibles, cuánta edad vuelve
  obsoleta una cotización con el mercado abierto, qué salto es «brusco», cuánto debe
  alejarse el precio del umbral para rearmar una alerta, cuánto silencio vuelve dudoso un
  aviso, qué spread es sospechoso en calma y en un salto, cuánta cuota se reserva y cómo
  se desempata. El original no da esas cifras.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Alertas compuestas: «avísame si baja de un umbral y el spread de alguna casa es menor
  que otro».
- Precio de la casa según el monto que se quiere cambiar.
- Alertas con horario de no molestar y vigencia.
- Otras divisas (euro, yuan) con su propia lista de fuentes.

---
*Las cifras de dominio (FIX a las 12:00, 16 a 21 pesos, 0.5 a 1 % y 2 %, spread de 0.10 a
0.40, consulta cada 30 s, 17.50, un cero o un 1700) vienen del problema original; la
escala y los ejemplos son del ejercicio. Verifica la fuente vigente antes de citarlas en
tu entrega.*
