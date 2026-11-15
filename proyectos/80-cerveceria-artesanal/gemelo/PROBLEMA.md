# #80 — Cervecería artesanal: gemelo digital con programación lógica

> Extensión del proyecto #80. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la cervecería: un proceso por lote que avanza de etapa,
fermentadores con su temperatura y fallas que se recuperan. Esa simulación responde
«¿en qué etapa va cada lote y qué temperatura tiene cada tanque?». El maestro cervecero
necesita algo más: «¿puede este lote seguir, dónde cabe y qué se me echa a perder si
espero?».

El gemelo digital es el **modelo lógico** de la cervecería: hechos que reflejan su estado
y reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque lo que hay que
resolver aquí no es calcular, sino deducir, justificar y descartar.

## La cervecería que se clona

Una cervecería artesanal de Tijuana, reducida a 3 recetas, 3 fermentadores y 6 lotes en
el mes simulado.

| Parte | Contenido |
|---|---|
| Entidades | cervecería → receta → lote (con sus mitades si se divide) → fermentador; insumos con el lote del proveedor |
| Estado por lote | receta, litros, etapa actual y desde cuándo, qué insumos usó, quién confirmó cada etapa |
| Estado por fermentador | lote que contiene (o sus litros, si comparte), temperatura, estado de limpieza, reservas |
| Estado por receta | estilo (ale o lager), rango de temperatura y tiempo de fermentación, densidad final esperada |
| Eventos | llega una lectura, un lote pide avanzar, falla el frío, se vacía un tanque, se limpia y sanitiza, el proveedor avisa de un insumo malo |
| Decisiones | ¿puede avanzar?, ¿terminó?, ¿está en riesgo?, ¿dónde fermenta?, ¿hay que retirarlo? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original: su escenario, sus casos difíciles, sus preguntas
guía y sus datos del mundo real. Los detalles que las vuelven exigentes (capacidades,
registros incompletos, reservas) son complemento de esta extensión. En cada una, tu
gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — El lote que pide avanzar

- **Qué pasa.** El maestro cervecero pide pasar el lote 3, una ale, de enfriado a
  fermentación. Una etapa solo vale si se cumplió de verdad: la maceración (~65-68 °C
  por ~60 min) debe sostenerse en su rango todo ese tiempo, y la cocción dura 60-90 min
  con lúpulo. El reloj dice que ya pasó el tiempo; la bitácora del macerador tiene un
  hueco de lecturas a media etapa.
- **Qué datos hay.** Etapas con su hora de inicio, lecturas del macerador, eventos de
  cocción y lúpulo, y qué fermentadores están limpios.
- **Qué debe deducir.** Si cada etapa previa se cumplió, se incumplió o no se puede
  saber. Nadie mide «maceración bien hecha»: se deduce de varios datos.
- **Qué debe contestar.** El siguiente paso válido (o la secuencia hasta fermentación),
  con sus alternativas; si lo niega, el motivo y qué falta para permitirlo.
- **Por qué es lógica.** La validez de una transición depende de lo que pasó en las
  etapas anteriores, no del tiempo transcurrido. Y «no se sabe» no es «no se cumplió».

### Situación 2 — ¿Terminó o se atoró?

- **Qué pasa.** El lote 2, una ale, lleva días fermentando y su densidad ya no baja. La
  fermentación termina cuando la densidad se estabiliza por 2-3 días, pero una densidad
  quieta también se ve en una fermentación atorada, y un sensor pegado da la misma línea
  plana. Un lote espera ese tanque (situación 4).
- **Qué datos hay.** Densidad original y lecturas con su hora, temperatura del tanque,
  tiempo que la receta prevé, densidad final esperada y quién confirmó qué.
- **Qué debe deducir.** Si el lote terminó, está atorado, tiene un sensor sospechoso o
  no alcanza la información. Que el calendario diga «ya toca» no basta.
- **Qué debe contestar.** El veredicto, su evidencia y la diferencia entre «los datos
  indican que terminó» y «el maestro cervecero lo confirmó». Con qué datos cambiaría.
- **Por qué es lógica.** Ningún sensor entrega esa conclusión: se apoya en varios hechos
  que pueden contradecirse, y lo obvio (cumplió sus días, entonces terminó) puede estar
  mal.

### Situación 3 — La noche que el fermentador perdió el frío

- **Qué pasa.** Un fermentador pierde frío y sube 5 °C en una noche. Una temperatura
  equivocada da sabores no deseados o detiene la fermentación, y un lote entero puede
  perderse. Otro tanque también marcó temperaturas raras, pero su sensor dejó de
  reportar a media noche.
- **Qué datos hay.** Lecturas por fermentador, qué lote contiene cada uno, su receta y
  estilo (ales 18-22 °C, lagers 8-12 °C), la etapa del lote y el aviso de falla del
  control de temperatura.
- **Qué debe deducir.** Qué lotes están en riesgo: no es lo mismo para una ale que para
  una lager, ni para un tanque con lote que para uno vacío. Nadie mide «lote en
  riesgo»; se deduce de la lectura, el contenido, su rango y cuánto duró fuera de él.
- **Qué debe contestar.** Qué lotes marcar en riesgo y a quién avisar, con la razón de
  cada caso; cuáles quedan en «no sé» y qué lectura los resolvería. El tanque que
  llegó más alto no es por fuerza el más grave.
- **Por qué es lógica.** La misma lectura significa cosas distintas según la receta, la
  etapa y el contenido. El contexto, no el número, decide.

### Situación 4 — El fermentador reservado

- **Qué pasa.** El lote 2 sigue ocupando el fermentador 2, que estaba reservado para el
  lote 5. El mosto del lote 5 ya está enfriado y esperando; el lote 6 también quiere
  entrar. El fermentador 1 figura libre, pero aún no se limpia y sanitiza. El lote 5
  es más grande que un fermentador y tendría que dividirse en dos. El dueño de cada
  lote cree tener razón.
- **Qué datos hay.** Capacidades, reservas, qué lote ocupa qué tanque y desde cuándo,
  estado de limpieza de cada uno, y la situación del lote 2 (la anterior).
- **Qué debe deducir.** Qué fermentadores estarán realmente disponibles y desde cuándo
  (vaciar, limpiar y sanitizar toma horas), si el lote 5 debe dividirse y entre
  cuáles, y a cuál lote hay que fallarle si el reparto no alcanza.
- **Qué debe contestar.** El reparto completo de fermentadores entre las solicitudes,
  con las demás alternativas válidas; si ninguna existe, que lo diga y por qué, y a
  quién se le falla y por qué. Un tanque que figura libre puede no estar disponible.
- **Por qué es lógica.** Es asignación con restricciones (capacidad, disponibilidad,
  reservas) cuyo resultado cambia con un solo dato. Las prioridades se declaran una vez.

### Situación 5 — El insumo contaminado

- **Qué pasa.** El proveedor avisa que un lote de levadura salió contaminado. Hay que
  retirar lo que la usó y rastrear qué más dependió de ella. Algunos lotes la usaron en
  recetas distintas, uno se dividió en dos fermentadores y a uno le falta el registro
  de qué levadura recibió. Un fermentador recibió después a otro lote y su limpieza no
  quedó registrada. El etiquetado y el cumplimiento sanitario exigen trazabilidad.
- **Qué datos hay.** Qué insumos (malta, lúpulo, levadura) usó cada lote con el lote del
  proveedor, qué tanque ocupó cada lote o cada mitad, y los eventos de limpieza.
- **Qué debe deducir.** Qué lotes, mitades y fermentadores quedan afectados por una
  cadena de pasos y cuáles son «no se sabe» porque falta un registro. La falta de
  registro no es falta de uso.
- **Qué debe contestar.** Qué retirar con certeza, qué retirar por precaución y qué
  dejar, con la cadena que lo sostiene. Dos partes tienen razón: el cervecero que no
  quiere tirar lo no probado y la obligación sanitaria de no vender lo dudoso. La regla
  debe decidir y justificar a quién se le falla.
- **Por qué es lógica.** Es razonar sobre relaciones: del insumo al lote, a sus mitades y
  a los tanques. Las preguntas inversas («¿qué usó este lote?», «¿qué lotes usaron
  esto?») salen de los mismos hechos.

## Por qué no basta un script

Con `if temperatura > 22: marcar_en_riesgo(lote)` resuelves un tanque de ale con datos
perfectos. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué hago con el lote 3? | decisión |
| ¿Por qué no puede entrar a fermentación? | explicación |
| ¿Qué lotes pueden avanzar de etapa ahora? | todas las respuestas |
| ¿Qué falta para que el lote 5 tenga fermentador? | la pregunta al revés |
| ¿Qué pasaría si el fermentador 2 sigue ocupado unas horas más? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué determina que una etapa «terminó» y quién lo confirma: el reloj, los datos o una
   persona?
2. ¿Cómo distingue tu gemelo «el lote no está en riesgo» de «no sé si lo está»?
3. Cuando dos lotes quieren el mismo tanque, ¿dónde queda escrito a quién se le falla?
4. ¿Cómo evitas que un retraso desbarate todo el calendario?
5. ¿Qué parte de tu simulación en Erlang (un proceso por lote, fermentadores con
   temperatura objetivo, la prueba de caos que marca un lote en riesgo) podría alimentar
   a este gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la cervecería, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar lecturas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 3 recetas, 3 fermentadores y 6 lotes, contra las 5 recetas, 6
  fermentadores y 12 lotes del escenario original.
- Los fermentadores son de 1,000 L cada uno (cifra de esta extensión, no del original) y
  el lote 5 es mayor. Puedes cambiarlo, pero un lote debe seguir sin caber en un tanque.
- El «ahora» es un hecho del modelo, en horas desde el inicio del mes simulado, no el
  reloj del sistema, para que las respuestas se puedan repetir.
- Los identificadores de los ejemplos (lote 3, fermentador 2) son del ejercicio.
- Defines tú, porque el original no los da: cuánto tiempo fuera de rango pone un lote en
  riesgo, cuánto silencio vuelve dudoso a un sensor, cuánta diferencia entre lecturas
  cuenta como densidad estable, cuántas horas toma limpiar y sanitizar, cuánto puede
  esperar un mosto enfriado, la densidad final esperada de cada receta y la regla de a
  quién se le falla.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Costo de la merma de cada lote y qué pérdida se prefiere cuando no hay para todos.
- Presión y puntos de carbonatación, y los tiempos de maduración por receta.
- Reparto de insumos entre lotes cuando una entrega llega incompleta.
- Efecto del clima de Tijuana (calor de verano) sobre el control de temperatura.
- Un lote por barril o por botella: qué se etiqueta y qué se retiene.

---
*Las cifras de dominio son de referencia (órdenes de magnitud) y vienen del problema
original. La escala reducida, las capacidades y los identificadores son del ejercicio.
Verifica la fuente vigente antes de citarlas en tu entrega.*
