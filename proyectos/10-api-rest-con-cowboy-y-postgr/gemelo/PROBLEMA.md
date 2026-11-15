# #10 — API REST con cowboy y PostgreSQL: gemelo digital con programación lógica

> Extensión del proyecto #10. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang construiste una API con pool de conexiones y un supervisor que la
protege cuando la base cae. Esa simulación responde «¿aguanta?». Quien reparte algo
escaso por esa API necesita algo más: «¿a quién se le acepta esta petición y por qué?».

El gemelo digital es el **modelo lógico** de la operación: hechos que reflejan su estado
y reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque aquí no se
trata de servir rápido, sino de **autorizar, validar, desempatar y justificar** cada
respuesta ante quien la recibe.

## La operación que se clona

«Despensa Frontera» es un banco de alimentos de Tijuana que reparte por una API a las
organizaciones afiliadas. **No existe: es un escenario planteado por esta extensión**;
el original solo pide un dominio acotado, y aquí es el inventario del banco. Se reduce
a 5 organizaciones, 6 delegados y 4 productos.

| Parte | Contenido |
|---|---|
| Entidades | organizaciones afiliadas (comedor, escuela, albergue, parroquia) y sus delegados con credencial; productos con existencia, caducidad y si son refrigerados; peticiones (consultar, apartar, cancelar) |
| Personas | la coordinadora de bodega (prepara pedidos), el director (autoriza excepciones y declara emergencias), los delegados de cada organización, y el auditor del donante que revisa a quién se le entregó lo donado |
| Estado por organización | convenio y su vigencia, informe del mes anterior, cupo mensual por producto, cámara fría declarada y cuándo se verificó, emergencia declarada, excepciones escritas |
| Estado por petición | quién la envía, a qué organización, clave, contenido, en qué nodo y en qué instante llegó, y qué se le contestó |
| Eventos | llega, se acepta o se rechaza una petición; se prepara un pedido; se captura una baja; se declara una emergencia; la base cae y regresa |
| Decisiones | ¿se acepta esta petición?, ¿es nueva o un reintento?, ¿a quién se le da la última unidad?, ¿qué se puede atender con la base caída?, ¿fue legítimo lo que pasó? |
| Reglamento (inventado) | (a) aparta solo una persona delegada con credencial vigente; la credencial es de la persona y su organización avisa las bajas «sin demora»; (b) la organización necesita convenio vigente y estar al corriente: entregar su informe de reparto del mes anterior antes del día 5, o queda suspendida hasta entregarlo, salvo excepción escrita de dirección con vigencia propia; (c) cada organización tiene un cupo mensual por producto, y una cancelación devuelve cupo si la bodega aún no preparó el pedido; (d) los refrigerados solo van a organizaciones con cámara fría declarada y verificada en visita durante el último año; (e) cada apartado lleva una clave que genera la aplicación del delegado, y dos peticiones con la misma clave son la misma petición (la versión vieja de la aplicación no manda clave); (f) entre organizaciones elegibles, la existencia se entrega por orden de llegada; (g) una organización con emergencia declarada se atiende primero, en lo que no pueda cubrirse con otro producto de la bodega |

## Situaciones que tu gemelo debe razonar

Las cinco las plantea esta extensión. La 2, la 3 y la 4 retoman casos del problema
original (la última unidad, el reintento del cliente, la base que se reinicia 20
segundos); la 1 y la 5 son nuevas. En cada una, tu gemelo debe llegar a una decisión
**y poder explicarla**.

### Situación 1 — Tiene credencial, ¿y entonces?

- **Qué pasa.** Iván, delegado de un comedor, pide 12 cajas de pollo congelado para el
  desayuno de mañana. Su credencial funciona y el cupo parece alcanzar. Pero el comedor
  entregó tarde su informe del mes pasado, su excepción de dirección venció y su cámara
  fría se verificó hace casi un año. Si se acepta mal, el donante puede retirar el
  pollo; si se rechaza mal, 300 personas se quedan sin desayuno.
- **Qué datos hay.** Credenciales, convenios, informes, excepciones, cupo, lo apartado y
  cancelado, verificaciones. Ningún dato dice «esta organización puede pedir».
- **Qué debe deducir.** En cadena: la credencial es de Iván, luego su organización es el
  comedor, luego su convenio e informe dicen si está al corriente, luego el cupo efectivo,
  luego si la cámara fría sigue vigente, y de ahí si la petición es elegible.
- **Qué debe contestar.** Aceptar, rechazar o aceptar parcial, con cada condición que
  falla y qué trámite la arreglaría.
- **Por qué es lógica.** Una credencial válida no basta: la elegibilidad se concluye de
  varios hechos de distintas personas y fechas.

### Situación 2 — La última caja, dos organizaciones

- **Qué pasa.** Queda una caja de pollo y dos peticiones llegan casi a la vez. Una
  parroquia está al corriente y dentro de cupo, y llegó 40 milisegundos antes según el
  reloj de su nodo. Un albergue tiene emergencia declarada (llegaron 80 personas esta
  semana), pero su verificación de cámara fría venció hace un mes y su cupo de pollo se
  agotó. Los relojes de los dos nodos de la API no coinciden del todo. Quien pierda
  tiene razón en reclamar.
- **Qué datos hay.** Peticiones con nodo e instante, desfase entre nodos (o su ausencia),
  emergencia, verificaciones, cupo y productos sustitutos.
- **Qué debe deducir.** Quién es elegible; si el orden de llegada se puede establecer; si
  una emergencia alcanza a cubrir una verificación vencida; y si el albergue puede
  cubrir su necesidad con otro producto.
- **Qué debe contestar.** A quién se le da la caja, qué regla cedió, a quién se le falla
  y qué le cuesta, y qué tendría que ser cierto para que la decisión fuera la contraria.
- **Por qué es lógica.** Las prioridades se declaran una vez, y «no se sabe quién llegó
  primero» es un resultado válido.

### Situación 3 — Tres veces el mismo pedido, o no

- **Qué pasa.** La delegada de una escuela aparta 40 cajas de arroz desde un teléfono con
  mala señal. A las 10:00:00 sale la petición con la clave K1; la base se reinicia justo
  entonces y ella reintenta con K1. Medio minuto después sale otra idéntica, sin clave
  (aplicación vieja). A las 10:04, una con la clave K2, también de 40 cajas, porque la
  camioneta hace dos viajes. Al final, otra con K1 pero de 60. Si todas cuentan,
  suspenden a la escuela por exceder su cupo; si se cuenta mal, el banco aparta doble o
  le niega su segundo viaje.
- **Qué datos hay.** Peticiones con clave (o sin ella), contenido e instante; cuándo cayó
  y regresó la base; la bitácora de lo que sí se grabó; el cupo.
- **Qué debe deducir.** Cuáles peticiones son la misma, cuáles nuevas y cuáles inválidas;
  qué sí se grabó y qué aún no se sabe; cuántas cajas apartó de verdad la escuela.
- **Qué debe contestar.** Por petición: nueva, repetida, inválida o no se sabe, con su
  razón; el cupo usado como cifra firme o como rango; y qué dato resolvería cada duda.
- **Por qué es lógica.** Lo intuitivo es mirar el contenido: tres pedidos de 40 cajas
  parecen el mismo. Pero K2 es legítima, K1 con 60 es un error de captura y la que no
  trae clave no se puede afirmar ni descartar. «Repetida» y «no sé» son distintas.

### Situación 4 — Jueves de entrega y la base se cae

- **Qué pasa.** Jueves de entrega: 200 delegados conectados, 80 % consultando y 20 %
  apartando o cancelando. La base se reinicia 20 segundos y el pool tiene pocas
  conexiones. Hay productos abundantes (arroz) y otros con pocas cajas (leche de
  caducidad corta). Aceptar de más es vender lo que no hay; rechazar todo deja a los
  albergues sin saber qué hay.
- **Qué datos hay.** Peticiones con tipo, producto y organización; la última lectura de
  existencias y cuándo se hizo; el reinicio; el pool en uso; las emergencias.
- **Qué debe deducir.** Qué tan confiable es cada existencia conocida (no hay un dato de
  «frescura»: se concluye de la lectura y del reinicio), qué peticiones arriesgan vender
  de más, y cuáles se sirven, se encolan, se sirven con aviso de dato viejo o se rechazan.
- **Qué debe contestar.** Una decisión por petición, con su explicación. Para una misma
  emergencia, la respuesta para arroz y para leche puede ser opuesta.
- **Por qué es lógica.** Lo «obvio» es atender primero a quien tiene emergencia. Pero no
  todas las peticiones arriesgan lo mismo cuando la existencia es dudosa, y la política
  se declara una vez para todos los casos.

### Situación 5 — El apartado que nadie debió hacer (o sí)

- **Qué pasa.** El auditor del donante revisa 15 cajas de leche apartadas el día 6 a las
  23:40 con la credencial de Rocío, delegada del comedor, desde un teléfono nuevo. El
  comedor afirma que ella se fue el día 3 y que nada de eso es suyo. El padrón del banco
  la tenía activa hasta capturar su baja el día 9, por un correo del día 7. La leche ya
  se repartió; si fue ilegítimo, otra organización que cumplía se quedó sin ella.
- **Qué datos hay.** Las bajas con su fecha efectiva, de aviso y de captura; la credencial;
  el apartado y su origen; el padrón del comedor y el del banco, que se contradicen.
- **Qué debe deducir.** Qué versión de los hechos es posible; si la credencial estaba
  vigente según cada fuente; si importa la fecha de aviso o la efectiva; y quién habría
  recibido la leche con la baja capturada a tiempo.
- **Qué debe contestar.** Legítimo, ilegítimo o no se sabe, con su evidencia; a quién le
  toca responder; y qué dato cerraría la duda.
- **Por qué es lógica.** Dos sistemas que no coinciden no se promedian: se razona cuál
  historia cabe, y el «¿qué habría pasado si…?» usa las mismas reglas.

## Por qué no basta un script

Con `if credencial.vigente and cupo > pedido: aceptar()` resuelves a un delegado sin
reintentos ni relojes distintos. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Se acepta la petición 14 del comedor? | decisión |
| ¿Por qué se rechazó y no se aceptó parcialmente? | explicación |
| ¿Qué peticiones se atienden hoy con la base caída? | todas las respuestas |
| ¿Qué tendría que cambiar para que el albergue pueda apartar pollo? | la pregunta al revés |
| ¿Qué habría pasado si la baja de Rocío se hubiera capturado el día 3? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir una petición y a quien la envía en un instante?
2. Cuando «el primero en llegar» choca con «quien más lo necesita», ¿dónde queda escrito
   cuál gana y cuál es la condición para que cambie?
3. ¿Cómo distingue tu gemelo «es un reintento» de «no sé si es un reintento»?
4. ¿Qué parte de la explicación le sirve al delegado rechazado y cuál solo al auditor?
5. En Erlang decidiste cuántas conexiones usar y qué hacer al agotarse. ¿Qué de eso
   alimentaría a este gemelo, y qué decide el gemelo que un pool no puede?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la operación, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch: solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en ella.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para simular peticiones o graficar.

## Supuestos de esta extensión

- Inventado por esta extensión: «Despensa Frontera», sus organizaciones, delegados y
  productos, el auditor, el reglamento (a)-(g) y las fechas. Son datos del ejercicio.
- Escala reducida: 5 organizaciones, 6 delegados y 4 productos (el original maneja 200
  usuarios concurrentes). Los números de los ejemplos (12, 40, 60 y 15 cajas; 300 y 80
  personas; los días 3, 5, 6, 7 y 9; las 10:00; los 40 milisegundos; el año de
  verificación) son datos del ejercicio, no estadísticas.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir. Las caídas y los retrasos no se sortean: entran como hechos.
- Tú defines y declaras como supuesto: el desfase tolerado entre relojes; cuándo una
  existencia deja de ser confiable; qué productos son «escasos» o sustitutos; qué es
  «sin demora»; si cuenta la fecha efectiva o la de aviso; y qué regla gana en cada
  choque.

## Extensiones posibles

Para quien quiera ir más lejos; investiga y cita tus fuentes antes de fijar cifras.

- Cuotas según el tamaño de cada organización y su historial de entregas.
- Lotes con caducidad próxima que deben salir primero.
- Credenciales con permisos distintos (consultar, apartar, cancelar) y su revocación.
- Un donante que impone condiciones distintas sobre lo que dona.

---
*Las cifras del dominio (200 usuarios concurrentes, 80 % lecturas y 20 % escrituras,
20 segundos de caída, reintentos del mismo POST) vienen del problema original. El
escenario y su reglamento son inventados: verifica la fuente vigente de toda cifra antes
de citarla.*
