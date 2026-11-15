# #81 — Gestión de ganado: gemelo digital con programación lógica

> Extensión del proyecto #81. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el rancho: animales que se pesan, potreros que se
secan, un lote que enferma. Esa simulación responde «¿qué está pasando?». El ranchero
necesita algo más: «¿qué hago, y por qué?». Si mueve el hato al potrero equivocado, el
terreno se degrada por años; si deja salir un lote que no debía, pierde la venta.

El gemelo digital es el **modelo lógico** del rancho: hechos que reflejan su estado y
reglas que reflejan cómo se decide en él. Se escribe en Prolog porque lo que hay que
resolver aquí no es calcular, sino deducir, justificar y descartar.

## El rancho que se clona

Un rancho del noroeste, de agostaderos secos, reducido a pocos animales y pocos
potreros. Los datos se capturan a mano en el corral; las decisiones se toman sobre
animales, lotes y potreros.

| Parte | Contenido |
|---|---|
| Entidades | rancho → potrero → lote → animal (con arete oficial del SINIIGA y categoría: becerro, vaquilla, vaca, toro) |
| Estado por animal | peso en cada pesaje (kg) y quién lo capturó, vacunas aplicadas por campaña, tratamientos, si tiene arete legible |
| Estado por potrero | pasto disponible, agua disponible, qué potreros colindan y cuáles comparten aguaje |
| Eventos | un pesaje, una vacunación, una enfermedad observada, un arete perdido, un movimiento, una solicitud de guía de tránsito |
| Decisiones | ¿alerta o ruido?, ¿quién es este animal?, ¿aislar a quién?, ¿a qué potrero y por dónde?, ¿puede salir este lote? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original (escenario, casos difíciles, preguntas guía y
datos del mundo real); lo que añado yo va marcado como «complemento». En cada una, tu
gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — El animal que «perdió» 100 kg

- **Qué pasa.** En el pesaje del mes, un animal «pierde» 100 kg (caso difícil del
  original). Una caída de peso puede ser enfermedad, sequía o robo, pero un becerro gana
  ~0.5-1.0 kg al día y los datos se capturan a mano, tarde o con errores. Tratar a un
  animal sano cuesta; ignorar a uno enfermo cuesta el animal y quizá el lote.
- **Qué datos hay.** Los pesajes de cada animal con su fecha y quién los capturó, la
  categoría, el lote y el potrero, y cómo les fue a los demás animales del mismo lote en
  el mismo periodo. Ningún dato dice «enfermo».
- **Qué debe deducir.** Si el cambio es una alerta real o ruido de captura, y qué causa
  la sustenta: un animal solo contra todo el lote, o un lote entero que baja junto, o
  un dato que la fisiología no admite.
- **Qué debe contestar.** «Alerta», «ruido» o «no lo sé», con la causa probable y qué
  pesaje o revisión la confirmaría (pregunta guía 1 del original).
- **Por qué es lógica.** Lo intuitivo es atender al animal con la caída más grande, y
  eso es sospechoso: la caída más espectacular puede ser un error de dedo, y la discreta
  de otro animal, la real. La causa se deduce de comparar, no de leer un número.

### Situación 2 — Arete perdido, animal duplicado

- **Qué pasa.** El registro dice que hay un animal más de los que cuenta el corral, o
  uno menos. Puede ser un arete perdido, un animal capturado dos veces con dos
  identificadores, o un animal robado (caso difícil del original). Sin identificación
  oficial no hay trazabilidad, y sin ella no hay venta.
- **Qué datos hay.** Registros con su arete (a veces repetido, a veces ausente),
  categoría, lote, historial de pesos y vacunas. (Complemento: el conteo del corral.)
- **Qué debe deducir.** Qué registros son el mismo animal, cuáles son animales
  distintos y qué hueco queda sin explicar, sin que ningún dato lo diga directamente.
- **Qué debe contestar.** Por cada par dudoso, «mismo animal», «animales distintos» o «no
  lo sé», con el historial que lo sostiene, y qué falta confirmar.
- **Por qué es lógica.** Identidad es una relación entre registros, no un campo. Y «no
  hay evidencia de que sean iguales» no es «son distintos». Si se equivoca, se vende
  con la vacuna de otro animal o se da por robado a uno que está en el potrero.

### Situación 3 — El brote y quién estuvo cerca

- **Qué pasa.** Un lote presenta un brote sanitario que debe aislarse (escenario del
  original). Los lotes se mueven entre potreros y el rancho responde ante campañas
  sanitarias (brucelosis, tuberculosis, rabia paralítica bovina). El ranchero no
  quiere aislar de más: es pasto, agua y venta perdidos. (Complemento: el aguaje común.)
- **Qué datos hay.** Qué animales enfermaron y cuándo, en qué potrero estuvo cada lote
  y desde cuándo, qué potreros comparten agua y las vacunas por animal. Ningún dato
  dice «en riesgo».
- **Qué debe deducir.** Quién estuvo expuesto aunque se vea sano: de un animal enfermo
  a su lote, de su lote a los potreros que usó, de esos a otros lotes que los usaron
  después o que comparten aguaje, y de ahí a quienes tienen o no la vacuna vigente. Es una
  cadena de varios pasos.
- **Qué debe contestar.** Qué lotes y qué animales aislar con certeza, cuáles por
  precaución, cuáles quedan «no lo sé» por falta de registro (un lote sin historial de
  ubicación, una vacuna sin fecha), y la hipótesis «¿qué pasaría si hubiera sido
  también el potrero 3?».
- **Por qué es lógica.** Es razonar sobre una red de contactos. Lo intuitivo es aislar
  solo a los enfermos; lo correcto puede incluir a un lote sin un solo síntoma y dejar
  fuera a uno que estaba más cerca pero llegó después.

### Situación 4 — La sequía y el potrero que parece buena idea

- **Qué pasa.** Una sequía reduce 50 % el pasto de dos potreros (escenario del
  original). Hay que decidir a qué potrero mover el hato (pregunta guía 2) y por dónde,
  porque el pastoreo rotacional pide descanso del pasto y el sobrepastoreo degrada el
  terreno por años. Mover un lote a un potrero con poca agua es un caso difícil del
  original. El ranchero y el terreno tienen razón: el hato necesita comer hoy y el
  pasto necesita descansar.
- **Qué datos hay.** Pasto y agua por potrero, cuáles colindan y por dónde se puede
  pasar, qué potreros están en descanso, quién ocupa cada uno, y la categoría de cada
  lote (con necesidades y calendarios distintos).
- **Qué debe deducir.** Qué destinos sirven a cada lote, por qué ruta llega sin pasar
  por donde no debe, y cuál potrero se sacrifica o se descansa.
- **Qué debe contestar.** Destino y ruta por lote, o «ninguno sirve» con el motivo; a
  quién se le falla (el hato, el pasto) y qué tendría que cambiar.
- **Por qué es lógica.** Lo intuitivo es mandar el hato al potrero con más pasto, y es
  sospechoso: puede no tener agua, estar en descanso, o quedar al otro lado de un
  potrero con brote. La decisión sale de combinar recurso, descanso y camino.

### Situación 5 — ¿Puede salir este lote?

- **Qué pasa.** Un comprador espera un lote. Mover animales entre predios exige guía
  de tránsito, arete oficial y campañas sanitarias al día (datos del mundo real del
  original), y la sequía vuelve urgente vender: menos animales, menos presión sobre el
  pasto. Pero el lote tiene un animal sin arete legible y otro sin la última campaña.
- **Qué datos hay.** Las vacunas por animal y las campañas del año (3 en el escenario
  original), la identificación de cada animal, la ubicación reciente del lote y las
  conclusiones de las situaciones 2 y 3.
- **Qué debe deducir.** Si cada animal es elegible, y por tanto el lote, y cuáles
  animales lo impiden. Ningún dato dice «puede salir»: se deduce de identidad, vacunas,
  historial de contacto y destino.
- **Qué debe contestar.** «Puede salir», «no» o «no lo sé», con quién lo impide y qué
  tendría que cambiar. Si la regla permite sacar solo parte del lote, a quién se le falla. El
  ranchero con la sequía encima y el comprador con su pedido tienen razón; la norma
  sanitaria también.
- **Por qué es lógica.** La elegibilidad de un lote se deduce de la de cada animal, y
  la de cada animal de varios hechos a la vez. Lo intuitivo es vender primero a los
  animales más gordos, y eso es sospechoso: el más gordo puede ser el que no cumple.

## Por qué no basta un script

Con `if peso_actual < peso_anterior: alerta()` resuelves un animal con datos perfectos.
Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué hago con la vaquilla 7? | decisión |
| ¿Por qué? | explicación |
| ¿Qué lotes se aíslan ahora? | todas las respuestas |
| ¿Qué falta para que el lote 2 pueda salir? | la pregunta al revés |
| ¿Qué pasaría si el potrero 3 también tuviera brote? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para decir que dos registros son el mismo animal?
2. ¿Dónde queda escrito qué hace que una variación de peso sea alerta y no ruido?
3. ¿Cómo distingue tu gemelo «no hay contacto con el brote» de «no sé si hubo contacto»?
4. ¿Qué parte de la explicación le sirve al ranchero y qué parte es ruido?
5. ¿Qué proceso de tu simulación en Erlang (el de cada animal, el de cada potrero, las
   alertas sanitarias) podría alimentar a este gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del rancho, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar pesajes simulados o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 12 animales en 3 lotes y 4 potreros, contra los 400 animales y 8
  potreros del escenario original. Los identificadores («lote 2», «potrero 3») son del
  ejercicio.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir.
- Tú defines el mapa (qué potreros colindan o comparten aguaje), las campañas del año y
  cuáles animales tienen arete legible.
- El original no da estos valores y no los invento: cuánta caída de peso es alerta o
  ruido, cuántos kilos hacen imposible un dato, cuánto tiempo de contacto expone a un
  animal, cuánta vigencia tiene una vacuna, cuánto descanso necesita un potrero, qué
  pasto o agua es «poca» y qué pesa más al decidir un dilema. Son decisión tuya;
  anótalos y justifícalos. Los destinos de los ejemplos son ilustrativos.

## Extensiones posibles

Para quien quiera ir más lejos. No vienen del original: investiga y cita fuentes
antes de fijar cifras.

- Periodo de retiro de un medicamento antes de vender.
- Parición y destete: quién debe estar con quién y en qué potrero.
- Capacidad de carga de cada potrero y cuándo el sobrepastoreo se vuelve irreversible.

---
*Las cifras (~0.5-1.0 kg/día, 100 kg, 400 animales, 8 potreros, 3 campañas al año,
50 % de pasto) vienen del problema original, que las da como orden de magnitud. Verifica
la fuente vigente antes de citarlas en tu entrega. Lo demás son supuestos de la escala
reducida.*
