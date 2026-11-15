# #15 — Cluster de 2-3 nodos: gemelo digital con programación lógica

> Extensión del proyecto #15. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang levantaste un clúster, mataste un nodo, desconectaste otro y
reconectaste, y mediste si el estado convergía. Esa simulación responde «¿sobrevivió?».
Quien administra un clúster que sostiene un hospital necesita algo más: «¿qué dato puede
escribirse dónde, quién manda ahora y a quién le fallo si hay que elegir?».

El gemelo digital es el **modelo lógico** del clúster: hechos que reflejan su estado y
reglas que reflejan cómo se reparten las copias y se nombra a quien manda. Se escribe en
Prolog porque aquí no se calcula: se deduce quién está con quién, se reparte con
restricciones y se sabe decir «no lo sé».

## El clúster del hospital que se clona

El «Hospital Comunitario Lomas de la Presa», de Tijuana, **no existe: es un escenario
planteado por esta extensión**, no por el problema original. Son 3 nodos y 5 datos.

| Parte | Contenido |
|---|---|
| Entidades | nodos **Sótano** (cuarto de servidores; ahí se conectan las terminales de urgencias), **Torre** (consulta externa y farmacia ambulatoria, otro edificio del campus) y **Mexicali** (servidor rentado en otra ciudad, solo respaldo); enlaces entre ellos; cinco datos: expediente, controlados, camas, sesiones, signos |
| Personas | la jefa de sistemas (propone y administra), el director médico (autoriza excepciones), la jefa de urgencias (necesita registrar ingresos), la farmacéutica responsable (responde ante la autoridad sanitaria por los controlados), el proveedor del servidor de Mexicali (su convenio de confidencialidad vence) |
| Estado por nodo | sitio (campus o fuera), capacidad, qué copias guarda, últimos latidos que recibió de cada otro nodo, desfase conocido de su reloj, si estuvo ausente y desde cuándo |
| Estado por dato | tamaño, copias mínimas, dónde está cada copia, versión que guarda cada nodo, qué se escribió mientras un nodo estaba aislado |
| Estado por enlace | medio (fibra del campus o internet), si reporta bien, latencia medida |
| Eventos | llega o falta un latido, se corta o vuelve un enlace, cae o regresa un nodo, se escribe un dato, se entrega un controlado, vence un convenio |
| Decisiones | ¿dónde viven las copias?, ¿el nodo está caído o solo no lo veo?, ¿quién manda y quién puede confirmar qué?, ¿qué se acepta de un nodo que regresa?, ¿qué pasó en realidad? |
| Reglamento (inventado) | (a) del expediente y de los controlados nunca deben existir dos versiones confirmadas; (b) urgencias no se queda sin registrar un ingreso ni sin saber qué camas hay, aunque el dato sea provisional; (c) cada dato tiene al menos sus copias mínimas en nodos distintos, y el expediente además una copia fuera del campus; (d) el expediente solo vive en nodos con convenio vigente, y al vencer deja de ser legal ahí desde ese instante; (e) si hay que sacrificar un servicio, se sacrifica consulta externa antes que urgencias; (f) un nodo que estuvo ausente no manda ni responde consultas críticas hasta ponerse al corriente; (g) todo cambio de líder, de ubicación de copias y toda entrega de controlados queda en bitácora con instante, quién lo ordenó y desde qué nodo |

## Situaciones que tu gemelo debe razonar

Las cinco las plantea esta extensión. La 2, la 3, la 4 y la 5 retoman casos y datos del
problema original (nodo muerto o lento, latidos de ~60 s, partición y *split brain*,
quórum, regreso con estado viejo, reloj adelantado 5 s); la 1 es nueva y la pide el
foco del proyecto: dónde replicar el estado. En cada una, tu gemelo debe decidir **y
poder explicar la decisión**.

### Situación 1 — ¿Dónde vive cada dato?

- **Qué pasa.** La jefa de sistemas debe repartir las copias de los cinco datos entre los
  tres nodos. No cabe todo en todos lados, el expediente exige una copia fuera del campus
  y el convenio del servidor de Mexicali vence esta noche. Si se reparte mal, un corte o
  un incendio se lleva la única copia de un expediente; si queda una copia en un nodo sin
  convenio, el hospital incumple su compromiso de confidencialidad.
- **Qué datos hay.** Capacidad de cada nodo, tamaño y copias mínimas de cada dato, qué
  nodos están dentro del campus, la vigencia de cada convenio y dónde está hoy cada copia.
- **Qué debe deducir.** Qué repartos cumplen todo el reglamento a la vez; qué copia
  actual deja de ser legal en cuanto vence el convenio; cuánto espacio queda en cada nodo.
- **Qué debe contestar.** Todos los repartos válidos antes del vencimiento. Después de
  él: los que sigan siéndolo o, si no existe ninguno, decirlo y señalar qué regla y qué
  nodo lo impiden, y qué tendría que cambiar (renovar, ampliar, una excepción del director).
- **Por qué es lógica.** Es asignar con restricciones que chocan: la misma descripción
  sirve para revisar un reparto, generar todos y explicar por qué no hay ninguno.

### Situación 2 — ¿Muerto o lento?

- **Qué pasa.** De madrugada, el Sótano deja de recibir latidos de la Torre. Si se declara
  caída a la Torre y se nombra otro responsable de los controlados mientras la farmacia
  ambulatoria sigue entregando, habrá dos versiones y la farmacéutica responde por ello.
  Si se espera de más, la farmacia ambulatoria se queda sin sistema. Un vigilante dice
  que «parpadeó la luz en la Torre».
- **Qué datos hay.** Último latido que cada nodo recibió de cada otro, los enlaces y su
  latencia medida (menos de 1 ms en el campus, 50 a 200 ms con pérdidas hacia Mexicali),
  la lectura del respaldo de energía de la Torre y el aviso del vigilante (una persona,
  sin hora exacta).
- **Qué debe deducir.** Para la Torre: caída, aislada de algunos nodos, solo lenta o
  «no se sabe»; y qué cambia si el único testigo que no la ve es un nodo que quizá es el
  aislado. Ningún dato dice «caída»: se concluye de varios.
- **Qué debe contestar.** Los cuatro veredictos distintos con los testigos que los
  sustentan; si ya es seguro cambiar de responsable; y qué observación nueva sacaría
  a la Torre de la duda.
- **Por qué es lógica.** «Nadie me contesta» no es «murió»: depende de quién lo ve y de
  quién no, y el silencio de un solo lado prueba menos de lo que parece.

### Situación 3 — El campus se parte

- **Qué pasa.** Una excavadora corta la fibra entre el Sótano y la Torre, y esa misma
  noche el proveedor de internet del Sótano se cae. El Sótano está sano, tiene el dato más
  reciente y era quien mandaba; en él están las terminales de urgencias. La jefa de
  urgencias exige seguir registrando ingresos y recetas. La farmacéutica exige que no se
  confirme ninguna entrega de controlados que la otra mitad pueda confirmar también.
  Ambas tienen razón.
- **Qué datos hay.** Estado de cada enlace, quién ve a quién, quién mandaba antes, la
  última escritura confirmada de cada nodo, y dónde están las terminales de cada servicio.
- **Qué debe deducir.** En cadena: qué enlaces siguen vivos, luego qué grupos de nodos
  se ven entre sí, luego cuál grupo puede tomar decisiones por todos, luego quién es el
  responsable legítimo, luego qué clase de dato puede confirmar cada grupo y qué servicios
  quedan degradados.
- **Qué debe contestar.** Por cada dato, quién puede confirmar escrituras y quién no, con
  la regla que lo decide; a quién se le falla (urgencias, consulta externa o la
  farmacia), qué le cuesta y qué regla perdió; y qué tendría que ser cierto para que el
  Sótano pudiera seguir escribiendo controlados.
- **Por qué es lógica.** La prioridad entre «no perder un registro» y «no quedar sin
  escribir» se declara una vez, por tipo de dato, y se aplica igual a cualquier corte.

### Situación 4 — Regresa con la libreta vieja

- **Qué pasa.** El enlace se repara y el Sótano regresa tras cuarenta minutos aislado. En
  ese tiempo, urgencias registró ingresos provisionales; consulta externa asignó una cama
  que urgencias también había asignado y añadió una alergia al expediente de un paciente
  que urgencias, con el expediente viejo, ya había medicado. Hay un paciente en riesgo.
- **Qué datos hay.** Lo escrito por cada lado durante la separación, con la versión de
  cada nodo, el momento de la separación y el momento del regreso.
- **Qué debe deducir.** Qué escrituras del Sótano se apoyaron en datos ya vencidos; qué
  registros se pueden combinar sin conflicto; cuáles chocan (dos pacientes en una cama);
  cuáles tocan a un paciente de verdad; y quién puede mandar mientras no se ponga al
  corriente.
- **Qué debe contestar.** Para cada escritura del Sótano: se acepta, se acepta con aviso,
  se rechaza o necesita decisión de una persona (y de cuál); a qué paciente avisar
  primero; y qué le falta al Sótano para volver a responder consultas críticas.
- **Por qué es lógica.** Quien regresa tiene más registros y, aun así, va atrasado: la
  versión no se lee por cantidad ni por hora, se razona sobre lo que cada lado sabía.

### Situación 5 — ¿Se entregó dos veces?

- **Qué pasa.** La autoridad sanitaria pregunta si cierta receta de un controlado se
  entregó una o dos veces la noche del corte. Entre que se partió la red y los nodos se
  dieron cuenta pasó un rato en que cada lado creía mandar. Hay una entrega registrada en
  el Sótano y otra en la Torre, y el reloj de la Torre iba adelantado 5 segundos. Hay una
  sanción en juego y la confianza de la farmacéutica.
- **Qué datos hay.** Los registros de entrega de cada nodo con su instante y su folio, el
  desfase conocido de cada reloj, los latidos de esa noche y el conteo físico del
  gabinete (que quizá aún no se hace).
- **Qué debe deducir.** Si ambos registros son una misma entrega copiada o dos entregas
  distintas; cuál ocurrió primero y si las horas alcanzan para saberlo; si hubo un
  momento en que dos nodos se creyeron responsables; y si la hipótesis «se entregó dos
  veces» queda confirmada, refutada o sin evidencia.
- **Qué debe contestar.** «Sí», «no» y «no lo sé», cada una con sus razones; la primera
  entrada que rompe la historia; y qué dato (el conteo, una firma) saldría de la duda.
- **Por qué es lógica.** Dos relojes que difieren no se promedian: se razona qué órdenes
  de los hechos son posibles. Y «no hay registro» no es «no ocurrió».

## Por qué no basta un script

Con `if not nodo.responde(): promover_lider()` resuelves un clúster con un solo testigo,
una red perfecta y un solo tipo de dato. Tu gemelo debe contestar, **con las mismas
reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Se nombra ya otro responsable de los controlados? | decisión |
| ¿Por qué la Torre no cuenta como caída? | explicación |
| ¿Qué repartos de copias cumplen el reglamento? | todas las respuestas |
| ¿Qué tendría que ser cierto para que el Sótano escribiera controlados? | la pregunta al revés |
| ¿Qué pasaría si el convenio de Mexicali venciera una hora antes? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir el clúster y sus enlaces en un instante?
2. Si nadie mide «partición», ¿de qué hechos se deduce quién está con quién?
3. Cuando «no perder un registro» choca con «no dejar a urgencias sin escribir», ¿dónde
   queda escrito cuál gana, y para cuál dato?
4. ¿Cómo distingue tu gemelo «el nodo murió» de «no sé si el nodo murió»?
5. En Erlang viste monitoreo de nodos, latidos y réplica de estado. ¿Qué de eso podría
   alimentar a este gemelo, y qué decide el gemelo que un monitor de nodos no puede?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del clúster, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar latidos y escrituras
  simulados o graficar.

## Supuestos de esta extensión

- Inventado por esta extensión, no por el original: el hospital, los nodos y sus sitios,
  los cinco datos, las personas, el convenio de Mexicali, capacidades y tamaños (unidades
  arbitrarias que fijas tú) y el reglamento (a)-(g). Son datos del ejercicio, no hechos
  del mundo. Las cantidades de los ejemplos (los cuarenta minutos, la receta, la cama)
  son ilustrativas.
- Escala reducida: 3 nodos y 5 datos. El original pide 2 o 3 nodos y un servicio sencillo.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir. Las fallas y los retardos no se sortean en las reglas: entran como
  hechos.
- Tú defines y declaras como supuesto: cuánto silencio vuelve sospechoso a un nodo (el
  original da ~60 s como valor por omisión del latido, no como regla); cuándo un desfase
  de reloj impide ordenar dos hechos; qué clase de dato prefiere consistencia y cuál
  disponibilidad; qué se acepta de un nodo que regresa; qué fuente pesa más cuando dos
  se contradicen; y qué regla gana en cada choque.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Actualizar los nodos de uno en uno sin dejar al clúster sin mayoría.
- Qué pasa con solo dos nodos cuando se pierde uno y por qué ya no hay forma de decidir.
- Copias de seguridad fuera de línea y cuánto tiempo de datos se aceptaría perder.

---
*Las cifras de dominio (latidos de ~60 s, latencia menor a 1 ms en red local y de 50 a
200 ms entre ciudades, reloj adelantado 5 s) son de referencia y vienen del problema
original: verifica la fuente vigente antes de citarlas. El hospital, las personas, las
capacidades y el reglamento son inventados.*
