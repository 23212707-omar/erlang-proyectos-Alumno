# #49 — Estacionamiento del campus: gemelo digital con programación lógica

> Extensión del proyecto #49. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste el campus: cajones como procesos agrupados por edificio,
autos que llegan en oleadas, sensores que fallan. Esa simulación responde «¿qué está
pasando?». El conductor y el personal de vigilancia necesitan algo más: «¿a qué cajón
va cada quien, con qué derecho, y por qué a ese?».

El gemelo digital es el **modelo lógico** del campus: hechos que reflejan su estado y
reglas que reflejan cómo se reparte el espacio y en qué dato se confía. Se escribe en
Prolog porque lo que hay que resolver aquí no es contar, sino acomodar a todos a la vez
sin contradicciones, justificar a quién se le falla y saber decir «no lo sé».

## El campus que se clona

Un campus reducido a 3 edificios y 3 estacionamientos, con unos 24 cajones repartidos
en zonas por tipo de usuario (alumnos, docentes, personal, visitantes, motos y accesibles).

| Parte | Contenido |
|---|---|
| Entidades | edificio; estacionamiento → zona → cajón; accesos con lector; usuarios con vehículo |
| Estado por cajón | lo que dice su sensor (libre u ocupado) y desde cuándo; a qué zona pertenece |
| Estado por estacionamiento | abierto o cerrado por obra; entradas y salidas leídas en su acceso |
| Estado por usuario | uno o más permisos (alumno, docente, personal, visitante, moto, accesible) |
| Eventos | llega una solicitud, un lector registra una placa, un sensor cambia, cierra un lote |
| Decisiones | ¿a qué cajón va cada usuario?, ¿este cajón está realmente libre?, ¿quién lo ocupa? |

## Situaciones que tu gemelo debe razonar

Las cinco parten de casos del problema original (el último cajón, el estacionamiento
cerrado por obra, el cajón ocupado que el sensor reporta libre, el vehículo sin permiso
en un cajón de discapacidad, los cambios de horario en días de evento). Varios
complementos son derivados y se señalan. En cada una, tu gemelo debe llegar a una
decisión **y poder explicarla**.

### Situación 1 — Dos autos, un último cajón

- **Qué pasa.** Antes de las 7:00 llegan al mismo edificio dos usuarios y solo queda un
  cajón cercano en una zona que ambos pueden usar. Es el caso de «evitar mandar a dos
  usuarios al último cajón»; con mil solicitudes a la vez, el choque sería de todos
  contra todos. Lo obvio es atender por orden de llegada, pero eso puede dejar a alguien
  sin ningún cajón permitido aunque existiera un reparto para todos.
- **Qué datos hay.** Las solicitudes (usuario, edificio, hora de llegada y salida
  estimada), los permisos de cada usuario, y los cajones con su zona y su distancia al
  edificio. (Que un usuario tenga más de un permiso es un complemento derivado.)
- **Qué debe deducir.** Un reparto en el que cada usuario recibe un cajón de una zona que
  su permiso admite, ningún cajón se repite y nadie es enviado a un lote cerrado o a un
  cajón dudoso.
- **Qué debe contestar.** El reparto completo; por qué cada quien recibió ese cajón y no
  el más cercano a su edificio; si dos usuarios tenían el mismo derecho, a quién se le
  falló y con qué criterio declarado; los demás repartos válidos; y, si no alcanzan los
  cajones, que no alcanzan y para quién.
- **Por qué es lógica.** No se busca el mejor cajón para cada uno, sino un acomodo que
  cumpla todas las condiciones a la vez, y cuando dos partes tienen razón la regla de
  desempate debe estar escrita una vez y valer para todos los casos.

### Situación 2 — El estacionamiento que cierra por obra

- **Qué pasa.** Un estacionamiento cierra por obra a media mañana. Desaparecen sus
  cajones, y con ellos sus zonas: puede quedar un edificio sin cajones accesibles
  cercanos, aunque las normas exigen un porcentaje de cajones accesibles. Los usuarios
  desviados empujan a otros fuera de zonas que se llenan. (Los cajones accesibles como
  consecuencia del cierre son un complemento derivado.)
- **Qué datos hay.** El estado de cada estacionamiento, sus zonas y cajones, las
  distancias de cada edificio a cada lote y las asignaciones vigentes.
- **Qué debe deducir.** Una cadena: qué cajones dejan de existir, qué zonas quedan sin
  capacidad, qué edificios se quedan sin acceso accesible cercano, a qué usuarios afecta
  y a dónde se les puede reubicar sin desplazar a otros con más derecho.
- **Qué debe contestar.** El nuevo reparto; a quién se movió y por qué; en qué edificios
  deja de cumplirse lo accesible; y, si no hay solución, qué recurso falta y cuánto.
- **Por qué es lógica.** Un solo hecho (el lote cerró) cambia muchas conclusiones en
  cadena, y alguien con discapacidad pierde si el gemelo se queda en el primer paso.

### Situación 3 — El cajón que el sensor dice libre

- **Qué pasa.** Un sensor reporta libre un cajón que sí tiene un auto. Si el gemelo lo
  asigna, dos autos llegan al mismo cajón, uno da vueltas y la cola crece en el acceso.
  Los accesos tienen lector o talón, y de ahí sale otro conteo de autos adentro.
- **Qué datos hay.** Lecturas de los sensores con su instante, entradas y salidas por
  placa en el acceso de cada lote, y cuándo se vio ocupado cada cajón. Ningún dato
  dice «la ocupación real» ni «este sensor está descompuesto».
- **Qué debe deducir.** Para cada cajón: ocupado, libre o dudoso. Para cada lote, cuántos
  autos están adentro sin que los sensores los expliquen, y qué cajones «libres» podrían
  explicarlo (por ejemplo, uno visto ocupado y sin salida registrada).
- **Qué debe contestar.** Tres respuestas distintas con su evidencia. Un cajón dudoso no
  se asigna ni se cuenta como libre. Un lote con cajones libres en el mapa puede estar
  lleno: lo obvio («libre en el mapa, libre en el campus») es lo sospechoso.
- **Por qué es lógica.** «El sensor dice libre» y «el cajón está libre» son afirmaciones
  distintas, y la ocupación real es una conclusión que sale de confrontar fuentes que
  se contradicen.

### Situación 4 — El vehículo sin permiso en el cajón accesible

- **Qué pasa.** Llega una usuaria con permiso accesible y el cajón accesible más cercano
  está ocupado por un vehículo cuya placa no figura con ese permiso. A ella le urge el
  lugar; quien lo ocupa podría ser un invasor o alguien con permiso temporal que aún no
  se captura. (El permiso temporal y la placa sin lectura son complementos derivados.)
- **Qué datos hay.** La lectura del sensor del cajón, las placas leídas en el acceso,
  los permisos registrados por placa y los cajones accesibles con su distancia.
- **Qué debe deducir.** Si hay una invasión: ningún dato dice «invasión», se concluye de
  varios; y cuándo no se puede concluir (placa nunca leída, permiso por actualizar).
- **Qué debe contestar.** A qué cajón accesible mandar a la usuaria ya, sin esperar el
  veredicto sobre el vehículo; y para el cajón ocupado, «invadido», «ocupado con
  permiso» o «no se sabe», con evidencia. «No está en la lista» no es «no tiene permiso».
- **Por qué es lógica.** Hay un dilema real: la usuaria necesita el lugar y el otro
  conductor puede estar en su derecho. La ausencia de un dato no es un dato en contra.

### Situación 5 — La ola de la tarde y el cajón de cinco horas

- **Qué pasa.** Un auto pasa de 4 a 8 horas estacionado y la rotación es baja: el cajón
  que se da a las 7:00 sigue ocupado cuando llegan las siguientes olas (13:00 y 16:00).
  En día de evento el horario cambia y la ola se mueve. Mandar a cada quien al cajón más
  cercano ahora puede dejar sin lugar permitido a quien llega después.
- **Qué datos hay.** Solicitudes con llegada y salida estimada, las olas del día, el
  evento que cambia el horario y las zonas de cada tipo de usuario.
- **Qué debe deducir.** Para cada cajón, durante qué horas quedaría ocupado según el
  reparto; qué solicitudes de la próxima ola quedarían sin cajón; y qué reparto de ahora
  lo evita aunque algunos queden más lejos. (La salida estimada puede fallar: dudoso.)
- **Qué debe contestar.** Un reparto que cubre la llegada de ahora y la próxima ola; si
  no existe, qué tendría que cambiar; y qué pasa si llegan diez autos más o si el evento
  adelanta la ola.
- **Por qué es lógica.** Es calendarizar un recurso escaso en el tiempo: lo mejor para
  uno es peor para el campus, y la política debe estar declarada, no enterrada en una
  resta de distancias.

## Por qué no basta un script

Con `if libres[lote] > 0: mandar(auto, lote)` mandas un auto a un lote con sensores
perfectos y sin nadie más llegando. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿A qué cajón mando a Marta, que va al edificio B? | decisión |
| ¿Por qué a ese y no al que está junto a la entrada? | explicación |
| ¿De cuántas formas acomodo a los cuatro autos que llegan juntos? | todas las respuestas |
| ¿Qué tendría que cambiar para que Luis pueda entrar al lote 2? | la pregunta al revés |
| ¿Qué pasa si cierra el lote 3 y llegan diez autos más? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para saber si un cajón puede asignarse a un usuario ahora?
2. ¿Dónde queda escrito qué zonas puede usar cada tipo de usuario, y cómo cambia con una
   obra o un evento?
3. Si dos usuarios tienen el mismo derecho al último cajón, ¿qué criterio decide y
   dónde queda escrito?
4. ¿Cómo distingue tu gemelo «el cajón está libre» de «no sé si está libre»?
5. En Erlang cada cajón es un `gen_statem` agrupado por edificio. ¿Qué de eso podría
   alimentar a este gemelo, y qué decide el gemelo que un proceso aislado no puede?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del campus, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra el reparto
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar llegadas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 3 edificios, 3 estacionamientos, unos 24 cajones y unos 10 usuarios,
  contra los 6 edificios, 4 estacionamientos, 1,500 cajones y 1,200 autos del escenario
  original.
- El «ahora» es un hecho del modelo (minuto del día), no el reloj del sistema, para que
  las respuestas se puedan repetir.
- Tú defines: qué zonas puede usar cada tipo de usuario, las distancias, qué es «cerca»,
  el criterio de desempate, cuánto tiempo sin cambiar vuelve dudoso a un sensor, el
  margen sobre la salida estimada, el porcentaje de cajones accesibles y los horarios del
  evento. El original no da esas cifras; si las fundamentas, cita la fuente.
- Los nombres y cantidades de los ejemplos (Marta, Luis, lote 2, lote 3, «cuatro autos»,
  «diez autos más») son ilustrativos, no datos del campus.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Motos que comparten cajón y zonas mixtas.
- Colas en los accesos con lector: a qué acceso mandar a cada auto.
- Semana de exámenes con ocupación total: política de prioridad cuando no alcanza.
- Visitantes con pase que expira durante la estancia.
- Auditoría de sanciones: demostrar por qué se aplicó o se negó cada una.

---
*Las cifras son de referencia (órdenes de magnitud) y vienen del problema original. Los
números de la escala reducida y de los ejemplos son datos del ejercicio. Verifica la
fuente vigente antes de citarlas en tu entrega.*
