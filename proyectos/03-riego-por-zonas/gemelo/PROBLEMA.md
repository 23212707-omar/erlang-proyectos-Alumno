# #3 — Riego por zonas: gemelo digital con programación lógica

> Extensión del proyecto #3. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el riego: un programador con cola de prioridades, una
válvula por zona, fallas inyectadas y un reinicio. Esa simulación responde «¿qué está
pasando?». El encargado del predio necesita algo más: «¿qué zona riego, a cuál le fallo
si no alcanza, y por qué?».

El gemelo digital es el **modelo lógico** del sistema de riego: hechos que reflejan su
estado y reglas que reflejan cómo se reparte el agua y a qué dato se le cree. Se escribe
en Prolog porque aquí no se cuentan litros: se acomodan zonas sin que se estorben, se
justifica a quién se le falla y se sabe decir «no lo sé».

## El sistema de riego que se clona

Un predio de Baja California con una sola fuente de agua, reducido a 6 zonas en 3 ramales
de tubería (dos zonas por ramal) y una bomba. La ventana de riego es la noche.

| Parte | Contenido |
|---|---|
| Entidades | bomba → ramal → zona → válvula; sensores de humedad por zona; un caudalímetro y un pluviómetro del predio |
| Estado por zona | minutos de riego que le faltan esta noche, prioridad que le dio su dueño, si su válvula está abierta o cerrada según el controlador |
| Estado del sistema | zonas que la bomba soporta a la vez, caudal medido en la línea, minuto de la noche |
| Eventos | se ordena abrir o cerrar una válvula, el controlador reporta que abrió o cerró, llega una lectura, llueve, se va la luz |
| Decisiones | ¿qué zona riega y cuándo?, ¿a quién se le falla si no cabe?, ¿esta válvula está realmente cerrada?, ¿le llovió a esta zona?, ¿cuánto regó de verdad? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original (su escenario y sus casos difíciles); lo que no
trae —ramales, prioridades de los dueños, zona bajo cubierta— está en «Supuestos». En
cada una, tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — La noche que sí cabe

- **Qué pasa.** Hay que programar todas las zonas dentro de la ventana de 8 horas. La
  bomba soporta 3 zonas a la vez y dos zonas del mismo ramal no pueden regar juntas.
  Cada zona necesita sus minutos completos, sin cortarse a medias.
- **Qué datos hay.** Zonas, ramales, minutos que requiere cada una, capacidad de la
  bomba y los límites de la ventana.
- **Qué debe deducir.** Un calendario en que cada zona recibe su dosis dentro de la
  ventana, sin exceder la bomba y sin coincidir dos del mismo ramal.
- **Qué debe contestar.** El calendario; por qué cada zona quedó en su turno; y, si hay
  varios calendarios válidos, cuáles son.
- **Por qué es lógica.** No se busca el mejor turno para una zona, sino un acomodo que
  cumpla todas las condiciones a la vez: restricciones.

### Situación 2 — El programa no cabe: ¿a quién se le falla?

- **Qué pasa.** Una ola de calor sube la demanda (ETc = ETo × Kc; la ETo va de ~2
  mm/día en invierno a ~7-8 mm/día en verano) y la suma de minutos ya no cabe en la
  ventana. Dos dueños declararon «prioridad alta» para zonas que no pueden regar ambas
  esa noche: la hortaliza recién trasplantada de uno y el árbol joven de otro.
- **Qué datos hay.** Los de la situación 1, la prioridad de cada zona y la demanda del día.
- **Qué debe deducir.** Que no existe un calendario completo y qué zonas se quedan sin
  riego o con riego recortado.
- **Qué debe contestar.** Que el programa no cabe (nunca fallar en silencio), a quién se
  le falla y bajo qué criterio, qué pierde cada parte, y cuánto tendría que crecer la
  ventana o la bomba para no fallarle a nadie.
- **Por qué es lógica.** Dos partes tienen razón y la regla debe decidir y justificar;
  el desempate se declara una vez y vale para todas las noches.

### Situación 3 — Se mandó cerrar y el agua sigue corriendo

- **Qué pasa.** Se ordenó cerrar una válvula y el controlador dice que cerró, pero el
  caudalímetro marca más de lo que corresponde: válvula atorada por sedimento o fuga
  (caudal sin zona activa).
- **Qué datos hay.** Órdenes de abrir y cerrar, lo que reporta el controlador, el caudal
  de la línea y la humedad del suelo de cada zona. Ningún dato dice «válvula atorada».
- **Qué debe deducir.** En cadena: orden y reporte dicen «cerrada»; el caudal contradice;
  la humedad de una zona sigue subiendo, luego esa válvula está atorada; y como la bomba
  carga con una zona que nadie programó, su capacidad útil baja y el resto de la noche
  se recalcula. Si la humedad no sube en ninguna zona, el diagnóstico cambia a fuga.
- **Qué debe contestar.** Atorada, fuga o «no lo sé», con la evidencia y la zona
  sospechosa; y el calendario restante con la capacidad que de verdad queda.
- **Por qué es lógica.** El diagnóstico nace de que varios datos se contradigan, no de
  uno solo que esté alto, y de él se derivan consecuencias en otra parte del modelo.

### Situación 4 — Llueve, ¿entonces se acaba el riego?

- **Qué pasa.** A mitad del programa llueve. Lo obvio es suspender todo lo que falta,
  pero hay un solo pluviómetro, en un extremo del predio, y una zona está bajo cubierta:
  lo que dice el pluviómetro y lo que pasa en cada suelo no tienen por qué coincidir.
- **Qué datos hay.** El pluviómetro, la humedad de cada zona y el programa que faltaba.
- **Qué debe deducir.** Para cada zona pendiente, si la lluvia la mojó, no la mojó o no
  se puede saber (sensor sin reportar, lectura imposible), y qué sobra o falta de la
  noche con esa información.
- **Qué debe contestar.** Qué zonas se suspenden, cuáles siguen y cuáles quedan en «no
  lo sé»; y si el espacio que libera la lluvia rescata a una zona a la que se le falló.
- **Por qué es lógica.** Un evento externo cambia varias conclusiones a la vez, y «no se
  mojó» no es «no sé si se mojó».

### Situación 5 — Se fue la luz: ¿cuánto regó de verdad cada zona?

- **Qué pasa.** El controlador se reinicia a mitad del turno. Antes de caerse reportó
  que abrió varias válvulas y no alcanzó a reportar su cierre. Su reloj y el del
  servidor no coinciden. Alguien paga el bombeo y un dueño reclama que su zona no se regó.
- **Qué datos hay.** Eventos del controlador y del servidor con su hora, órdenes y
  lecturas del caudalímetro y de humedad.
- **Qué debe deducir.** La dosis que recibió cada zona, que ningún dato mide: de cuáles
  hay certeza, de cuáles solo un rango y de cuáles nada; y qué válvulas hay que suponer
  abiertas hasta que se pruebe lo contrario.
- **Qué debe contestar.** Por zona: regó completo, parcial o «no lo sé», con las horas y
  fuentes que lo sustentan; y qué se puede abrir ahora sin pasar la capacidad de la bomba.
- **Por qué es lógica.** Es rendición de cuentas: reconstruir lo que pasó con la
  certeza que los datos permiten, y no más.

## Por qué no basta un script

Con `if humedad < umbral: abrir(zona)` resuelves una zona con datos perfectos. Tu gemelo
debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué hago con la zona 4 ahora? | decisión |
| ¿Por qué la zona 4 va después de la 2? | explicación |
| ¿Cuáles calendarios son válidos esta noche? | todas las respuestas |
| ¿Qué tendría que cambiar para que la zona 4 alcance a regar? | la pregunta al revés |
| ¿Qué pasaría si mañana la ETo sube al doble? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio: es el programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir una zona y la bomba en un instante?
2. Cuando dos zonas con la misma prioridad compiten, ¿dónde queda escrito quién gana?
3. ¿Cómo distingues una válvula atorada de una fuga y de un sensor que miente?
4. ¿Cómo distingue tu gemelo «no se regó» de «no sé si se regó»?
5. ¿Qué parte de tu simulación en Erlang (estado persistido, válvulas en fallo) podría
   alimentar a este gemelo con hechos?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del predio, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra el calendario
  y la decisión con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar lecturas simuladas o
  graficar el calendario.

## Supuestos de esta extensión

- Escala reducida: 6 zonas, 3 ramales y una bomba que soporta 3 zonas a la vez, contra
  las 12 zonas del escenario original. La ventana de 8 horas sí es la del original.
- Los ramales (qué dos zonas no riegan juntas) son del escenario reducido: el original
  habla de «riegos simultáneos en conflicto» sin precisar cuáles. También lo son la
  prioridad de cada zona (alta, media o baja), sus dueños, la zona bajo cubierta y el
  único pluviómetro. Los fijas tú.
- Las dosis (minutos por zona), el instante en que se va la luz, el desfase entre los
  relojes y cuánto caudal anómalo basta para sospechar de una válvula son decisiones
  tuyas. Elige números pequeños; no los presentes como cifras reales.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Tarifa eléctrica: preferir las horas baratas de bombeo y pagar de más cuando no queda
  otra.
- Presión de línea como dato extra para distinguir fuga de válvula atorada.
- Riego repartido en dos noches cuando una sola no alcanza.

---
*Las cifras de dominio (3 zonas a la vez, ventana de 8 horas, ETo de ~2 a ~7-8 mm/día) son
de referencia y vienen del problema original; lo demás es del escenario reducido y está
en «Supuestos». Verifica la fuente vigente antes de citar cualquier cifra en tu entrega.*
