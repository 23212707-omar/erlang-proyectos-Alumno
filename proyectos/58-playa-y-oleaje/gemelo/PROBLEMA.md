# #58 — Playa y oleaje: gemelo digital con programación lógica

> Extensión del proyecto #58. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la operación: un proceso de condiciones que recibe
oleaje, viento y marea, un autómata de bandera y un registro de cambios. Esa simulación
responde «¿qué bandera hay y cuándo cambió?». El jefe de salvavidas necesita algo más:
«¿qué bandera corresponde ahora, por qué, y qué le digo a quien me pregunte si me
equivoqué?».

El gemelo digital es el **modelo lógico** de la costa: hechos que reflejan lo que miden
las boyas, la marea y el laboratorio, y reglas que reflejan cómo se decide una bandera.
Se escribe en Prolog porque aquí se deduce, se justifica y se distingue lo que se sabe
de lo que no.

## La costa que se clona

Una costa de Baja California con 6 playas (dos por municipio: Tijuana, Rosarito y
Ensenada), pocas boyas, una tabla de mareas, un laboratorio y un puesto de salvavidas
por playa.

| Parte | Contenido |
|---|---|
| Entidades | playa; boya (cada playa depende de una); puesto de salvavidas; laboratorio |
| Estado por playa | bandera vigente y desde cuándo, quién la izó, si tiene bancos de arena, boya que la cubre |
| Estado del mar | altura significativa Hs, periodo Tp y dirección (boya, cada 30 min); viento (cada 10 min); marea (tabla) |
| Estado del agua | último resultado de laboratorio (enterococos), con instante de muestra y de llegada; lluvias recientes |
| Eventos | llega una lectura, llueve fuerte, llega un resultado, se iza una bandera, un salvavidas reporta lo que ve, una boya se calla |
| Decisiones | ¿qué bandera?, ¿mantener, subir o bajar?, ¿creer este dato?, ¿quién manda aquí? |

## Situaciones que tu gemelo debe razonar

Las cinco parten de casos, datos o preguntas del problema original; cada una añade un
complemento derivado que se lista en «Supuestos». En cada una, tu gemelo debe llegar a
una decisión **y poder explicarla**.

### Situación 1 — Cielo despejado, bandera roja

- **Qué pasa.** Sábado de sol, sin viento, mar de aspecto tranquilo y la playa llena. La
  boya reporta oleaje de periodo largo y la marea baja deja bancos de arena a la vista.
  Cerca del 80 % de los rescates son por resaca. Si el gemelo mira el cielo y dice verde,
  lo paga quien se meta al agua.
- **Qué datos hay.** Hs y Tp de la boya que cubre cada playa, la tabla de marea, qué
  playas tienen bancos de arena, el viento y un aviso de fauna marina en una playa.
  Nada mide «resaca».
- **Qué debe deducir.** En qué playas hay resaca probable: oleaje que llega, marea que
  expone el banco, banco que forma la corriente; y qué bandera sale de ahí con los demás
  factores. La misma boya da riesgo en una playa con banco y no en otra sin él.
- **Qué debe contestar.** La bandera por playa, el factor que más pesó y qué tendría que
  cambiar (por ejemplo, la marea) para bajarla. Lo intuitivo es que el cielo despejado
  mande; es sospechoso porque el peligro del agua no se ve desde la arena.
- **Por qué es lógica.** El nivel es el peor de varios factores que no se miden en la
  misma escala, y uno de ellos (la fauna) no es «más» ni «menos» que los otros.

### Situación 2 — La marejada y el rebote

- **Qué pasa.** Una marejada sube Hs de 1 m a 3 m en 4 horas y luego se queda oscilando
  cerca del límite entre dos banderas: las lecturas cruzan y regresan. Si la bandera
  sigue cada lectura, cambia sin parar y nadie le cree. Si tarda, hay gente en un mar ya
  peligroso. Quien no quiere sacar a todos por una lectura suelta y quien exige no
  esperar al peor momento tienen razón los dos.
- **Qué datos hay.** La serie de lecturas de la boya con su instante, el historial de
  banderas (color, cuándo y quién) y el «ahora».
- **Qué debe deducir.** La tendencia (sube, baja u oscila), si un cruce es cambio
  sostenido o rebote, si conviene anticipar antes de que el número cruce y cuándo puede
  bajar. Cadena: lecturas → tendencia → cambio sostenido → bandera.
- **Qué debe contestar.** Mantener, subir, bajar o anticipar, con la razón, qué falta
  para que cambie y a quién se le falla con esa decisión. Lo intuitivo es que la bandera
  siga a la última lectura; el caso esperado muestra una lectura que ya permite bajar y
  una respuesta que dice mantener.
- **Por qué es lógica.** La decisión depende de la historia y no solo del instante; la
  política de cuándo no cambiar se declara una vez y vale para todas las playas.

### Situación 3 — El laboratorio llega tarde

- **Qué pasa.** El resultado de enterococos tarda 24 a 48 horas y el límite del programa
  Playas Limpias es de ~200 NMP/100 ml. Llega uno que lo rebasa cuando la playa lleva un
  día con bandera verde y gente. Llega otro, bueno, de una playa donde llovió fuerte
  después de tomar la muestra. En un caso se pone en riesgo la salud de los bañistas; en
  el otro se cierra una playa por un número que ya no describe el agua de hoy.
- **Qué datos hay.** Resultados con instante de muestra y de llegada, lluvias fuertes con
  su instante, banderas con su instante y el límite del programa.
- **Qué debe deducir.** Si el resultado todavía describe a la playa: muestra anterior a
  una lluvia posterior → resultado vencido → playa sin dato vigente de calidad aunque
  tenga un número en la tabla. Y si el resultado contradice la bandera vigente.
- **Qué debe contestar.** Calidad «cumple», «no cumple» o «no lo sé», con la edad de la
  muestra; si hay contradicción con la bandera y qué corresponde; qué haría falta saber.
  Lo intuitivo es que un número bajo el límite sea luz verde; es sospechoso porque
  llegó con la lluvia de por medio.
- **Por qué es lógica.** «Limpio hace dos días» no es «limpio hoy», y «no lo sé» no es lo
  mismo que «no cumple».

### Situación 4 — La boya que se calla

- **Qué pasa.** En plena marejada, la boya de dos playas deja de reportar. El viento
  (cada 10 min) sigue llegando. Sin oleaje, un gemelo ingenuo ve calma. La prueba de caos
  del README pide lo contrario: con datos faltantes, la bandera no se queda en verde.
  Pero subir todas las banderas por pánico también cuesta: se cierra el mar a todos.
- **Qué datos hay.** Lecturas con su instante, qué boya cubre cada playa, qué playas son
  vecinas, el último oleaje conocido, el viento y la marea.
- **Qué debe deducir.** Si el silencio es falla o solo el intervalo normal; qué se puede
  estimar del oleaje de una playa sin boya a partir de la tendencia, de la boya de una
  vecina y del viento; y qué playas se quedan sin nada con qué estimar.
- **Qué debe contestar.** Por playa, la bandera con tres bloques en la explicación: lo
  que se sabe, lo que se infiere (marcado como inferencia, con la fuente) y lo que se
  ignora.
- **Por qué es lógica.** La ausencia de dato no es dato de ausencia. Y de la cadena
  silencio → falla → vecina que cubre → estimación → bandera mínima ninguna pieza se mide
  directamente.

### Situación 5 — El salvavidas dice una cosa, el sistema otra

- **Qué pasa.** Con los datos, el gemelo concluye amarilla; el salvavidas ve en la torre
  una resaca y pide roja. En otro momento el gemelo mantiene roja por la marejada y el
  salvavidas, con el mar ya calmado a simple vista, pide bajarla. Si siempre gana el
  sistema, se ignora a quien está en la arena; si siempre gana el humano, la decisión
  depende de quién esté de turno y nadie puede auditarla.
- **Qué datos hay.** Banderas con quién las izó y cuándo, la observación del salvavidas
  como evento con su instante, y lo que dicen en ese momento las boyas, el viento y la
  marea.
- **Qué debe deducir.** Qué bandera rige y de quién es, si la orden humana contradice los
  datos, si el motivo de esa orden sigue vigente y qué le queda anotado en el historial.
  Cadena: observación → contradicción con los datos → quién manda según la política →
  bandera vigente → registro.
- **Qué debe contestar.** La bandera, quién tiene la última palabra en este caso, por
  qué, qué terminaría la orden del salvavidas y qué pasaría si repitiera su orden.
  Ninguna de las dos órdenes se puede contestar con la misma frase.
- **Por qué es lógica.** La autoridad entre fuentes se declara una vez y se aplica a
  todos los casos; y el historial es un conjunto de hechos que se consulta.

## Por qué no basta un script

Con `if hs > 2: bandera = "roja"` resuelves una playa con una boya perfecta y un
instante. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué bandera izo en la playa 3? | decisión |
| ¿Por qué sigue en amarilla si la lectura ya bajó? | explicación |
| ¿En qué playas hay resaca probable ahora? | todas las respuestas |
| ¿Qué tendría que pasar para bajar la playa 3 a verde? | la pregunta al revés |
| ¿Qué pasaría si la boya sigue callada dos horas más? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Cómo evitas que la bandera cambie cada 5 minutos sin ignorar una marejada real?
2. ¿Quién tiene la última palabra, el sistema o el salvavidas, y dónde queda escrito?
3. ¿Cómo distingue tu gemelo «agua limpia» de «agua sin dato vigente»?
4. ¿Qué parte de la explicación le sirve al salvavidas y cuál es ruido para el bañista?
5. ¿Qué parte de tu simulación en Erlang (condiciones, autómata de bandera, registro)
   podría alimentar a este gemelo con lecturas y banderas como hechos?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la costa, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar lecturas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala: las 6 playas del escenario original, con pocas boyas (el original no da su
  número), una tabla de marea, un laboratorio y un puesto por playa; unas cuantas horas
  de datos, no un día completo.
- El «ahora» es un hecho del modelo, en minutos, no el reloj del sistema, para que las
  respuestas se puedan repetir.
- Nombres de playas, qué boya cubre a cuál, cuáles tienen bancos de arena y los
  identificadores de los ejemplos («la playa 3») los defines tú.
- Complementos de esta extensión, sin cifras en el original: la relación playa-boya y
  de vecindad, los bancos de arena por playa, la observación del salvavidas y su
  autoridad, y la vigencia de un resultado de laboratorio tras una lluvia.
- Estos umbrales tampoco los da el original; son tuyos y los documentas: qué
  combinación de Hs y Tp corresponde a cada bandera (solo hay un ejemplo: 2 m con
  periodo mayor de 14 s); cuánta marea baja expone un banco; qué es «lluvia fuerte»;
  cuánto tiempo sostenido hace un cambio real y cuánto debe pasar para bajar; cuánto
  silencio vuelve sospechosa a una boya; qué bandera corresponde a mala calidad del
  agua; cuándo vence la orden de un salvavidas; si la temperatura del agua cuenta.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Repartir pocos salvavidas entre muchas playas según el riesgo de cada una.
- Un derrame de aguas residuales que se propaga hacia las playas vecinas.
- Zonas de la misma playa con distinta bandera (surfistas aparte de bañistas).

---
*Las cifras (80 % de rescates por resaca, 2 m con periodo mayor de 14 s, ~200 NMP/100 ml,
24-48 h de laboratorio, 6 playas, boya cada 30 min, viento cada 10 min, Hs de 1 m a 3 m
en 4 horas) vienen del problema original; escala, relaciones y umbrales del escenario son
de esta extensión. Verifica la fuente vigente antes de citarlas.*
