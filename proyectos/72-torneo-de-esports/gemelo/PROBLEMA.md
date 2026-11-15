# #72 — Torneo de esports: gemelo digital con programación lógica

> Extensión del proyecto #72. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el torneo: partidas que pasan de programada a en juego y
a finalizada, resultados que llegan de varios clientes, un marcador en vivo. Esa
simulación responde «¿cómo va el cuadro?». El organizador necesita algo más: «¿quién
juega ahora contra quién, qué se cae si corrijo este resultado, y por qué?».

El gemelo digital es el **modelo lógico** del torneo: hechos que reflejan su estado y
reglas que reflejan cómo se decide en él. Se escribe en Prolog porque el cuadro no es una
lista sino un árbol (en doble eliminación, dos árboles cruzados): hay que recorrerlo en
ambos sentidos, justificar cada avance y saber decir «todavía no se sabe».

## El torneo que se clona

Un torneo regional de esports en doble eliminación, reducido a 12 equipos, 3 mesas de
juego y 2 árbitros. Con 12 el cuadro no es potencia de 2, a propósito.

| Parte | Contenido |
|---|---|
| Entidades | equipos, partidas (cuadro de ganadores, de perdedores o final), mesas, árbitros |
| Estructura | cada partida alimenta a otra con su ganador y, en doble eliminación, con su perdedor |
| Estado por partida | quién la alimenta, qué equipos tiene (o «por definir»), formato de la serie (mejor de 1, 3 o 5), mesa, árbitro, estado, marcador y reportes recibidos |
| Estado por equipo | partidas jugadas, derrotas, si fue descalificado |
| Eventos | se programa una partida, empieza, un equipo reporta un resultado, un árbitro lo confirma o corrige, un equipo no se presenta, se descalifica a un equipo |
| Decisiones | ¿quién juega la siguiente?, ¿qué partidas pueden empezar ya?, ¿qué resultado vale?, ¿qué se anula si algo se corrige?, ¿es creíble lo que dice el sistema? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original (sus casos difíciles y su escenario a simular); en
cada una añadimos un ángulo de decisión. Tu gemelo debe llegar a una decisión **y poder
explicarla**.

### Situación 1 — El resultado que ya viajó

- **Qué pasa.** Un resultado de la primera ronda se reportó mal: avanzó el equipo
  equivocado. Ese equipo ya jugó dos partidas más, y el que perdió por error bajó al
  cuadro de perdedores, donde ya fue eliminado. Hoy el árbitro corrige el resultado.
  Alguien se juega su lugar en el torneo; el premio no se reparte hasta cerrar el cuadro.
- **Qué datos hay.** La estructura del cuadro, los resultados con su instante y quién jugó
  cada partida. Ningún dato dice «esta partida ya no vale».
- **Qué debe deducir.** Qué partidas, en ambos cuadros, tuvieron como participante (directo
  o por herencia) a un equipo que no debía estar ahí; cuáles resultados siguen valiendo
  porque no dependían de la corrección; y en qué estado queda cada equipo.
- **Qué debe contestar.** La lista de partidas anuladas, cada una con el camino que la
  conecta con la corrección, y el cuadro resultante. Lo intuitivo es «cambio el ganador de
  esa partida y listo». Es sospechoso: un equipo que ya se había ido a casa puede volver a
  estar vivo.
- **Por qué es lógica.** Una corrección es un cambio en la raíz de una cadena de «depende
  de»; el efecto se calcula siguiendo las aristas, y la explicación es el camino.

### Situación 2 — Los dos dicen que ganaron

- **Qué pasa.** Ambos equipos de una partida reportan que ganaron; además uno de ellos ya
  había reportado lo contrario poco antes. Mientras llega el árbitro, hay una mesa
  libre, un rival esperando en la partida siguiente y un tercer equipo del cuadro de
  perdedores que no sabe si le toca jugar hoy.
- **Qué datos hay.** Los reportes con su autor y su instante, el árbitro asignado y la
  estructura que sale de esa partida. Nadie sabe todavía quién ganó.
- **Qué debe deducir.** Que la partida está en disputa y no «ganó A» ni «ganó B»; qué
  partidas quedan en «por definir» siguiendo la cadena (ganador desconocido, luego la
  siguiente de ganadores, luego la de perdedores que recibiría al perdedor), y cuáles
  pueden seguir sin esperar.
- **Qué debe contestar.** Para cada resultado posible, qué partidas resultarían; qué puede
  jugarse ya sin riesgo; y, si la regla del torneo permite o no programar con un ganador
  provisional, a quién se le falla: al rival que espera de pie o a los equipos en disputa.
  Dos partes tienen razón y la regla debe decidir y justificar.
- **Por qué es lógica.** «No se sabe» no es «no»: se propaga por el árbol y se distingue de
  lo que sí se sabe.

### Situación 3 — Descalificado a media ronda

- **Qué pasa.** A media ronda se descalifica a un equipo. Su partida iba en el segundo mapa
  de una serie al mejor de 3 con el marcador 1-0. Antes, ese equipo eliminó a otro en una
  ronda previa. En una liga escolar hay becas en juego para quien llegue lejos.
- **Qué datos hay.** El evento de descalificación con su instante, el estado y el marcador
  de la serie, el historial de a quién eliminó y el cuadro.
- **Qué debe deducir.** Qué secuencia de estados es válida para la partida que iba en
  curso; que su rival avanza; que el descalificado no cae al cuadro de perdedores como si
  hubiera perdido; qué partidas dejan de tener sentido; y qué pasa con quien perdió contra
  él antes.
- **Qué debe contestar.** El estado de cada partida afectada y, para el eliminado
  anteriormente, si regresa o no. El original no da esa política: la fijas tú en «Supuestos»
  y tu gemelo la aplica y explica a quién le falla (al que reingresa o a los que ya jugaron
  sin él).
- **Por qué es lógica.** Hay secuencias de estados permitidas y prohibidas; una excepción
  (la descalificación) recorta ramas del cuadro sin cambiar las reglas de las demás.

### Situación 4 — Doce equipos y ninguna ronda perfecta

- **Qué pasa.** Con 12 equipos, algunos pasan directo (*byes*). Un espectador pregunta en
  qué ronda va cada equipo; el organizador, cuántas partidas se jugarán de verdad.
- **Qué datos hay.** Los equipos, las partidas, quién alimenta a quién y quiénes entran
  directo a una partida. Ningún dato mide «ronda». Un *bye* no es una victoria.
- **Qué debe deducir.** La ronda de cada equipo según su camino; la diferencia entre «no
  tiene rival porque pasó directo» y «su rival aún no está definido»; y cuántas partidas
  reales quedan por jugar.
- **Qué debe contestar.** Ronda y rival (o su ausencia) por equipo, el total de partidas
  reales y por qué. Lo intuitivo es «un *bye* ahorra una partida». Contrástalo con la regla
  de las dos derrotas del original antes de creerlo.
- **Por qué es lógica.** La ronda se deduce de la posición en el árbol, y «sin rival» y
  «rival por definir» son respuestas distintas.

### Situación 5 — La mesa que dos partidas quieren

- **Qué pasa.** Dos partidas listas necesitan la misma mesa, o al mismo árbitro. El
  sistema marca a un equipo como *no-show* en una de ellas. Un equipo eliminado por no
  presentarse no se recupera, y los espectadores esperan ver el cuadro avanzar.
- **Qué datos hay.** Mesas, árbitros, quién alimenta a cada partida, los estados y la hora
  en que se programó cada una.
- **Qué debe deducir.** Qué partidas están listas (alimentadoras terminadas, equipos
  definidos, sin disputa); cuáles se estorban; y si el *no-show* es del equipo o de la
  organización, porque la partida nunca pudo empezar.
- **Qué debe contestar.** Todos los órdenes válidos para usar las mesas y los árbitros; el
  que más partidas desbloquea; y la causa del *no-show*. Si no hay ningún orden válido,
  debe decirlo y señalar el choque.
- **Por qué es lógica.** Es asignar recursos sobre un árbol de dependencias: las
  restricciones se declaran y el sistema busca todas las soluciones.

## Por qué no basta un script

Con `if reporte_a == reporte_b: avanzar(ganador)` resuelves una partida sin conflictos.
Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Quién juega la partida 9? | decisión |
| ¿Por qué el equipo X sigue en el torneo? | explicación |
| ¿Qué partidas pueden empezar ahora con las mesas libres? | todas las respuestas |
| ¿Qué tendría que pasar para que X llegue a la final? | la pregunta al revés |
| ¿Qué se anula si se corrige el resultado de la partida 3? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco consultas
sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir el cuadro y una partida en un instante?
2. Cuando un resultado cambia, ¿cómo sabe tu gemelo qué depende de él?
3. ¿Cómo distingue «no hay rival», «el rival aún no se define» y «hay una disputa»?
4. ¿Qué parte de la explicación le sirve al organizador y qué parte es ruido?
5. ¿Qué parte de tu simulación en Erlang (el gen_statem de cada partida, la disputa del
   resultado reportado dos veces) alimentaría a este gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del torneo, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar resultados simulados o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 12 equipos y 3 mesas, contra los 64 equipos y 8 mesas del escenario
  original. Los 2 árbitros, los nombres de equipos y los números de partida de los
  ejemplos son del ejercicio.
- El «ahora» es un hecho del modelo, no el reloj del sistema (minutos desde que abre el
  torneo), para que las respuestas se puedan repetir.
- Tú defines: cómo se numera el cuadro, dónde caen los *byes*, el formato de cada serie,
  quién arbitra qué, y los instantes de los eventos.
- El original no dice qué pasa con quien perdió contra un equipo luego descalificado, ni
  si se programa con un ganador provisional, ni cuánto espera una partida sin mesa antes
  de que un *no-show* sea justo: son decisiones tuyas, y tu gemelo debe explicarlas.
- La serie al mejor de 3 con marcador 1-0 (situación 3), las «dos partidas más» (1) y la
  liga escolar con becas (3) son datos del ejercicio, no del original.

## Extensiones posibles

Para quien quiera ir más lejos. No vienen del problema original: investiga y cita tus
fuentes antes de fijar cifras.

- Formatos suizo y de grupos.
- Sembrado para que los favoritos no se enfrenten pronto.
- Reinicio del cuadro cuando gana quien llegó por el cuadro de perdedores.
- Apelaciones sobre una descalificación.
- Priorizar qué partida se transmite según el público que la espera.

---
*Las cifras (N−1 y 2N−2 partidas, series al mejor de 1, 3 o 5, 64 equipos, 8 mesas)
vienen del problema original; la escala reducida, los árbitros y las políticas de los
Supuestos son de este ejercicio. Verifica la fuente vigente antes de citarlas.*
