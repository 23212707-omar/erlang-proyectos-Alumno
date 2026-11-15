# #60 — Restaurante: gemelo digital con programación lógica

> Extensión del proyecto #60. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el restaurante: meseros que toman comandas, estaciones de
cocina que las preparan, mesas que se ocupan y se liberan, y fallas inyectadas. Esa
simulación responde «¿qué está pasando en el salón y en la cocina?». Quien dirige el
servicio necesita algo más: «¿a quién siento, qué cocino primero, qué prometo y a quién
le fallo si no alcanza?».

El gemelo digital es el **modelo lógico** del restaurante: hechos que reflejan su estado
y reglas que reflejan cómo se decide en él. Se escribe en Prolog porque lo que hay que
resolver aquí no es contar comandas, sino repartir recursos que no alcanzan (mesas,
estaciones, minutos), seguir el ciclo de vida de cada comanda y justificar cada reparto.

## El restaurante que se clona

Un restaurante de Tijuana en hora pico, reducido a 8 mesas, 4 estaciones y 3 meseros, en
un tramo del servicio de alrededor de una hora.

| Parte | Contenido |
|---|---|
| Entidades | mesa (con su capacidad y su sección) → mesero; grupo de clientes; comanda → partida (platillo); estación; platillo con sus ingredientes agotables |
| Estado por mesa | libre u ocupada, grupo sentado, comandas abiertas, si ya pidió la cuenta, qué mesas pueden juntarse con ella |
| Estado por comanda | etapa (tomada, en cocina, lista, servida), partidas, modificadores y alergias, instante de cada cambio de etapa |
| Estado por estación | disponible o fuera de servicio, cola de partidas, tiempo de preparación de cada platillo |
| Estado del sistema | existencias de cada platillo (puede estar sin contar), grupos en espera |
| Eventos | llega un grupo, se toma una comanda (a veces dos veces), se envía a cocina, una estación termina, se agota un platillo, la mesa cambia su pedido, se cae una estación, se pide la cuenta |
| Decisiones | ¿en qué mesa siento a este grupo?, ¿qué estación arranca qué y cuándo?, ¿qué comanda va primero?, ¿qué platillo se puede seguir ofreciendo?, ¿procede este cambio?, ¿esta comanda es duplicada? |

## Situaciones que tu gemelo debe razonar

Cuatro salen del problema original (la 1, la 2, la 3 y la 5); la 4, la asignación de
mesas, plantea algo que el original no desarrolla y que el foco del proyecto pide. En
cada una, tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — Que todo llegue junto a la mesa 7

- **Qué pasa.** La mesa 7 pide bebidas, una entrada fría, un plato fuerte a la parrilla
  con guarnición de la freidora, y la mesa quiere que lo caliente salga junto. Cada
  estación ya trae su propia cola y cada platillo tarda distinto. Si el plato fuerte
  sale a destiempo, se enfría o la mesa espera de más; si alguien arranca todo al
  llegar la comanda, la cocina se atasca.
- **Qué datos hay.** Las partidas de la comanda, la estación que exige cada una, el
  tiempo de preparación de cada platillo (el original da un rango para el plato fuerte),
  lo que ya está en la cola de cada estación y el instante actual. Nada dice «arranca la
  guarnición en tal minuto».
- **Qué debe deducir.** A qué hora debe arrancar cada partida para que las calientes
  salgan sincronizadas, cuál estación marca el ritmo de toda la mesa y si la comanda
  completa cabe en el tiempo objetivo del ticket.
- **Qué debe contestar.** El plan completo (qué estación hace qué y cuándo); las demás
  formas válidas de repartirlo; o, si no hay ninguna que cumpla, que no existe y por qué
  (qué estación o cola lo impide), sin fallar en silencio.
- **Por qué es lógica.** El instante de cada partida se deduce de las demás y de las
  colas ajenas; es un calendario con restricciones, no una cuenta de minutos.

### Situación 2 — Cocina saturada y la freidora se cae

- **Qué pasa.** En el pico la cocina está llena y la freidora deja de servir a media
  operación. Varias comandas la necesitan. Una mesa ya rebasó el tiempo objetivo del
  ticket; otra, de mucha gente, apenas lleva unos minutos pero sus platos ocupan tres
  estaciones a la vez; otra pide solo bebidas y una entrada. No hay manos para todo.
- **Qué datos hay.** Para cada comanda, cuánto lleva esperando, qué estaciones pide, si
  tiene partidas que otra estación podría cubrir, y qué estaciones siguen disponibles.
- **Qué debe deducir.** Qué comandas pueden salir aún dentro de objetivo, cuáles ya no, y
  en qué orden se atiende lo que queda para que el daño total sea el menor.
- **Qué debe contestar.** El orden de la cocina, la justificación de cada lugar y a quién
  se le falla. Lo intuitivo es atender primero la comanda más vieja; aquí esa respuesta
  es sospechosa y el gemelo debe poder decir cuándo sí y cuándo no.
- **Por qué es lógica.** Dos mesas tienen razón al reclamar; la prioridad se declara una
  vez y se justifica con los hechos de cada caso, no con el orden de llegada.

### Situación 3 — El platillo que se agota con seis comandas pendientes

- **Qué pasa.** Se acaba un platillo con 6 comandas que lo piden. Algunas ya se están
  cocinando, otras solo están tomadas y una aún no sale de la mesa del mesero. El menú
  debe dejar de ofrecerlo al instante, pero aún quedan algunas porciones y nadie sabe
  con certeza cuántas: la bodega y la cocina no coinciden. Una de las mesas tiene a un
  comensal con alergia.
- **Qué datos hay.** Las comandas afectadas y su etapa, las existencias según cada fuente
  (o ninguna), los modificadores y alergias de cada partida y los platillos que podrían
  sustituirlo.
- **Qué debe deducir.** Cuántas comandas se pueden cumplir con lo que de verdad queda,
  cuáles quedan protegidas por llevar ya el platillo en marcha, a quién hay que avisar y
  qué sustitutos son seguros para cada mesa.
- **Qué debe contestar.** Una de tres respuestas por comanda (se cumple, no se cumple, no
  se sabe todavía), el aviso al mesero y qué conteo resolvería la duda. Un sustituto que
  rompe una alergia nunca es una respuesta válida, aunque sea el único.
- **Por qué es lógica.** Hay una cadena de conclusiones (se agotó, quién
  depende de él, quién está protegido, cuántas porciones quedan, qué se ofrece) y
  «no hay» no es lo mismo que «no sé si hay».

### Situación 4 — ¿Dónde siento a este grupo y cuándo se libera su mesa?

- **Qué pasa.** Llegan grupos de distinto tamaño y no hay mesas para todos. Algunas
  mesas pueden juntarse, otras no. Cada mesero atiende una sección y no debe quedar
  saturado mientras otro está ocioso. Una mesa ocupada se libera en unos 45 a 90
  minutos, pero nadie lo mide: se ve en lo que ya pidieron, si ya llegó la cuenta, si
  ya se pagó.
- **Qué datos hay.** Capacidad de cada mesa, qué mesas se pueden juntar, las secciones, la
  carga de cada mesero, los grupos en espera con su hora de llegada y los eventos de cada
  mesa ocupada.
- **Qué debe deducir.** Cuándo se liberará, con qué margen, cada mesa ocupada, aun sin
  que nadie lo declare; y qué grupo conviene en cada mesa libre o por liberarse.
- **Qué debe contestar.** El reparto de grupos a mesas, los demás repartos válidos y, si
  alguien no cabe, el motivo. Si una mesa lleva demasiado tiempo sin eventos, el gemelo
  contesta «no lo sé» y qué dato lo aclararía, no una hora inventada.
- **Por qué es lógica.** Asignar es una restricción que compite por mesas, secciones y
  tiempo; y la hora de liberación es una conclusión, no un dato.

### Situación 5 — La comanda duplicada y el cambio a media cocción

- **Qué pasa.** La mesa 4 aparece con dos comandas casi idénticas, tomadas con segundos de
  diferencia: ¿doble toque del mesero o dos personas pidiendo lo mismo? Además, la mesa 9
  cambia su pedido cuando el platillo ya está en la parrilla, y uno de los cambios es por
  una alergia que el comensal olvidó avisar.
- **Qué datos hay.** Los eventos de cada comanda con su instante, la etapa en que va cada
  partida, los modificadores, y qué mesero capturó cada toque.
- **Qué debe deducir.** Si la segunda comanda es duplicado, pedido legítimo o dudosa; si
  el cambio procede según la etapa de la partida, y qué hacer con lo ya cocinado; y
  si la historia de una comanda es posible (nada se sirve antes de estar lista).
- **Qué debe contestar.** La decisión, el siguiente paso válido de la comanda y sus
  alternativas, y quién absorbe el costo de lo desperdiciado. Lo intuitivo es cancelar
  la segunda comanda por parecerse a la primera; hacerlo sin otro hecho puede dejar sin
  comer a una persona, y no hacerlo puede cobrar de más. Con la alergia de por medio, lo
  que está en juego ya no es solo el tiempo.
- **Por qué es lógica.** El ciclo de vida es una secuencia con pasos válidos e
  inválidos, y «es lo mismo» y «parece lo mismo» son conclusiones distintas.

## Por qué no basta un script

Con `cola.sort(key=lambda c: c.minutos_esperando)` ordenas comandas de una sola cocina,
sin estaciones que se caen, sin platillos que se agotan y sin mesas que cambian de
opinión. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué arranco ahora en la parrilla? | decisión |
| ¿Por qué la mesa 7 va detrás de la 4? | explicación |
| ¿Qué comandas van a quedar fuera de objetivo? | todas las respuestas |
| ¿Qué tendría que pasar para que el plato de la mesa 7 salga a tiempo? | la pregunta al revés |
| ¿Qué pasaría si la freidora se cae ahora? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir una mesa y una comanda en un instante?
2. ¿Cómo coordinas varias estaciones para que los platos salgan juntos, y dónde queda
   escrito el reparto?
3. Cuando dos mesas reclaman la misma estación, ¿dónde queda escrito cuál gana y a quién
   se le falla?
4. ¿Cómo distingue tu gemelo «no queda» de «no sé si queda», y «duplicada» de «parecida»?
5. En Erlang cada mesa y cada estación eran procesos, y cada comanda una máquina de
   estados. ¿Qué de eso alimentaría a este gemelo, y qué decide el gemelo que un
   proceso no puede?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del restaurante, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar comandas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 8 mesas, 4 estaciones (parrilla, freidora, fría y barra), 3 meseros y
  un tramo de una hora del servicio, contra las 20 mesas, 5 estaciones, 6 meseros y 3
  horas del escenario original. Las secciones de los meseros, las mesas que se pueden
  juntar, la alergia y los identificadores de los ejemplos («mesa 7», «mesa 4») son del
  ejercicio.
- Qué estación puede cubrir a otra, qué sustituye a qué platillo y qué platos exigen
  sincronía son datos del escenario que tú defines y declaras.
- El «ahora» es un hecho del modelo, en minutos desde un origen fijo, no el reloj del
  sistema. Los tiempos de preparación entran como hechos; las reglas no sortean nada.
- Tú defines: qué valor del rango de 12 a 20 minutos usas para cada plato fuerte, cuánto
  silencio de una mesa la vuelve dudosa, qué tan seguidos deben ser dos toques para
  sospechar un duplicado, cuántas porciones quedan de lo agotado y hasta qué etapa se
  puede cambiar un pedido. El original no da ninguno de esos valores.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Cuenta dividida con artículos compartidos, cortesías y propinas.
- Reservaciones que bloquean mesas con anticipación.
- Un mesero que se ausenta y sus mesas que hay que repartir.
- Platillos que comparten un ingrediente agotable.
- Ajuste del menú de la noche según lo que se agota primero.

---
*Las cifras de dominio (45 a 90 minutos por mesa, 2, 5 y 12-20 minutos de preparación,
tickets de 20-25 minutos fuera de objetivo, 20 mesas, 5 estaciones, 6 meseros, 6
comandas pendientes) vienen del problema original; lo demás (secciones, mesas juntables,
alergia, sustitutos) es del ejercicio. Verifica la fuente vigente antes de citarlas en tu
entrega.*
