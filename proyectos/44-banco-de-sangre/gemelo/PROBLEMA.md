# #44 — Banco de sangre: gemelo digital con programación lógica

> Extensión del proyecto #44. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).
> Es un ejercicio con datos simulados, no un sistema real de un banco de sangre.

## Del simulador al gemelo

En la parte de Erlang simulaste el banco: un inventario por tipo y lote, unidades que pasan
de disponibles a reservadas, transfundidas o caducadas, y un gestor de solicitudes
urgentes que no debe reservar dos veces la misma unidad. Esa simulación responde «¿qué hay
en el refrigerador y en qué estado está cada unidad?». El médico y el responsable del
banco necesitan algo más: «¿qué unidad le doy a este paciente, a quién se la quito, y por
qué?».

El gemelo digital es el **modelo lógico** del banco: hechos que reflejan su estado y reglas
que reflejan cómo se decide en él. Se escribe en Prolog porque lo que hay que resolver
aquí no es contar bolsas, sino decidir quién recibe qué, justificar a quién se le falla y
reconocer cuándo el banco no tiene cómo saber.

## El banco de sangre que se clona

El banco de sangre de un hospital general de Tijuana, reducido a unas 30 unidades, los 8
tipos sanguíneos, los 3 componentes (glóbulos rojos, plaquetas y plasma), 3 equipos de
almacenamiento y 6 pacientes.

| Parte | Contenido |
|---|---|
| Entidades | donante → donación → unidad (una por componente obtenido); equipo de almacenamiento; paciente; solicitud; cirugía programada |
| Estado por unidad | componente, tipo, caducidad, en qué equipo está y desde cuándo, si está reservada, en cuarentena, retirada o transfundida |
| Estado por equipo | temperatura medida a lo largo del tiempo y el rango que exige el componente que guarda |
| Estado por paciente | tipo sanguíneo registrado, y por qué fuente quedó registrado |
| Estado por donación | tipo del donante y resultado de sus pruebas, con la hora de cada una |
| Eventos | llega una donación, se libera una unidad, se reserva, se transfunde, una lectura sale de rango, llega una prueba tardía, llega un accidente |
| Decisiones | ¿qué unidad se asigna?, ¿se libera una reserva?, ¿se retira una unidad?, ¿a quién se avisa?, ¿el nivel de un tipo es crítico? |

## Situaciones que tu gemelo debe razonar

Las cinco parten del problema original. Los complementos derivados (que de una donación
salgan varios componentes, que un paciente tenga el tipo registrado por dos fuentes) se
indican en cada situación. En cada una, tu gemelo debe llegar a una decisión **y poder
explicarla**.

### Situación 1 — Se acabó mi tipo

- **Qué pasa.** Llega la solicitud de glóbulos rojos para un paciente de tipo conocido y
  el banco ya no tiene unidades de ese tipo exacto. Hay otras compatibles, pero unas son
  O negativo, el tipo que sirve a casi todos y que se agota primero. Si se gasta ahora en
  quien tenía otras opciones, no queda para quien llegue sin tipificar.
- **Qué datos hay.** Tipo del paciente, tipo y caducidad de cada unidad disponible, la
  compatibilidad ABO/Rh y las demás solicitudes abiertas.
- **Qué debe deducir.** Qué unidades sirven a este paciente, en qué orden convienen y cuáles
  conviene no tocar porque otro paciente no tiene alternativa.
- **Qué debe contestar.** La unidad asignada, las alternativas válidas que descartó y la
  razón de cada descarte. Si el paciente pide un tipo que ninguna unidad cubre, lo dice y
  señala qué falta.
- **Por qué es lógica.** La compatibilidad es una relación entre tipos, no una igualdad. Lo
  intuitivo («dale la unidad universal, sirve seguro») está mal cuando gasta la unidad que
  alguien más no puede sustituir.

### Situación 2 — La reserva que caduca antes que la cirugía

- **Qué pasa.** Una cirugía programada tiene unidades reservadas. Esa noche llega una
  urgencia que pide el mismo tipo y componente. Una de las unidades reservadas caduca
  antes de la hora de la cirugía; otra más fresca está libre. Además, si una cirugía
  termina sin usar lo reservado, esa sangre sigue ocupada. Si la reserva es intocable, la
  urgencia espera; si no lo es, la cirugía puede quedarse corta.
- **Qué datos hay.** Reservas con la hora de su cirugía, caducidad de cada unidad, la
  solicitud urgente y las unidades libres.
- **Qué debe deducir.** Qué reservas son realmente utilizables a la hora que importa, qué
  unidad se debe dar primero y si se puede reasignar sin dejar a nadie sin sangre.
- **Qué debe contestar.** A quién va cada unidad, qué reserva se reacomoda y qué parte
  queda sin cubrir si no alcanza, nombrando a quién se le falla y por qué.
- **Por qué es lógica.** Es un dilema real: la cirugía programada tiene su derecho y la
  urgencia tiene el suyo. El orden de caducidad (el que vence antes sale primero) y la
  prioridad de la reserva se declaran una vez y valen para todos los casos. La respuesta
  correcta puede ser entregar la unidad reservada y reservar otra.

### Situación 3 — El donante que salió positivo tarde

- **Qué pasa.** La prueba de un donante resulta positiva después de que sus unidades ya
  fueron liberadas. Algunas siguen en refrigerador, otras están reservadas para una cirugía
  y otras ya se transfundieron. Un error aquí es un paciente infectado por la sangre que
  debía curarlo.
- **Qué datos hay.** Quién donó, qué unidades salieron de esa donación (complemento
  derivado: de una donación salen varios componentes), dónde está cada una y a qué
  receptor llegó. Ningún dato dice «unidad contaminada».
- **Qué debe deducir.** Qué unidades se retiran de inmediato aunque su propia bolsa luzca
  bien, a qué receptores se avisa, y qué unidades no tienen registro: ahí la respuesta es
  «no se sabe», distinta de «no se transfundió».
- **Qué debe contestar.** Tres listas: retirar, avisar y no se sabe, cada una con la cadena
  que la sustenta. Si una unidad retirada estaba reservada, cuál cirugía queda sin sangre.
- **Por qué es lógica.** Son varios eslabones encadenados (donante, donación, unidades,
  estado, receptor) y el resultado depende de recorrer la cadena entera. Si las donaciones
  anteriores del mismo donante también se revisan, y hasta cuándo, lo decides tú.

### Situación 4 — El refrigerador que falla

- **Qué pasa.** Un refrigerador de glóbulos rojos deja de mantener su temperatura. Las
  lecturas salen de rango un rato, regresan, y hay horas sin ninguna lectura. Algunas
  unidades se movieron a otro equipo antes de la falla, otras durante. Un equipo de
  plaquetas, que trabaja a otra temperatura, también está en el banco.
- **Qué datos hay.** Lecturas de cada equipo con su hora, el rango que exige cada
  componente, en qué equipo estuvo cada unidad y desde cuándo.
- **Qué debe deducir.** Qué unidades estuvieron expuestas, cuáles seguramente no, y cuáles
  no se puede saber porque faltan lecturas. Ningún sensor mide «lote comprometido».
- **Qué debe contestar.** Las unidades comprometidas, las que pasan a cuarentena por duda y
  las que se salvan, con la lectura o el hueco que lo justifica. Cuánto tiempo fuera de
  rango es tolerable no lo da el original: lo decides y lo declaras.
- **Por qué es lógica.** Una temperatura buena para un componente es mala para otro, y la
  exposición se deduce del cruce entre lecturas, ubicación y tiempo. Lo intuitivo («ya
  volvió a rango, está bien») está mal: lo que importa es lo que pasó mientras tanto. Y
  descartar sin saber puede dejar al banco sin O negativo.

### Situación 5 — Veinte unidades de O negativo en una hora

- **Qué pasa.** Un accidente múltiple llena la urgencia (en el original consume 20
  unidades de O negativo en 1 hora). A quien llega sin tipificar se le da O negativo. En
  ese momento quedan pocas unidades y hay varias solicitudes a la vez: un paciente sin
  tipificar, uno cuyo tipo es O negativo confirmado y otro cuyo expediente dice un tipo
  pero su pulsera dice otro (complemento derivado: dos fuentes que no concuerdan). Para el
  paciente O negativo, casi nadie más le sirve.
- **Qué datos hay.** Solicitudes de emergencia, unidades por tipo y estado, las fuentes de
  tipo de cada paciente y las reservas ya hechas.
- **Qué debe deducir.** A quién se le asigna cada unidad escasa, quién cuenta como
  «tipificado» y cuándo el nivel de un tipo es crítico. El inventario total engaña: lo que
  cuenta es lo utilizable, no lo vencido, reservado o en cuarentena.
- **Qué debe contestar.** El reparto, el desempate entre quienes tienen razón y la alerta
  de nivel crítico por tipo, con las unidades que de verdad cuentan.
- **Por qué es lógica.** Es un dilema real: gastar la última unidad en quien no sabe su
  tipo o en quien no tiene otra opción. Un tipo en el expediente que contradice a la
  pulsera es «no se sabe», no «ya sabemos cuál es».

## Por qué no basta un script

Con `if unidad.tipo == paciente.tipo and unidad.caducidad > hoy: asignar(unidad)` resuelves
una solicitud con datos perfectos y un solo paciente. Tu gemelo debe contestar, **con las
mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué unidad le doy a la solicitud 7? | decisión |
| ¿Por qué esa y no la O negativo? | explicación |
| ¿Qué receptores hay que avisar por este donante? | todas las respuestas |
| ¿Qué tendría que cambiar para que la cirugía conserve su reserva? | la pregunta al revés |
| ¿Qué pasaría si el refrigerador B falla a media noche? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos distinguen una unidad «en inventario» de una «utilizable»?
2. Cuando el tipo exacto se acabó, ¿dónde queda escrito el orden de sustitución?
3. ¿Cómo distingue tu gemelo «la unidad no está comprometida» de «no sé si lo está»?
4. ¿Qué parte de la explicación necesita un médico a las 3 de la mañana y cuál es ruido?
5. ¿Qué estados de la unidad en tu simulación en Erlang (disponible, reservada, transfundida,
   caducada) podrían alimentar a este gemelo como hechos?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del banco, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar donaciones simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: unas 30 unidades, 3 equipos y 6 pacientes, contra las 300 unidades del
  escenario original. El accidente se reduce en proporción: cuántas unidades consume lo
  fijas tú.
- El «ahora» es un hecho del modelo, en horas, no el reloj del sistema, para que las
  respuestas se puedan repetir.
- Los identificadores y cantidades de los ejemplos («solicitud 7», «refrigerador B») son
  ilustrativos, no datos del escenario.
- Que una donación produzca varias unidades y que un paciente tenga el tipo registrado
  por dos fuentes son complementos de esta extensión, no del original.
- Los define y verifica el estudiante, porque el original no los da: la tabla completa de
  compatibilidad ABO/Rh (solo da los extremos), cuándo un nivel es crítico, cuánto tiempo
  fuera de rango se tolera, cuándo se libera una reserva no usada, qué fuente de tipo
  prevalece y cuánto se revisa hacia atrás en las donaciones de un donante.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Plasma y plaquetas con reglas de compatibilidad distintas a las de glóbulos rojos.
- Intervalo mínimo entre donaciones de un mismo donante, según la norma vigente.
- Prueba cruzada antes de transfundir y qué hacer si no concuerda.
- Plaquetas con agitador detenido o sangre en tránsito entre dos bancos.
- Picos de demanda por eventos masivos y campañas de donación.

---
*Las cifras (vida útil de cada componente, rango de temperatura de refrigeración, 300
unidades, 20 unidades de O negativo en una hora) son de referencia y vienen del problema
original. Verifica la fuente vigente, incluida la NOM-253-SSA1-2012, antes de citarlas en tu
entrega.*

