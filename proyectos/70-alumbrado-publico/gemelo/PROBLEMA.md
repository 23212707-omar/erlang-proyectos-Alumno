# #70 — Alumbrado público: gemelo digital con programación lógica

> Extensión del proyecto #70. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el alumbrado: luminarias que fallan, reportes que
llegan, fallas que pasan de reportadas a reparadas. Esa simulación responde «¿cuántas
lámparas están apagadas y en qué estado va cada falla?». Quien despacha necesita algo
más: «¿qué falla es esta realmente, a cuál voy primero, a quién mando y por qué?».

El gemelo digital es el **modelo lógico** de la zona: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque la ciudad no es
una lista de lámparas sino una red (calles contiguas, circuitos que comparten tablero,
rutas entre postes): hay que recorrerla, justificar cada turno y saber decir «no lo sé».

## La zona que se clona

Una colonia ficticia de Tijuana, reducida a unas 24 luminarias en 4 calles, 3 circuitos
y 2 cuadrillas. Calles, colonia y folios de los ejemplos son inventados.

| Parte | Contenido |
|---|---|
| Entidades | tablero → circuito → luminaria; calle → luminaria contigua; sitio sensible (cruce peligroso, escuela, hospital); cuadrilla |
| Estado por luminaria | su calle y circuito, su altura, si tiene telemetría (corriente y estado) o solo se sabe de ella por reportes, y su historia de reparaciones |
| Estado de la zona | reportes ciudadanos con su dirección escrita a mano y su hora; lecturas de telemetría con su instante; cuadrillas disponibles |
| Eventos | llega un reporte, llega una lectura, se asigna una falla, una cuadrilla cierra una reparación, falla un tablero, una cuadrilla se queda sin camión |
| Decisiones | ¿estos reportes son la misma falla?, ¿es un circuito o son fallas sueltas?, ¿qué falla va primero?, ¿qué hace cada cuadrilla hoy y en qué orden?, ¿se puede creer que ya está reparada? |

## Situaciones que tu gemelo debe razonar

Las cuatro primeras salen del problema original (sus casos difíciles, su escenario y
sus datos); la quinta usa su meta de atención, sus cuadrillas y su capacidad por día
para plantear un día completo de despacho, con un imprevisto que el original no
menciona. En cada una, tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — Quince reportes, ¿cuántos postes?

- **Qué pasa.** Un mismo poste se reporta muchas veces y cada persona escribe la
  dirección a su manera: «Pinos esquina Cedros», «frente a la primaria, por Pinos»,
  «Pinos 120». Pero en la misma calle hay otro poste cercano que también puede estar
  apagado: fusionar de más deja una luminaria sin atender; de menos, manda a la
  cuadrilla quince veces a lo mismo.
- **Qué datos hay.** Los reportes con texto y hora, las luminarias de esa calle y la
  telemetría de las que la tienen.
- **Qué debe deducir.** Qué reportes apuntan a la misma luminaria, cuáles a otra y
  cuáles no se pueden asignar con lo que hay. Ningún dato dice «es el mismo poste».
- **Qué debe contestar.** Las fallas únicas con sus reportes; de cada reporte ambiguo,
  entre cuáles luminarias duda y qué dato lo resolvería.
- **Por qué es lógica.** «Es la misma falla» se apoya en varios indicios y puede ser
  «sí», «no» o «no lo sé». Lo intuitivo es creer que quince reportes son una falla
  quince veces más grave; es sospechoso: son quince personas viendo un poste.

### Situación 2 — Un circuito caído o cuarenta fallas sueltas

- **Qué pasa.** Se apagan de golpe todas las luminarias de un circuito (en el escenario
  original, 40 a la vez). Llegan reportes de muchas calles y solo algunas luminarias
  tienen telemetría. Cambiar lámparas de un circuito sin energía no arregla nada.
- **Qué datos hay.** Circuito y tablero de cada luminaria, lecturas de corriente de las
  que reportan, reportes y horas. Ningún dato dice «circuito caído» ni «causa común».
- **Qué debe deducir.** Que el tablero perdió la alimentación, que por tanto todo su
  circuito está sin energía (también las luminarias sin telemetría) y que los reportes
  sueltos son síntomas de una sola causa; y cuándo varias apagadas de un mismo
  circuito siguen siendo fallas independientes.
- **Qué debe contestar.** La causa común con el camino hasta cada luminaria afectada;
  cuáles son efecto y cuáles falla propia; de las que no tienen telemetría, cuáles
  están apagadas con certeza y cuáles solo «probablemente».
- **Por qué es lógica.** La causa se propaga por la red; la cadena tablero, circuito,
  luminaria, reporte se declara una vez y se recorre en ambos sentidos.

### Situación 3 — «Ya la reparamos»

- **Qué pasa.** La cuadrilla cerró la falla de una luminaria como reparada. Cinco días
  después llega un reporte del mismo lugar (reincidencia: vuelve a fallar en una
  semana). Pero el cierre dice «reparada» y la telemetría, si la hay, dice que nunca
  volvió la corriente. La cuadrilla acusa al registro; el despacho, a la cuadrilla.
- **Qué datos hay.** La historia de cada luminaria (reportes, asignaciones, cierres),
  quién cerró y las lecturas posteriores al cierre.
- **Qué debe deducir.** Si el reporte es la misma falla que se dio por cerrada o una
  nueva, si la reparación funcionó alguna vez y qué otros cierres de esa cuadrilla
  merecen revisarse.
- **Qué debe contestar.** Misma falla, falla nueva o «no se sabe», con evidencia, y su
  lugar en la fila. Lo intuitivo es tratarla como reporte nuevo y mandarla al final;
  es sospechoso: quizá nunca estuvo arreglada.
- **Por qué es lógica.** Lo que dice el sistema (una orden cerrada) y lo que pasa (no
  hay corriente) se contradicen, y el gemelo debe decidir a cuál creer y dejarlo dicho.

### Situación 4 — La clínica, la primaria y el tramo oscuro

- **Qué pasa.** El día alcanza para una sola reparación en el sector. Una luminaria
  apagada está frente a una clínica, con sus vecinas contiguas encendidas. En otra
  calle hay tres contiguas apagadas junto a una primaria y un cruce peligroso, y su
  falla más antigua se acerca a la meta de 72 h. Las dos partes tienen razón; a una
  se le va a fallar.
- **Qué datos hay.** Qué luminarias son contiguas y cuáles están encendidas, el tipo de
  sitio, la hora de cada falla y la meta de atención.
- **Qué debe deducir.** Qué luminarias forman un tramo oscuro continuo (ningún sensor lo
  mide: una apagada entre dos encendidas no es lo mismo que tres seguidas), qué tan
  crítica es cada falla por su lugar y qué tan cerca está de vencer.
- **Qué debe contestar.** Cuál va primero, la regla que decidió, a quién se le falla y
  qué tendría que cambiar para atender a ambas.
- **Por qué es lógica.** La criticidad y la antigüedad chocan; la regla que desempata se
  escribe una vez y justifica cada orden, también el que a nadie le gusta.

### Situación 5 — El día de las dos cuadrillas

- **Qué pasa.** Hay fallas abiertas en varias calles, cada cuadrilla repara entre 8 y
  15 luminarias al día según la distancia entre ellas y la altura, y las fallas tienen
  metas de atención. Las luminarias de un circuito sin energía no se pueden reparar
  hasta que se restablezca su tablero. A media jornada, una cuadrilla se queda sin
  camión.
- **Qué datos hay.** Las fallas consolidadas con prioridad y hora, distancias, altura de
  cada luminaria, qué falla depende de otra y el estado de las cuadrillas.
- **Qué debe deducir.** Un reparto entre cuadrillas y un orden de visita que respete
  dependencias y capacidad del día; y, si algo cambia a media jornada, qué se reasigna
  y qué se queda sin atender a tiempo.
- **Qué debe contestar.** El plan de cada cuadrilla y, si hay varios válidos, cuáles;
  cuando ninguno cumple todas las metas, que no existe, qué fallas no caben y qué
  recurso falta, en vez de un plan que finge cumplirlas.
- **Por qué es lógica.** Son rutas y recursos limitados con restricciones que se
  declaran; alternativas y causas de fracaso salen de las mismas reglas. Agrupar por
  cercanía es natural, pero puede dejar para el final una falla a punto de vencer.

## Por qué no basta un script

Con `for falla in fallas: asignar(falla, cuadrilla_mas_cercana)` repartes fallas
que no se repiten, que no dependen de otras y que siempre son lo que dicen ser. Tu
gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué hace hoy cada cuadrilla? | decisión |
| ¿Por qué la clínica va después de la primaria? | explicación |
| ¿Qué luminarias del circuito están apagadas con certeza? | todas las respuestas |
| ¿Qué tendría que pasar para atender la falla 4 antes de 72 h? | la pregunta al revés |
| ¿Qué pasaría si el tablero del circuito 2 vuelve a fallar mañana? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Cuándo dos reportes son «la misma falla»? ¿Y cuándo no lo puedes saber?
2. ¿Cómo equilibras la antigüedad de la falla con la criticidad del lugar, y dónde queda
   escrito quién gana?
3. ¿Qué hechos necesitas para saber que un circuito completo está sin energía, si nadie
   lo reporta así?
4. ¿Cómo distingue tu gemelo «reparada» de «cerrada como reparada»?
5. En Erlang cada luminaria o circuito es un proceso y cada falla una máquina de estados.
   ¿Qué de eso podría alimentar a este gemelo, y qué decide el gemelo que un proceso no
   puede?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la zona, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra el mapa de
  fallas con su decisión y explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para simular o graficar.

## Supuestos de esta extensión

- Escala reducida: unas 24 luminarias, 3 circuitos y 2 cuadrillas, contra las 5,000
  luminarias, los 80 reportes diarios y las 4 cuadrillas del escenario original. Con
  esa escala, el circuito caído de la situación 2 es más chico que el de 40 lámparas.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir.
- La situación 5 añade un imprevisto (la cuadrilla sin camión) y un tablero que se
  restablece antes de reparar su circuito: son del ejercicio, no del original. Las calles, sitios sensibles y folios también son inventados, igual que
  las cantidades de los ejemplos («tres luminarias contiguas», «cinco días», «Pinos 120»).
- Tú defines: qué tan parecidas deben ser dos direcciones para fusionar reportes; cuánto
  silencio vuelve dudosa a una luminaria con telemetría; qué cuenta como «la misma
  falla» tras un cierre; cuánto pesa cada tipo de sitio; y cuánto cabe en un día dentro
  del rango de 8 a 15. Decláralo como supuesto.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Luminarias encendidas de día: fotocelda descompuesta y consumo que se paga de más.
- Cambio de sodio a LED por circuito, con el ahorro que cada circuito justifica.
- Robo de cable: qué circuitos son más propensos a repetirlo y qué hacer con ellos.

---
*Las cifras son de referencia y vienen del problema original. Verifica la fuente vigente
antes de citarlas en tu entrega.*
