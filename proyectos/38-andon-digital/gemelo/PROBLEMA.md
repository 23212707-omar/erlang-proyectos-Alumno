# #38 — Andon digital: gemelo digital con programación lógica

> Extensión del proyecto #38. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el andon: estaciones que llaman, temporizadores que
escalan, procesos que se reconstruyen tras un reinicio. Esa simulación responde «¿se
disparó el aviso a tiempo?». Quien responde por la línea necesita algo más: «¿en qué
punto está esta llamada, a quién le toca, qué puede pasar ahora y quién falló si nadie
vino?».

El gemelo digital es el **modelo lógico** de la planta: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque una llamada no
es un número: es una historia de eventos que debe ser válida, y de ella se deduce en
qué estado está, se justifica cada paso y se sabe decir «no lo sé».

## La planta que se clona

Una maquiladora de Tijuana con andon en cada estación, reducida a 8 estaciones en
2 líneas, de un solo área. La planta y las personas del ejemplo son ilustrativas; los
tiempos de respuesta, la escalera de niveles y los casos difíciles vienen del original.

| Parte | Contenido |
|---|---|
| Entidades | estaciones (cada una en una línea), llamadas, y las personas de la escalera: líder de grupo, supervisor, gerente de área y gerente de planta |
| Personas | 2 líderes por turno, 1 supervisor para las dos líneas, 1 gerente de área, 1 gerente de planta; dos turnos, con cambio de turno a mitad de la operación |
| Estado por llamada | su tipo (ayuda, paro de línea, material, calidad), quién la pulsó, a quién se avisó y quién respondió; su etapa se deduce de sus eventos |
| Estado por estación | el color que muestra su tablero (verde, amarillo, rojo, azul, blanco) y su historial de llamadas falsas |
| Estado por persona | su nivel, su turno y si está atendiendo otra llamada |
| Eventos | se pulsa una llamada, se avisa a un nivel, alguien acusa recibo, llega a la estación, se resuelve o se cancela; la llamada sube de nivel; cambia el turno; el sistema se cae y se levanta |
| Decisiones | ¿en qué etapa y nivel está esta llamada?, ¿a quién le toca ahora?, ¿qué paso sigue y cuál sería inválido?, ¿quién atiende primero?, ¿se puede cerrar?, ¿qué pasó en realidad? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original: sus llamadas sin atender, ocho llamadas
simultáneas, un líder ocupado, la cancelación en pleno escalamiento, el cambio de turno
con llamadas abiertas y el reinicio a mitad de escalamiento. Lo que el original no
dice (quién recibió el aviso y quién lo acusó, los traspasos de turno, el historial de
falsas por estación) lo añade esta extensión como complemento. En cada una, tu gemelo debe llegar a
una decisión **y poder explicarla**.

### Situación 1 — Seis minutos sin que nadie conteste

- **Qué pasa.** La estación 3 pulsa una llamada de paro de línea y durante seis minutos
  nadie la atiende. El tablero sigue en rojo. El sistema registra que se avisó al líder y
  después al supervisor, pero del supervisor nunca llegó un acuse.
- **Qué datos hay.** Los eventos de la llamada con su minuto, los turnos de la escalera,
  el color del tablero y el «ahora». El original da rangos de respuesta (1 a 2 minutos
  para el líder, 5 a 10 para el supervisor); el objetivo exacto lo fijas tú.
- **Qué debe deducir.** En qué etapa y nivel está la llamada, qué avisos ya tuvieron que
  salir y cuáles no, y quién es hoy el responsable. Nadie guarda «nivel actual»: sale de
  la secuencia de eventos, del tiempo corrido y de quién estaba de turno.
- **Qué debe contestar.** La etapa, el nivel, el responsable y los pasos siguientes
  válidos (con sus alternativas); también, un paso que sería inválido y por qué. Si
  según tu objetivo el supervisor aún está a tiempo, debe decirlo.
- **Por qué es lógica.** Cambiar un solo evento o un minuto cambia toda la historia; el
  estado es una consecuencia de la secuencia, no un campo que se actualiza.

### Situación 2 — Dos llamadas, un líder

- **Qué pasa.** Se juntan las llamadas (en el original, ocho a la vez) y un líder queda
  libre para una sola. La de la estación 2 es de calidad, la más antigua, y viene de una
  estación con muchas llamadas falsas. La de la estación 5 detuvo la línea y cada minuto
  parada cuesta cientos o miles de dólares. La otra líder atiende un paro en la línea 2.
- **Qué datos hay.** Tipo y antigüedad de cada llamada, historial de falsas por estación,
  qué líder está libre u ocupado y el supervisor disponible.
- **Qué debe deducir.** A cuál llamada va el líder, qué pasa con la otra y por qué. Es un
  dilema: las dos partes tienen razón y alguien sale perdiendo.
- **Qué debe contestar.** La decisión, las dos reglas en choque, cuál prevaleció, a quién
  se le falla y qué tendría que cambiar para que la decisión fuera la otra. Lo obvio
  (la más antigua primero) es sospechoso: la fila no es lo único que cuenta.
- **Por qué es lógica.** Las prioridades se declaran una vez y valen para ocho
  llamadas o para tres; el desempate también necesita explicación.

### Situación 3 — Cancelada justo cuando sube

- **Qué pasa.** Una llamada llega al momento de escalar y, en ese mismo instante, queda
  registrada una cancelación. El operador dice que fue falsa; el líder dice que ya
  había empezado a revisar. En otro caso, la cancelación se capturó después del aviso al
  supervisor.
- **Qué datos hay.** Eventos con su minuto y su fuente (tablero, persona, captura
  manual), quién pulsó y quién canceló, y si el aviso al supervisor tiene acuse.
- **Qué debe deducir.** Si la cancelación llegó antes o después del escalamiento, si
  quien canceló tenía derecho a hacerlo, y si el aviso al supervisor fue procedente.
- **Qué debe contestar.** «Procedente», «improcedente» o «no se sabe» (por ejemplo, dos
  eventos en el mismo minuto sin orden), con la evidencia, y qué debe pasar con la
  llamada y con el historial de falsas de la estación.
- **Por qué es lógica.** «Se canceló» y «no consta que se haya cancelado a tiempo» no
  son lo mismo, y de ello depende a quién se le carga la falta.

### Situación 4 — La llamada que se quedó con quien ya se fue

- **Qué pasa.** Cambia el turno con llamadas abiertas. Un líder del turno saliente
  acusó recibo de una llamada de material en la estación 6, dejó el piso y nadie
  registró el traspaso. En el tablero la llamada figura «atendida».
- **Qué datos hay.** Eventos de la llamada, los turnos de cada persona y los eventos
  de cambio de turno.
- **Qué debe deducir.** Si la llamada sigue realmente en manos de alguien, quién la
  tiene ahora y en qué punto de la escalera está. Ningún dato dice «huérfana».
- **Qué debe contestar.** El responsable actual (o que no hay), por qué lo que el
  tablero afirma no coincide con lo ocurrido, y los pasos válidos que siguen. Lo obvio
  («atendida» significa que alguien se hace cargo) es sospechoso.
- **Por qué es lógica.** La respuesta sale de encadenar tres cosas: quién acusó, a qué
  hora terminó su turno y si hubo traspaso; el tablero y el mundo se contradicen.

### Situación 5 — El hueco del reinicio

- **Qué pasa.** El sistema se cae y se levanta con llamadas abiertas. Durante el hueco
  no se registró ningún evento: no se sabe si llegaron avisos, si alguien acudió o si
  se pulsaron llamadas nuevas.
- **Qué datos hay.** Los eventos antes de la caída y después del reinicio, los minutos
  de ambos y las llamadas abiertas.
- **Qué debe deducir.** El nivel al que cada llamada ya tuvo que llegar por el tiempo
  corrido, qué avisos están pendientes y qué se ignora (si hubo acuse en el hueco).
- **Qué debe contestar.** Por llamada, el nivel alcanzado, el aviso que se debe enviar
  hoy y lo que **no se sabe**; y una hipótesis: qué pasaría con la llamada si el
  supervisor hubiera acudido durante la caída.
- **Por qué es lógica.** El tiempo corrido sí obliga, el acuse perdido no se puede
  inventar, y las tres consecuencias se encadenan; no saber no es lo mismo que «no».

## Por qué no basta un script

Con `if minutos_sin_atender > 2: avisar(supervisor)` resuelves una llamada con un
reloj perfecto y un solo nivel. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué procede con la llamada de la estación 3? | decisión |
| ¿Por qué sube al supervisor y no al gerente? | explicación |
| ¿Cuáles llamadas están hoy sin responsable? | todas las respuestas |
| ¿Qué tendría que pasar para que la 5 espere a la 2? | la pregunta al revés |
| ¿Qué pasaría si el supervisor tarda diez minutos más? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para reconstruir la historia de una llamada en el «ahora»?
2. ¿Dónde queda escrito qué sigue después de cada etapa y quién puede dar cada paso?
3. ¿Cómo distingue tu gemelo «nadie vino» de «no sé si vino alguien»?
4. ¿Qué parte de la explicación le sirve al supervisor y qué parte es ruido?
5. ¿Qué hace tu simulación en Erlang con el temporizador de una llamada al reiniciar,
   y qué le tocaría al gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la planta, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar eventos simulados o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 8 estaciones, 2 líneas, 2 líderes, 1 supervisor y 1 gerente por
  nivel, contra las 40 estaciones y 3 líderes del escenario original.
- La maquiladora, el área, los nombres, las estaciones numeradas y los tipos de
  llamada de los ejemplos son datos ilustrativos; el cambio de turno y el reinicio son
  casos que tú ubicas en tu escenario.
- El «ahora» es un hecho del modelo, en minutos, no el reloj del sistema, para que las
  respuestas se puedan repetir.
- Los tiempos objetivo de cada nivel los fijas tú dentro de los rangos del original (1 a
  2 minutos y 5 a 10); el original no da los del gerente de área ni de planta, ni
  cuántas llamadas falsas vuelven sospechosa a una estación, ni quién puede cancelar:
  son decisiones tuyas, declaradas.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Llamadas falsas recurrentes por estación y qué hace el equipo de mejora con ellas.
- Especialistas que solo atienden ciertos tipos de llamada (calidad, material).
- Costo de línea detenida para ordenar la atención cuando hay más llamadas que personas.
- Varias áreas compartiendo supervisor o gerente.
- Indicadores del turno: tiempo de respuesta y de solución por estación y causa.

---
*Las cifras son de referencia y vienen del problema original (los rangos de respuesta,
los seis minutos, las ocho llamadas, la escala de 40 estaciones). Verifica la fuente
vigente antes de citarlas en tu entrega.*
