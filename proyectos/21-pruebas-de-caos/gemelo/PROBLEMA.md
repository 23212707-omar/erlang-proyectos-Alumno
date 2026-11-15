# #21 — Pruebas de caos: gemelo digital con programación lógica

> Extensión del proyecto #21. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang mataste procesos a propósito y mediste si el sistema se levantaba.
Esa simulación responde «¿se recuperó?». Quien firma el permiso para provocar una falla
en un negocio que está vendiendo necesita algo más: «¿se puede hacer hoy, en qué orden,
cuándo se detiene, y quién responde si sale mal?».

El gemelo digital es el **modelo lógico** de la plataforma y de su programa de
simulacros de falla: hechos que reflejan su estado y reglas que reflejan cómo se decide
en él. Se escribe en Prolog porque aquí no se calcula: se revisa si una secuencia de
eventos deja sano al sistema, se justifica cada permiso y se sabe decir «no lo sé».

## La plataforma que se clona

«Botica Frontera» es una cadena de farmacias de Tijuana con pedidos en línea y entrega
a domicilio. **No existe: es un escenario planteado por esta extensión**, no por el
problema original. Se reduce a 6 servicios, 1 base de datos de pedidos y 3 simulacros.

| Parte | Contenido |
|---|---|
| Entidades | servicios (catálogo, precios, carrito, pagos, recetas, despacho) y la base de datos; instancias de cada servicio (pagos tiene principal y respaldo; precios, una sola); simulacros con sus pasos; pedidos reales y de prueba |
| Personas | la ingeniera de confiabilidad (propone), el gerente de operaciones (autoriza), la guardia en turno (vigila y captura la bitácora), la responsable sanitaria (recetas) y una clínica con contrato de entrega urgente |
| Estado por servicio | criticidad, de qué servicios depende, si guarda datos solo en memoria (carrito y precios sí), qué instancias están en pie y lo que el monitor midió de él |
| Estado por simulacro | su etapa: propuesto → autorizado → en curso → terminado o abortado → verificado → cerrado; y sus pasos, cada uno una falla contra un blanco |
| Eventos | se propone, autoriza, inicia, aborta o cierra un simulacro; se aplica o se retira un paso; cae o reinicia una instancia; se crea, cobra, surte o entrega un pedido; dirección publica una ventana del calendario |
| Decisiones | ¿se inicia hoy?, ¿en qué orden van los pasos?, ¿abortar, terminar el paso o seguir?, ¿ya se recuperó?, ¿se puede cerrar?, ¿qué pasó en realidad? |
| Reglamento de simulacros (inventado) | (a) nadie inicia sin autorización vigente, guardia en turno y botón de aborto probado; (b) solo hay un simulacro abierto a la vez; (c) en congelamiento (Buen Fin) no hay simulacros, y en quincena solo los que no alcanzan a pagos; (d) un servicio crítico nunca se queda sin instancias en pie ni sin sus requisitos; (e) los pedidos reales no se tocan y el cliente real va primero; (f) un simulacro se cierra hasta comprobar que el servicio volvió a ser útil, no solo que está vivo |

## Situaciones que tu gemelo debe razonar

Las cinco las plantea esta extensión. La 2 y la 3 retoman casos y datos del problema
original («recuperado», estado en memoria, radio de explosión, sus fallas); la 1, la 4
y la 5 son nuevas. En cada una, tu gemelo debe decidir **y poder explicar la decisión**.

### Situación 1 — ¿Se lanza hoy o no?

- **Qué pasa.** La ingeniera quiere iniciar hoy el simulacro 2. Se autorizó ayer, pero
  anoche dirección adelantó el congelamiento, hoy es quincena y el simulacro 1 sigue sin
  cerrar. Si tumba pagos en quincena se pierden ventas y se cancela el programa; si se
  pospone sin razón, se llega al Buen Fin sin haber probado nada.
- **Qué datos hay.** Los eventos de cada simulacro, las ventanas del calendario y cuándo
  se publicaron, los turnos de guardia, los pasos y las dependencias.
- **Qué debe deducir.** La etapa de cada simulacro; hasta qué servicios llega el radio
  de explosión del 2, siguiendo las dependencias desde sus blancos; qué reglas aplican
  hoy y si una autorización dada con el calendario de ayer sigue siendo válida.
- **Qué debe contestar.** Iniciar, posponer o pedir nueva autorización; cada condición
  que lo impide; y el primer momento en que sí podría iniciarse.
- **Por qué es lógica.** La misma solicitud recibe respuestas distintas según la etapa
  y el día, y el radio de explosión no está escrito en ningún lado: se deduce.

### Situación 2 — Todo en verde y nadie recibe su pedido

- **Qué pasa.** En el simulacro 1 se mató la instancia de carrito. Reinició sola, el
  tablero quedó en verde y la ingeniera quiere cerrarlo. Pero carrito guarda todo en
  memoria: hay clientes a los que ya se les cobró un pedido que nadie va a surtir.
- **Qué datos hay.** Caídas y reinicios, lecturas del monitor, qué servicios guardan
  en memoria, dependencias y los eventos de cada pedido. Ninguno dice «recuperado».
- **Qué debe deducir.** En cadena: la instancia reinició, luego su memoria está vacía;
  luego los pedidos a medio camino perdieron su carrito; luego hay cobros sin surtido
  posible; luego el servicio está vivo pero no es útil; luego el simulacro no puede
  cerrarse, y por la regla (b) el simulacro 2 tampoco puede iniciar.
- **Qué debe contestar.** Por servicio: recuperado, no recuperado o no se sabe; qué
  pedidos quedaron huérfanos y a qué clientes hay que buscar; y qué falta para cerrar.
- **Por qué es lógica.** «Recuperado» no lo mide nadie: se concluye de varios hechos, y
  lo que el tablero sugiere (verde = bien) es justo lo incorrecto.

### Situación 3 — El orden de los golpes

- **Qué pasa.** El simulacro 3 tiene tres pasos: matar la instancia principal de pagos;
  añadir 500 ms de latencia y 20 % de pérdida a la conexión con la base de datos; y
  dejar a precios, «el servicio chico», muriendo cada 2 segundos. Lo intuitivo es
  empezar por el chico. Pero precios no tiene respaldo y de él dependen catálogo,
  carrito y recetas: falla pequeña, efecto dominó. Si recetas cae, hay pacientes sin
  medicamento controlado y la responsable sanitaria responde por ello.
- **Qué datos hay.** Pasos, instancias, dependencias, criticidad y el radio autorizado.
- **Qué debe deducir.** Para cada orden posible de los pasos, cómo queda la plataforma
  tras cada uno y si en algún momento se rompe el reglamento: un crítico sin instancias
  o sin requisitos, un paso sobre un daño que aún no sana, un radio mayor al autorizado.
- **Qué debe contestar.** Todos los órdenes que dejan sano al sistema; para los demás,
  el primer paso que lo rompe y por qué; y si ninguno sirve, qué paso sobra.
- **Por qué es lógica.** La misma descripción de «qué provoca cada falla» sirve para
  revisar una secuencia propuesta y para generar todas las válidas.

### Situación 4 — Abortar ya, o terminar el paso

- **Qué pasa.** A mitad del simulacro 3, con pagos en el respaldo y las dos copias
  sincronizándose, entra un pedido urgente real de la clínica. El gerente ordena
  abortar: el cliente real va primero y el contrato penaliza la entrega tardía. La
  ingeniera se opone: cortar a media sincronización deja dos copias de pagos con
  historias distintas, y sin evidencia se llega a ciegas al Buen Fin. Ambos con razón.
- **Qué datos hay.** Los eventos del simulacro y de la sincronización, el pedido de la
  clínica con su plazo, el estado de cada instancia y el calendario.
- **Qué debe deducir.** Desde la etapa actual, qué movimientos son válidos (abortar,
  terminar el paso y después abortar, continuar), cuál deja sano al sistema, qué regla
  prevalece cuando (e) choca con dejar los datos íntegros, y a quién se le falla.
- **Qué debe contestar.** La decisión, la regla que perdió, a quién se le falla y qué le
  cuesta; y qué tendría que ser cierto para que abortar de inmediato fuera seguro.
- **Por qué es lógica.** Abortar no siempre es la salida segura: depende de la etapa.
  Y la prioridad entre reglas se declara una vez, no se improvisa bajo presión.

### Situación 5 — La bitácora y el monitor no cuentan lo mismo

- **Qué pasa.** La clínica reclama la penalización por un pedido que llegó tarde. La
  bitácora, capturada a mano por la guardia, dice que el paso ya se había retirado; el
  monitor muestra errores después de esa hora, tiene un hueco sin datos (viaja por la
  red que el simulacro degradó) y una lectura imposible. Un pedido no tiene marca de
  real ni de prueba. Hay dinero en juego y alguien a quien culpar.
- **Qué datos hay.** Los eventos según cada fuente, con su instante; las lecturas del
  monitor y el rango posible de cada indicador; y los pedidos con su marca.
- **Qué debe deducir.** Qué entradas no pudieron ocurrir (un paso retirado antes de
  aplicarse, un inicio sin autorización); si el silencio del monitor es «no hubo
  errores» o «no hay datos»; si la hipótesis quedó confirmada, refutada o sin
  evidencia; y si el retraso del pedido se debe al simulacro.
- **Qué debe contestar.** Tres respuestas distintas: «sí», «no» y «no lo sé»; la primera
  entrada que rompe la historia; y qué dato haría falta para salir de la duda.
- **Por qué es lógica.** «No hay registro de errores» no es «no hubo errores», y dos
  fuentes que se contradicen no se promedian: se razona cuál historia es posible.

## Por qué no basta un script

Con `if servicio.vivo(): cerrar(simulacro)` resuelves un servicio sin memoria ni
dependencias y un monitor que nunca falla. Tu gemelo debe contestar, **con las mismas
reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Se puede iniciar hoy el simulacro 2? | decisión |
| ¿Por qué no se puede cerrar el simulacro 1? | explicación |
| ¿En qué órdenes pueden ir los tres pasos del simulacro 3? | todas las respuestas |
| ¿Qué tendría que ser cierto para que abortar ahora fuera seguro? | la pregunta al revés |
| ¿Qué pasaría si el congelamiento empezara un día antes? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir un simulacro y la plataforma en un instante?
2. Si la etapa de un simulacro no se guarda, ¿de qué eventos se deduce?
3. Cuando «el cliente real va primero» choca con «no dejar datos a medias», ¿dónde
   queda escrito cuál gana?
4. ¿Cómo distingue tu gemelo «no hubo errores» de «no sé si hubo errores»?
5. En Erlang viste reinicios, intensidad agotada y tiempos de recuperación. ¿Qué de eso
   podría alimentar a este gemelo, y qué decide el gemelo que un supervisor no puede?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la plataforma, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar eventos y lecturas
  simulados o graficar.

## Supuestos de esta extensión

- Inventado por esta extensión, no por el original: «Botica Frontera», sus servicios y
  dependencias, las personas, la clínica y su contrato, el calendario, las etapas del
  simulacro y el reglamento (a)-(f). Son datos del ejercicio, no hechos del mundo.
- Escala reducida: 6 servicios, 1 base de datos y 3 simulacros de hasta 3 pasos. El
  original no fija escala: pide experimentar contra otro proyecto del curso.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir. Las fallas no se sortean en las reglas: entran como hechos.
- Tú defines y declaras como supuesto: la banda de «estado estable» de cada indicador y
  cuánto debe sostenerse; el radio autorizado; el plazo y la penalización del contrato;
  cuánto dura una autorización; desde cuándo el silencio del monitor es sospechoso; qué
  fuente pesa más cuando dos se contradicen; y qué regla gana en cada choque.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Presupuesto de error: cuánta falla tolera el mes antes de suspender los simulacros.
- Dos equipos que piden la misma ventana para simulacros que se estorban entre sí.
- Fallas de un proveedor externo (banco, paquetería) que la empresa no puede retirar.
- Obligación de avisar a clientes o a la autoridad sanitaria cuando se afectan recetas.

---
*Las cifras son de referencia y vienen del problema original. El escenario y su
reglamento son inventados: verifica la fuente vigente de toda cifra antes de citarla.*
