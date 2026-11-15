# #14 — Acortador de URLs: gemelo digital con programación lógica

> Extensión del proyecto #14. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el acortador: un generador de códigos, una tabla de
código a URL, un contador de visitas, una ráfaga contra un solo enlace. Esa simulación
responde «¿aguanta?». Quien administra el servicio necesita algo más: «¿a quién le doy
este alias, qué hago con este reporte, y qué puedo afirmar de lo que pasó?».

El gemelo digital es el **modelo lógico** del acortador: hechos que reflejan su estado
y reglas que reflejan cómo se decide en él. Se escribe en Prolog porque aquí lo difícil
no es redirigir rápido, sino decidir quién puede qué, justificarlo y saber cuándo un
dato no alcanza para afirmar nada.

## El acortador que se clona

El servicio del problema original, reducido a unos cuantos usuarios y enlaces. Los
ejemplos (una taquería, un gimnasio, un banco falso) son ilustrativos del ejercicio.

| Parte | Contenido |
|---|---|
| Entidades | usuarios (anónimo, registrado, moderador); enlaces con su destino y su tipo de redirección (301 o 302); alias; dominios de destino; reportes |
| Estado por enlace | dueño, destino, alias que apuntan a él, tipo de redirección, vigencia, si está activo, bloqueado o vencido, y cuándo se validó el destino |
| Estado por alias | libre, ocupado, reservado o vencido; qué enlace tuvo y hasta cuándo |
| Eventos | se pide un alta (con o sin alias), se crea, se visita, se reporta, se bloquea, se valida un destino, vence un enlace, se reinicia el contador |
| Decisiones | ¿se acepta esta URL?, ¿a quién se le da el alias?, ¿se bloquea?, ¿se puede reasignar un alias?, ¿qué se puede afirmar de las visitas? |

## Situaciones que tu gemelo debe razonar

Las tres primeras salen del problema original (casos difíciles y escenario); la 4 y la
5 son derivadas: usan datos del original (expiración, alias, 301, validar destinos), pero
el original no las plantea. En cada una, tu gemelo debe decidir **y poder explicarlo**.

### Situación 1 — Dos personas, un mismo alias

- **Qué pasa.** Una taquería y un gimnasio piden `promo` en el mismo segundo para
  imprimirlo en carteles. El servidor registró primero a uno, pero el reloj de la otra
  petición dice lo contrario. Ambos tienen razón, y a quien pierda le toca reimprimir.
- **Qué datos hay.** Las peticiones con su alias y su segundo, el tipo de cuenta de cada
  solicitante y sus enlaces vivos, los alias ocupados, reservados o vencidos.
- **Qué debe deducir.** Si el alias estaba realmente disponible en ese instante; quién
  lo obtiene cuando el instante no desempata; y qué alternativas son válidas para quien
  no lo obtiene.
- **Qué debe contestar.** A quién se le asigna, qué desempate lo decidió, a quién se le
  falla, los alias alternativos que sí puede ofrecerle y qué tendría que cambiar para
  que el otro ganara.
- **Por qué es lógica.** El desempate se declara una vez y sirve para «¿puedo tomar
  este alias?», «¿por qué no?» y «¿cuáles sí?».

### Situación 2 — Reportado no es lo mismo que inaccesible

- **Qué pasa.** Alguien reporta que un enlace lleva a un banco falso. La dueña asegura
  que es su sitio y que la reporta un competidor. Cada minuto de espera puede costarle
  dinero a una víctima; cada minuto de bloqueo injusto, ventas y reputación a la dueña.
  Hay otros alias hacia el mismo destino, y el enlace se creó con 301 hace días.
- **Qué datos hay.** Los reportes (quién, con qué rol, cuándo), el destino y su
  dominio, los demás enlaces del mismo dueño y del mismo dominio, el tipo de redirección
  y las visitas anteriores. Ningún dato dice «sigue llegando gente al destino».
- **Qué debe deducir.** En cadena: el reporte lo vuelve sospechoso; el bloqueo alcanza a
  los alias que comparten destino; una redirección 301 ya está guardada en los
  navegadores de quienes la visitaron; esos visitantes siguen llegando sin pasar por el
  acortador; luego el bloqueo no cubre a todos.
- **Qué debe contestar.** Bloquear, vigilar o pedir más evidencia, con la razón; qué
  otros enlaces arrastra; a quién se le falla si el reporte resulta falso; y qué parte
  del daño ya no se puede detener desde el servidor.
- **Por qué es lógica.** Lo intuitivo es «bloqueado, luego ya nadie llega», y es falso.
  Dos partes con razón obligan a que la regla decida y justifique a quién se le falla.

### Situación 3 — Las visitas que nadie contó

- **Qué pasa.** Una agencia pagó una campaña y cobra por visita. El contador del enlace
  dice una cifra; el registro de visitas individuales, otra. El contador se reinició a
  media ráfaga, y el enlace pasó de 302 a 301 durante la campaña. Una cifra de visitas
  estable puede significar que el enlace dejó de ser popular o que dejó de ser contado.
- **Qué datos hay.** Las lecturas del contador con su instante, los registros de visita,
  los cambios de tipo de redirección, los reinicios y el rango posible del contador.
- **Qué debe deducir.** Para cada tramo, si las visitas se contaron completas, pudieron
  contarse de menos o hay un hueco; y si contador y registro son compatibles entre sí o
  uno de los dos no pudo ocurrir (por ejemplo, un contador que baja sin reinicio).
- **Qué debe contestar.** Tres respuestas: lo que se puede afirmar, lo que se descarta
  y lo que no se sabe; qué tramos son dudosos; y qué dato sacaría de la duda.
- **Por qué es lógica.** «No registré más visitas» no es «no hubo más visitas», y dos
  fuentes que se contradicen no se promedian: se razona cuál historia es posible.

### Situación 4 — El alias libre que no lo está

- **Qué pasa.** El alias de una campaña venció y alguien nuevo lo pide. El sistema lo ve
  libre. Pero se creó con 301, hay carteles impresos, siguen llegando visitas después de
  vencer, y el destino anterior se marcó después como malicioso. Reasignarlo manda a
  quien escanee el cartel a un sitio ajeno; negarlo deja sin alias a quien lo pidió.
- **Qué datos hay.** Los eventos de vida del alias y del enlace, el tipo de redirección,
  las visitas posteriores al vencimiento, el historial del destino anterior y quién
  pide el alias hoy.
- **Qué debe deducir.** Si el alias, libre en el sistema, lo está también en el mundo, y
  quién resultaría perjudicado según a quién se le dé.
- **Qué debe contestar.** Reasignar, retener o negar, con la razón; cuándo podría
  asignarse; y qué evidencia cambiaría la respuesta.
- **Por qué es lógica.** La respuesta correcta contradice «venció, luego está libre», y
  se llega a ella encadenando hechos que nadie midió juntos.

### Situación 5 — «Lo validé ayer»

- **Qué pasa.** Llega una tanda de URLs por acortar. Una está bien escrita pero apunta a
  otro acortador; otra imita el dominio de un banco; otra se validó ayer y su contenido
  pudo cambiar; otra pertenece a un dominio que apareció en la lista de bloqueo, que
  hace tiempo no se actualiza. Aceptar una maliciosa daña al público; rechazar una
  legítima deja a un negocio sin su campaña.
- **Qué datos hay.** Las URLs y sus dominios, las cadenas de redirección conocidas, las
  validaciones anteriores con su instante, la lista de bloqueo y cuándo se actualizó.
- **Qué debe deducir.** Si cada URL es aceptable, no aceptable o no se sabe, y si una
  validación vieja o una lista desactualizada bastan para afirmar algo.
- **Qué debe contestar.** El veredicto de cada URL con su evidencia, qué falta para
  decidir las dudosas y qué cambiaría si la lista se actualizara hoy.
- **Por qué es lógica.** «No está en la lista» no es «es segura», y «validada» tiene una
  vigencia que se razona, no se supone.

## Por qué no basta un script

Con `if alias not in tabla: guardar(alias, url)` resuelves un alta sin competidores, sin
alias reservados y sin que nada se cachee. Tu gemelo debe contestar, **con las mismas
reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Se le da `promo` a la taquería? | decisión |
| ¿Por qué sigue llegando gente a un enlace bloqueado? | explicación |
| ¿Qué alias puede ofrecerle al gimnasio? | todas las respuestas |
| ¿Qué tendría que ser cierto para reasignar el alias vencido? | la pregunta al revés |
| ¿Qué pasaría si el enlace se hubiera creado con 302? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir un alias y su historia en un instante?
2. Si «libre» no se guarda, ¿de qué hechos se deduce?
3. Cuando dos partes tienen razón sobre el mismo alias, ¿dónde queda escrito quién gana?
4. ¿Cómo distingue tu gemelo «no hubo más visitas» de «no sé si las hubo»?
5. En Erlang tuviste un generador de códigos, una tabla ETS y un contador. ¿Qué de eso
   podría alimentar a este gemelo, y qué decide el gemelo que un proceso no puede?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del acortador, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar visitas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: unos 5 usuarios, 8 enlaces y unas pocas decenas de visitas, contra el
  millón de enlaces, las 500 redirecciones por segundo y la ráfaga de 5,000 del original.
- Son ejemplos del ejercicio, no hechos del mundo: la taquería, el gimnasio, el banco
  falso, el alias `promo` y las cantidades que aparecen en ellos.
- El «ahora» es un hecho del modelo, en segundos, no el reloj del sistema, para que las
  respuestas se puedan repetir.
- Tú defines y declaras como supuesto: el desempate entre peticiones; qué alias son
  reservados o demasiado parecidos a otro; cuánto debe esperar un alias vencido antes de
  reasignarse; cuánto pesa un reporte según quién lo hace; cuánto dura una validación
  de destino; cuánto tiempo sin actualizar vuelve dudosa a la lista de bloqueo; y
  cuánta diferencia entre contador y registro se tolera.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Cuotas de enlaces por usuario y planes según el tipo de cuenta.
- Reportes coordinados para tumbar un enlace legítimo.
- Transferir un alias de un dueño a otro.

---
*Las cifras (7 caracteres en base62, relación 100:1, 301 y 302, ráfaga de 5,000, colisiones
tras unos 2 millones de ids) son de referencia y vienen del problema original. Verifica la
fuente vigente antes de citarlas en tu entrega.*
