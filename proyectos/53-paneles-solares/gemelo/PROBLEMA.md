# #53 — Paneles solares: gemelo digital con programación lógica

> Extensión del proyecto #53. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang montaste la casa solar: un proceso para el inversor, otro para el
consumo y un calculador de balance. Esa simulación responde «¿cuánto produje y cuánto
gasté?». Quien pagó los paneles necesita algo más: «¿mi sistema produce lo que debería,
por qué no, y cuándo me conviene gastar, guardar o inyectar la energía?».

El gemelo digital es el **modelo lógico** de la casa: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque aquí no se suma:
se deduce, se justifica y se sabe decir «no lo sé».

## La casa solar que se clona

Una casa de Tijuana con un sistema de 4 kWp, reducido a 8 paneles en 2 cadenas, un
inversor, un medidor de producción y otro de consumo. Tiene además un acumulador (batería)
y tres equipos grandes que la familia quiere usar: la lavadora, la bomba del tinaco y el
cargador del auto. Los paneles, los equipos y el acumulador son ejemplos de esta
extensión; el sistema de 4 kWp y los datos de producción son los del original.

| Parte | Contenido |
|---|---|
| Entidades | casa → cadena → panel; inversor; medidor de producción y de consumo; acumulador; equipos |
| Estado por panel | potencia (W) y temperatura (°C), cada minuto, con el instante de su medidor |
| Estado de la casa | irradiancia, consumo, carga del acumulador, códigos de falla del inversor, pronóstico |
| Eventos | llega una lectura, el inversor reporta un código, pasa una nube, hay un corte de luz, un equipo arranca |
| Decisiones | ¿es normal esta producción?, ¿qué la baja?, ¿hay excedente de verdad?, ¿qué equipo se enciende y cuándo?, ¿consumir, guardar o inyectar? |

## Situaciones que tu gemelo debe razonar

Cuatro de las cinco salen del problema original. La 5 es derivada: toma del original la
medición neta, el excedente y el desfase entre el pico solar y el de consumo, y del foco
del eje, que hay que decidir entre consumir, almacenar o vender; el acumulador es un
complemento. En cada una, tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — ¿Nube o falla?

- **Qué pasa.** A media mañana la producción cae 70 % y diez minutos después vuelve a
  la normalidad. Otro día, un solo panel produce mucho menos que sus hermanos con el
  cielo despejado, y el inversor no reporta ningún código. Si cada nube se toma por falla,
  el dueño paga visitas del instalador y deja de creer en las alertas. Si una falla real
  se toma por nube, pierde producción semanas sin que nada avise.
- **Qué datos hay.** Potencia y temperatura de cada panel y del inversor con su
  instante, la irradiancia, los códigos de falla y los días anteriores. Ningún dato dice
  «nube» ni «falla».
- **Qué debe deducir.** Cuánto debería producir el sistema con esas condiciones; si la
  caída toca a todos los paneles o a uno, si coincide con una caída de la irradiancia y
  si se recupera. Lo intuitivo es que cuanto mayor la caída, más grave el problema; es
  sospechoso porque una nube grande baja 70 % sin que nada esté roto, y una falla real
  puede quitar poco y durar semanas.
- **Qué debe contestar.** Para cada caída: nube, falla, otra causa o «no lo sé», con la
  evidencia. Si falta la irradiancia de esos minutos, no es «no hay falla»: es «no lo sé»,
  y dice qué dato la resolvería. Nunca alertar por una lectura ausente tratada como cero.
- **Por qué es lógica.** La causa no se mide: se deduce de un patrón, y lo «esperado»
  depende de las condiciones (también del calor: cada °C sobre 25 resta ~0.3-0.4 %), no
  de un número fijo.

### Situación 2 — La baja de la mañana y la baja de las 3

- **Qué pasa.** En primavera la capa marina cubre las mañanas y la producción tarda en
  arrancar; el dueño lo nota y se preocupa. Desde las 3 p. m., con cielo despejado, un
  panel cae todos los días. Además hay semanas sin lluvia y polvo en todo el arreglo.
  Si se culpa al panel equivocado se lava, se reclama la garantía o se discute con el
  vecino por una sombra que no era, y la pérdida real sigue.
- **Qué datos hay.** Producción por panel con su instante, varios días de historia, el
  cielo y la temperatura de cada hora. Ningún dato dice «sombra», «suciedad» ni
  «capa marina».
- **Qué debe deducir.** Cuál baja la explican las condiciones y cuál no; y para la que no,
  qué causa sostienen los datos entre sombra, suciedad y falla, a partir de cuántos
  paneles afecta, a qué hora, desde cuándo y con qué cielo. Lo intuitivo es que la peor
  baja del día, la de la mañana, es el problema; es sospechoso porque la capa marina la
  explica sola, y la única baja que nada explica es la de las 3.
- **Qué debe contestar.** Para cada baja: esperada o anormal; la causa más probable, las
  descartadas y por qué; y si dos causas empatan, decirlo y qué observación las separaría.
- **Por qué es lógica.** Es eliminar hipótesis con evidencia que se combina, y contar
  con que dos causas pueden quedar igual de posibles.

### Situación 3 — Dos relojes, un excedente

- **Qué pasa.** El medidor de producción y el de consumo tienen relojes distintos. Según
  cómo se alineen, parece que sobra energía o que falta. Un corte de luz de la semana
  pasada lo registraron ambos, cada uno a su hora. Hoy una recomendación de «enciende la
  lavadora» nace de un excedente que quizá no existe, y esa energía se compra a la red.
- **Qué datos hay.** Producción y consumo, cada uno con el instante de su propio reloj,
  y los eventos que ambos medidores vieron (el corte, el arranque de un equipo grande).
  Ningún dato dice «el desfase es tanto».
- **Qué debe deducir.** Si hay desfase y de qué tamaño, a partir de eventos que vieron
  los dos; si es el mismo a lo largo del día; y qué excedente se puede afirmar con eso.
  Si dos eventos dan desfases distintos, no se inventa uno. Lo intuitivo es que el mismo
  minuto en las dos tablas es el mismo instante; es sospechoso porque justo eso es lo que
  nadie ha comprobado.
- **Qué debe contestar.** Por minuto: excedente seguro, posible o «no lo sé», con el
  evento que alineó los relojes. Si los eventos se contradicen, cuál manda y a quién se
  le falla con esa elección.
- **Por qué es lógica.** El desfase es una conclusión, no un dato, y la respuesta honesta
  tiene tres lados.

### Situación 4 — Tres equipos y un solo mediodía

- **Qué pasa.** Mañana la familia quiere lavar, llenar el tinaco y cargar el auto. El
  excedente se concentra cerca del mediodía, y el consumo de la casa se dispara en la
  tarde y noche. La lavadora debe correr completa sin interrumpirse; el cargador puede
  partirse en ratos, pero el auto debe estar listo para la mañana siguiente; la bomba debe
  terminar antes de que la familia vuelva. No caben los tres en el mismo pico. El pronóstico
  dice «despejado», pero ayer dijo lo mismo y la capa marina se quedó hasta pasado
  mediodía. Quien necesita la ropa y quien necesita el auto tienen razón.
- **Qué datos hay.** El pronóstico con la hora en que se emitió y cómo le fue los días
  anteriores, la producción esperada por hora, y de cada equipo su tipo y su plazo.
  Ningún dato dice «aquí cabe la lavadora».
- **Qué debe deducir.** Cuánto excedente se espera por hora y qué tan firme es; qué
  repartos cumplen el tipo y el plazo de cada equipo; cuáles siguen siendo buenos si el
  pronóstico falla y cuáles solo valen si acierta. Lo intuitivo es poner todo en la hora
  que el pronóstico llama la mejor; es sospechoso porque ese pronóstico ya falló y porque
  los equipos compiten por el mismo pico.
- **Qué debe contestar.** Un reparto con su explicación y, al pedir más, los demás
  repartos válidos. Si ninguno cumple todo, quién cede, por qué y qué cuesta. Qué
  recomendaciones se callan por no ser confiables: eso es lo que separa un consejo útil
  del ruido.
- **Por qué es lógica.** Es asignar con plazos y con tipos de equipo, y cada recomendación
  carga las condiciones bajo las cuales vale.

### Situación 5 — Consumir, guardar o inyectar

- **Qué pasa.** Pasado el mediodía, la casa produce más de lo que consume y el acumulador
  está a medias. Cada kWh sobrante puede usarse en ese momento, guardarse o inyectarse a
  la red, donde la medición neta lo compensa con lo que se consuma después. Al
  atardecer, el aire acondicionado y la cocina pican el consumo. A las 3 p. m. el panel
  con sombra producirá menos. Esta semana hubo un corte de luz: quien teme otro quiere
  reserva en el acumulador; quien mira el recibo quiere inyectar y compensar.
- **Qué datos hay.** La producción esperada del resto del día, el consumo habitual de la
  tarde y noche, la carga del acumulador con su instante (que puede ser vieja) y la lista
  de equipos. Ningún dato dice «guarda esto».
- **Qué debe deducir.** En cadena: cuánta producción queda por delante, con la sombra
  incluida; cuánto excedente deja eso; si el acumulador alcanzará a llenarse; y qué
  parte del consumo de la noche cubriría. De ahí, qué destino le toca a lo que sobra
  ahora.
- **Qué debe contestar.** Por momento: consumir, guardar o inyectar, con su razón y qué
  prioridad (reserva o ahorro) la decidió; qué cambiaría si el pronóstico falla o la
  sombra llega antes. Si la carga del acumulador es vieja, lo dice en lugar de decidir
  como si fuera cierta.
- **Por qué es lógica.** Tres destinos compiten por lo mismo, la prioridad se declara una
  sola vez y la conclusión se sostiene en varias deducciones encadenadas.

## Por qué no basta un script

Con `if produccion < esperado * limite: llamar_instalador()` resuelves un panel con datos
perfectos. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué hago con el panel 5? | decisión |
| ¿Por qué lo atribuyes a la sombra y no a la suciedad? | explicación |
| ¿Qué paneles están hoy por debajo de lo esperado? | todas las respuestas |
| ¿Qué tendría que cambiar para poder encender la lavadora a las 11? | la pregunta al revés |
| ¿Qué pasaría si mañana hay capa marina hasta mediodía? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para decir cuánto debería producir el sistema en un minuto?
2. ¿Cuándo una recomendación es útil y cuándo es ruido, y dónde queda escrito?
3. Si los dos relojes no coinciden, ¿qué afirma tu gemelo y qué deja como «no lo sé»?
4. ¿Cómo distingue tu gemelo «no hay falla» de «no sé si hay falla»?
5. En tu prueba de caos el inversor cae y el balance marca producción 0 con alerta, sin
   inventar datos: ¿cómo distingue tu gemelo un cero medido de un cero por falta de dato?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la casa, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar lecturas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 8 paneles en 2 cadenas, con el sistema de 4 kWp del original. La
  lectura por panel y la irradiancia son datos que añade esta extensión: el original
  solo dice que el inversor reporta potencia, voltaje, corriente, temperatura y fallas.
- El acumulador, los tres equipos, el panel 5, el corte de luz y el «ayer» del pronóstico
  son ejemplos de esta extensión. El acumulador sale del foco del eje, no del original.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir; la unidad que más sirve es el minuto desde la medianoche.
- Los datos son cada minuto, como en el escenario original; el desfase entre relojes no
  está dado: es lo que deduces.
- Defines tú, con su fuente: cómo se calcula la producción esperada, cuánta diferencia
  vuelve anormal una baja, cuántos días de historia usas, cuándo un cielo cuenta como
  capa marina, cuánto desfase toleras, cuánta fe le das a un pronóstico, qué reserva
  mínima guarda el acumulador y qué horas son de consumo alto.
- El original no da tarifas ni cómo se compensa la energía por periodos: tu gemelo no
  calcula pesos. Si una regla lo necesita, es tu supuesto, con fuente.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Cuándo conviene lavar los paneles frente a lo que cuesta dejarlos sucios.
- Tarifas por horario y cómo cambiarían el reparto de equipos.
- Degradación de los paneles con los años y qué cubre la garantía.
- Cuántos paneles o qué capacidad de acumulador más compensaría la ampliación.
- Una ola de calor que sube el consumo del aire acondicionado y baja el rendimiento.

---
*Las cifras de dominio (4 kWp, 70 % por 10 minutos, sombra desde las 3 p. m., 0.3-0.4 %
por °C, un dato por minuto) vienen del problema original y son de referencia; verifica la
fuente vigente antes de citarlas. Los paneles, equipos y acumulador son de esta extensión.*
