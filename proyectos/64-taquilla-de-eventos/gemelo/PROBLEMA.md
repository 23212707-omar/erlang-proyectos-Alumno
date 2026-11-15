# #64 — Taquilla de eventos: gemelo digital con programación lógica

> Extensión del proyecto #64. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la taquilla: un inventario de asientos por evento, una
compra como máquina de estados (selección, bloqueada con timeout, pagada, expirada), una
sala de espera y una prueba de caos con miles de compradores contra pocos asientos. Esa
simulación responde «¿se vendió algo dos veces?». La taquilla necesita algo más: «¿a
quién le toca este asiento, por qué esta persona ya no puede comprar y qué boleto vale en
la puerta?».

El gemelo digital es el **modelo lógico** de la taquilla: hechos que reflejan sus
asientos, retenciones y boletos, y reglas que reflejan cómo se reparte, se limita y se
valida. Se escribe en Prolog porque lo difícil no es atender el pico, sino repartir sin
contradicciones, justificar a quién se le falla y saber decir «no lo sé».

## La taquilla que se clona

Un foro de Tijuana, reducido a 24 asientos en 3 zonas, con una venta que acaba de abrir.

| Parte | Contenido |
|---|---|
| Entidades | evento → zona → fila → asiento; cuentas de comprador; fila virtual por tandas; boletos; puertas |
| Estado por asiento | libre, retenido (por quién y desde cuándo), vendido o en duda |
| Estado por comprador | cuentas, tarjeta y dispositivo que usa, boletos pagados, retenciones vigentes, turno en la fila |
| Estado por boleto | asiento, titular, transferencias y escaneos en puerta |
| Eventos | se admite una tanda, llega una solicitud, se retiene, se paga o vence, la pasarela no contesta, el sistema cae, se transfiere un boleto, se escanea en una puerta |
| Decisiones | ¿a quién le toca el asiento?, ¿puede comprar más esta persona?, ¿se puede ofrecer este asiento?, ¿entra este boleto?, ¿cómo se reparte el lote? |

## Situaciones que tu gemelo debe razonar

Cuatro salen del problema original (sus casos difíciles, su escenario y sus datos del
mundo real); la 5 es derivada: plantea algo nuevo sobre asientos, sin cifras. Lo que
cada una añade se dice en su texto. En cada una, tu gemelo debe llegar a una decisión
**y poder explicarla**.

### Situación 1 — Dos personas, un mismo asiento

- **Qué pasa.** Abre la venta y Marisol y Beto piden el mismo asiento de platea en el
  mismo instante. Marisol esperó en una tanda anterior; Beto fue admitido después. Una
  tercera persona pide otro asiento de esa fila que alguien tiene retenido mientras
  paga. Si el gemelo se equivoca, hay dos personas con el mismo boleto o una fila
  virtual que se siente injusta.
- **Qué datos hay.** Asientos con zona, fila y número; retenciones con su inicio; turnos
  en la fila; solicitudes con su instante; el «ahora». Nadie guarda «asiento
  disponible» ni «quién ganó».
- **Qué debe deducir.** Qué asientos se pueden ofrecer en ese instante, qué solicitudes
  chocan y un reparto donde ningún asiento se asigna dos veces.
- **Qué debe contestar.** El reparto, a quién se le falló y con qué criterio de
  desempate; con «más soluciones», los demás repartos válidos; qué asiento equivalente
  se le puede ofrecer a quien perdió, o que no hay. Es un dilema: las dos partes tienen
  razón y la regla debe decidir y justificar.
- **Por qué es lógica.** La exclusividad es una restricción, y el desempate se declara
  una vez y vale para todos los choques.

### Situación 2 — El límite no se cuenta por cuenta

- **Qué pasa.** Los límites por persona intentan frenar la reventa, y el tráfico trae
  personas y también bots. Rubén tiene boletos pagados y retenciones en una cuenta y pide
  uno más. Otra cuenta con su misma tarjeta y dispositivo también retiene. Una tercera
  comparte solo la tarjeta, como una familia. Una retención vence sin pagarse. Si el
  gemelo se equivoca, un revendedor se lleva medio foro o una familia queda castigada.
- **Qué datos hay.** Cuentas con tarjeta y dispositivo, boletos pagados, retenciones con
  vigencia, solicitudes y el límite. Ningún dato dice «misma persona» ni «cuántos lleva».
- **Qué debe deducir.** Qué cuentas son probablemente un solo comprador, cuántos boletos
  le cuentan, cuántos le quedan y si la solicitud cabe: de indicios a comprador, de
  comprador a acumulado, de acumulado a margen y de margen a elegibilidad.
- **Qué debe contestar.** «Puede», «no puede» o «no se sabe» (si los indicios no alcanzan
  para unir dos cuentas), con las cuentas y boletos que lo sustentan y qué tendría que
  cambiar para poder comprar. Lo intuitivo es que el límite es por cuenta; es sospechoso
  porque es justo lo que explota un revendedor.
- **Por qué es lógica.** La identidad no se mide, se deduce de varios indicios, y «no es
  la misma persona» no es lo mismo que «no puedo saberlo».

### Situación 3 — Retención vencida, ¿asiento libre?

- **Qué pasa.** Mientras un usuario paga, su asiento está retenido; si no paga, vuelve al
  inventario, y una parte de las retenciones nunca se paga. Una retención vence cuando la
  pasarela no ha contestado: quizá pagó y la confirmación se perdió. Además el sistema
  cayó con retenciones activas y no es seguro cuáles seguían vivas. Otra persona pide ese
  asiento. Venderlo habiendo pagado el primero es sobreventa; dejarlo ocupado sin pago
  es una venta perdida.
- **Qué datos hay.** Eventos de retención, pago, vencimiento, silencio de la pasarela y
  caída, cada uno con su instante; el «ahora». Nadie guarda el estado real del asiento.
- **Qué debe deducir.** Si cada asiento está vendido, retenido, libre o en duda, si se
  puede ofrecer sin riesgo y cuántos quedaron en duda tras la caída: de eventos y reloj a
  estado, de estado a vendible y de vendible al conteo.
- **Qué debe contestar.** Por asiento, «se puede vender», «no» o «no se sabe», con el
  evento que lo sostiene y qué tendría que llegar para decidir. Lo intuitivo es liberar
  al vencer el tiempo; es sospechoso porque la pasarela pudo cobrar. Veredicto esperado:
  un asiento sin respuesta no se ofrece. Hipótesis: qué cambia si la confirmación llega
  después de una reventa.
- **Por qué es lógica.** Sobreventa cero exige distinguir «libre» de «no sé si está
  libre», y ese estado se deduce de una historia, no se lee de un campo.

### Situación 4 — Un boleto, dos puertas

- **Qué pasa.** Un boleto digital debe validarse en la puerta y no puede funcionar
  duplicado, pero un QR copiado aparece en dos puertas. El mismo boleto se escanea en la
  puerta A y poco después en la B. Una tercera puerta estuvo sin conexión un rato, y el
  titular pudo transferir el boleto a un amigo. Si el gemelo se equivoca, entra un
  impostor o se le niega la entrada a quien pagó.
- **Qué datos hay.** Boletos con asiento y titular, transferencias con su instante,
  escaneos con puerta e instante, y los periodos de conexión de cada puerta.
- **Qué debe deducir.** El titular vigente, si los escaneos pueden ser de una sola
  persona, si algún escaneo pudo perderse y si el boleto está comprometido.
- **Qué debe contestar.** Por escaneo, «entra», «no entra» o «no se sabe», con la
  evidencia. Lo intuitivo es que el primero en entrar es el legítimo; es sospechoso
  porque copiar un QR no deja huella de orden. Veredicto esperado: no se declara impostor
  a nadie por llegar después; el boleto queda comprometido y se dice qué falta verificar.
- **Por qué es lógica.** Es un conflicto entre dos evidencias que no se resuelve con un
  número, y que una puerta no reporte no significa que no hubo escaneo.

### Situación 5 — Los últimos asientos juntos

- **Qué pasa.** Los mejores asientos se agotan en segundos. En la mejor zona quedan pocos
  libres, en tramos. Llega un lote: un grupo de cuatro que quiere sentarse junto, una
  pareja, alguien solo y un comprador ya en su límite. Hay retenciones que quizá venzan.
  Si el gemelo se equivoca, un grupo se queda sin lugar o se desperdicia un tramo útil.
- **Qué datos hay.** Asientos libres, retenidos y vendidos por zona, fila y número;
  solicitudes con cantidad y si piden juntas; el límite; el «ahora». Nadie guarda «tramo».
- **Qué debe deducir.** Qué tramos contiguos hay, qué solicitudes caben y dónde, y una
  combinación que sirva al lote sin romper límites ni exclusividad. Una solicitud
  rechazada por límite no debe ocupar tramo.
- **Qué debe contestar.** El reparto completo y, al pedir más soluciones, los demás
  válidos; si el grupo no cabe junto, por qué y qué alternativa hay; qué retención tendría
  que vencer para que quepa. Lo intuitivo es asignar por orden de llegada; es sospechoso
  porque puede dejar tramos inservibles. Qué pesa más, llegada o asientos vendidos, lo
  decides y declaras tú.
- **Por qué es lógica.** Repartir un recurso escaso con restricciones es buscar, y las
  alternativas y la causa del «no cabe» salen de la misma búsqueda.

## Por qué no basta un script

Con `if asiento.libre: vender()` resuelves un asiento sin competencia y con pagos que
siempre responden. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué hago con la solicitud 7? | decisión |
| ¿Por qué no le tocó el asiento a Beto? | explicación |
| ¿Qué asientos puede comprar hoy esta persona? | todas las respuestas |
| ¿Qué tendría que pasar para que le toquen cuatro juntos? | la pregunta al revés |
| ¿Qué pasaría si el 30 % de las retenciones no se paga? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para saber si un asiento se puede vender, y cuáles **no**
   deberías guardar?
2. Cuando dos solicitudes tienen razón, ¿dónde queda escrito a cuál se le falla?
3. ¿Cómo distingue tu gemelo «el asiento está libre» de «no sé si está libre»?
4. ¿Qué cuenta contra el límite de una persona y cómo decide quién es esa persona?
5. En Erlang un proceso por evento serializa el inventario y la prueba de caos exige cero
   sobreventa. ¿Qué garantiza ese proceso que tu gemelo no, y qué explica tu gemelo que el
   proceso no puede?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la taquilla, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar solicitudes simuladas
  o graficar la ocupación.

## Supuestos de esta extensión

- Escala reducida: 24 asientos en 3 zonas, una docena de cuentas y 3 puertas, contra los
  20,000 asientos y 100,000 usuarios del escenario original (que menciona dos puertas).
- Los nombres, ids de asiento, cuentas, tandas y cantidades de los ejemplos son del
  ejercicio. «Contiguo» significa misma fila y números consecutivos.
- El «ahora» es un hecho del modelo, en segundos desde que abre la venta, no el reloj del
  sistema, para que las respuestas se puedan repetir. «Al mismo tiempo» se representa con
  el mismo instante.
- Tú defines, dentro de lo que el original da: el límite exacto dentro de 4-6 boletos y
  los minutos de retención dentro de 3-10. Y sin cifra en el original: cuánto esperar a
  una pasarela muda, qué indicios unen dos cuentas, el criterio de desempate, el tiempo
  mínimo para ir de una puerta a otra y qué se hace con un boleto comprometido.
  Decláralos como supuestos.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Reventa autorizada: transferir un boleto con trazabilidad y sin saltarse el límite.
- Asientos para accesibilidad y su liberación si nadie los usa.
- Paquetes de varias funciones con un solo límite.
- Cancelación del evento y orden de los reembolsos.
- Patrones de bots en la fila virtual.

---
*Las cifras de dominio (límite de 4-6 boletos, retención de 3-10 min, 30 % de retenciones
que no se pagan, 20,000 asientos y 100,000 usuarios, QR en dos puertas) son de referencia
y vienen del problema original. Verifica la fuente vigente antes de citarlas en tu
entrega. La escala del foro y los números de los ejemplos son del ejercicio.*
