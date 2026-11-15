# #40 — Camas de hospital: gemelo digital con programación lógica

> Extensión del proyecto #40. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste las camas: cada una cambia de estado (libre, ocupada, por
limpiar, bloqueada), las admisiones piden camas y, si dos piden la última, solo una la
obtiene. Esa simulación responde «¿en qué estado está cada cama y quién la obtuvo?». Quien
coordina las camas necesita algo más: «¿a quién le toca cada cama, cuándo habrá otra, y
por qué a él y no al otro?».

El gemelo digital es el **modelo lógico** del hospital: hechos que reflejan su estado y
reglas que reflejan cómo se decide en él. Se escribe en Prolog porque lo que hay que
resolver aquí no es calcular, sino repartir recursos que no alcanzan, deducir en qué
punto del ciclo está cada cama y decir «no lo sé» cuando falta un dato.

## El hospital que se clona

Un hospital general de Tijuana, reducido a 15 camas en 5 servicios, con una docena de
pacientes. Es una simulación planteada por el problema original; lo que se añade (actores
y detalles) está marcado en las situaciones.

| Parte | Contenido |
|---|---|
| Entidades | hospital → servicio → cama; pacientes; solicitudes de cama; traslados internos |
| Estado por cama | servicio, tipo (general, terapia intensiva, aislamiento, pediátrica), historia de eventos con su instante, y lo que muestra el tablero |
| Estado por paciente | tipo de cama que pide su indicación, origen de la solicitud (urgencias o cirugía programada), resultado de su prueba de infección si la hay, y el motivo por el que su alta no sale |
| Eventos | llega una solicitud, se indica un alta, el paciente sale, empieza y termina la limpieza, se bloquea una cama, se pide un traslado, llega el resultado de una prueba |
| Decisiones | ¿a quién le toca cada cama?, ¿está de verdad disponible?, ¿cuántas habrá libres?, ¿hay saturación?, ¿qué se hace si no hay cama del tipo requerido? |

## Situaciones que tu gemelo debe razonar

Las cinco parten del problema original; las derivadas añaden un detalle que el original
no menciona y se señalan en cada una. En cada situación, tu gemelo debe llegar a una
decisión **y poder explicarla**.

### Situación 1 — Dos pacientes, una cama

- **Qué pasa.** Urgencias manda a un paciente grave y, casi a la vez, cirugía manda a uno
  programado cuyo quirófano ya está reservado (la cirugía programada es complemento
  derivado). Los dos caben en la misma cama general libre. Un día hay otra cama que sirve
  a uno de los dos; otro día, no. Es el caso «dos servicios piden la misma cama libre».
- **Qué datos hay.** Camas con su tipo y estado; solicitudes con su origen y su hora de
  llegada; el tipo de cama que pide la indicación de cada paciente.
- **Qué debe deducir.** Qué repartos de camas distintas son válidos y si alguno atiende a
  todos. Si no existe, a quién se le falla y qué tendría que pasar para que le toque.
- **Qué debe contestar.** El reparto completo con la razón de cada pareja; los demás
  repartos válidos; y, si alguien queda sin cama, quién, por qué y cuándo podría tocarle.
  Lo obvio es dársela a quien llegó primero; es sospechoso porque puede dejar sin cama a
  quien no tenía otra opción cuando sí existía un reparto para ambos. Si de verdad no
  alcanza, los dos tienen razón y la regla debe decidir y justificar a quién se le falla.
- **Por qué es lógica.** Un reparto es un conjunto de parejas que deben cumplirse a la
  vez. El orden de llegada es un criterio más, no la solución; la preferencia se declara
  una vez y vale para todos los casos.

### Situación 2 — Alta indicada, cama todavía no

- **Qué pasa.** Se indica el alta de un paciente y el tablero pinta su cama de libre. Pero
  el paciente aún no sale y, cuando salga, la cama necesita limpieza y desinfección
  (30-60 minutos típicos; en el escenario original, una limpieza tarda 2 horas). Mientras
  tanto, un paciente espera en urgencias. A veces el registro además cuenta algo imposible:
  limpieza terminada sin que nadie saliera, o dos ingresos seguidos sin alta (el registro
  incoherente es complemento derivado).
- **Qué datos hay.** Los eventos de cada cama con su instante, lo que muestra el tablero,
  el ahora y el paciente que espera. Nadie guarda «esperando limpieza» ni «disponible».
- **Qué debe deducir.** En qué punto del ciclo está cada cama; si ya puede ocuparse y de
  qué paciente; cuándo podría, como muy pronto; y si la historia es una secuencia posible.
- **Qué debe contestar.** El estado deducido de la cama, si discrepa del tablero y por qué,
  si se asigna ahora, y la hora más temprana a la que podría. Para una historia imposible,
  cuál es el primer paso que la rompe; para cualquier cama, qué pasos pueden seguir.
- **Por qué es lógica.** El estado es una conclusión de varios eventos encadenados (alta,
  salida, limpieza, sin bloqueo, tipo compatible). La misma descripción de «qué puede
  seguir a qué» sirve para revisar una historia y para generar los pasos permitidos.

### Situación 3 — ¿Cuántas camas habrá esta noche?

- **Qué pasa.** Las altas se concentran por la tarde y los ingresos de urgencias llegan por
  la noche. La dirección quiere comprometer camas para esa hora, pero hay altas indicadas
  que esperan receta, transporte o familiares: pueden salir o no. Y cada una que sale aún
  necesita limpieza. Prometer una cama que no se libera deja a un paciente en el pasillo o
  cancela una cirugía; no prometerla desperdicia una cama que otro necesita. Es el caso de
  predecir camas con altas inciertas.
- **Qué datos hay.** Altas indicadas con el motivo de su espera, camas en limpieza, el
  ahora y las solicitudes que esperan.
- **Qué debe deducir.** Para cada cama, si estará libre a esa hora con seguridad, si es
  posible o si no lo estará; y cuáles solicitudes se pueden prometer con garantía.
- **Qué debe contestar.** Tres listas (seguras, posibles, imposibles) y de qué depende
  cada cama posible; el mínimo y el máximo de camas libres; y qué cambia si uno de los
  motivos de espera se resuelve o no.
- **Por qué es lógica.** «No sé si saldrá» no es «no saldrá». Y la duda se hereda: una
  cama que depende de un alta dudosa y de una limpieza no tiene la hora asegurada.

### Situación 4 — El paciente que ocupa dos camas

- **Qué pasa.** Un paciente de terapia intensiva mejora y se traslada a una cama general.
  Durante el traslado, la cama de origen y la de destino están comprometidas a la vez. En
  ese momento se mide la ocupación: por encima de ~85 % suelen venir la saturación y las
  cirugías canceladas. Alguien espera la cama de terapia que este traslado liberaría.
- **Qué datos hay.** Camas por servicio y su estado, traslados en curso con su instante,
  camas en limpieza o bloqueadas y las solicitudes que esperan. Nadie mide «ocupación real».
- **Qué debe deducir.** La ocupación real de cada servicio y del hospital, contando una
  sola vez al paciente en traslado, y si cruza el umbral. Y la cadena: el que espera
  terapia depende del traslado, este de una cama general libre y esa de una limpieza.
- **Qué debe contestar.** Ocupación real frente a la aparente, con las camas que cuenta
  cada una; si la alerta es válida; y el eslabón de la cadena que falta para que el que
  espera obtenga su cama.
- **Por qué es lógica.** Contar bien es razonar sobre relaciones: un paciente, dos camas.
  Qué cuenta como ocupada (limpieza, bloqueo, traslado) se declara una vez, y la
  respuesta correcta puede ser la contraria a la del tablero.

### Situación 5 — El brote y la prueba que no llega

- **Qué pasa.** Un brote llena el área de aislamiento. En urgencias hay un paciente con
  prueba positiva y otro con sospecha cuya prueba aún no tiene resultado (la prueba
  pendiente es complemento derivado). Un infeccioso en el pasillo contagia a otros; un
  paciente sin infección en aislamiento ocupa la cama que otro necesita. Es la pregunta
  guía del original: qué se decide cuando no hay cama del tipo requerido.
- **Qué datos hay.** Camas de aislamiento con sus ocupantes, resultados de prueba y el
  instante en que se pidieron, las solicitudes y qué tipos hay libres.
- **Qué debe deducir.** Quién requiere aislamiento con certeza, quién no, de quién no se
  sabe; qué ocupante de aislamiento ya no lo necesita y qué cama sigue sin servir mientras
  no se limpie; y qué opciones existen cuando no hay cama del tipo requerido.
- **Qué debe contestar.** Para cada solicitud, la cama o la espera, a qué se renuncia al
  elegirla y qué resultado de prueba cambiaría la decisión. Un «no se sabe» no debe
  acabar convertido en «sí» ni en «no» sin avisarlo.
- **Por qué es lógica.** Tres valores (requiere, no requiere, no se sabe) y un dilema
  entre dos riesgos: la regla debe declarar qué riesgo pesa más y poder justificarlo.

## Por qué no basta un script

Con `cama = next(c for c in camas if c.libre and c.tipo == p.tipo)` asignas una cama a
un paciente a la vez, con datos perfectos. Tu gemelo debe contestar, **con las mismas
reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué cama le doy al paciente 7? | decisión |
| ¿Por qué no la cama 3, si el tablero la marca libre? | explicación |
| ¿Qué repartos atienden a las cuatro solicitudes de esta noche? | todas las respuestas |
| ¿Qué tendría que pasar para que el paciente 9 tenga cama de aislamiento? | la pregunta al revés |
| ¿Qué pasaría si el transporte del paciente 4 no llega antes de la noche? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Cuáles son los estados legales de una cama y qué evento dispara cada cambio?
2. ¿Qué decide tu gemelo cuando no hay cama del tipo requerido? ¿Y cuando no sabe si el
   paciente la requiere?
3. Cuando «el primero que llegó» y «el que más la necesita» se contradicen, ¿dónde queda
   escrito cuál gana?
4. ¿Cómo distingue tu gemelo «no se libera» de «no sé si se libera»?
5. En Erlang cada cama es un proceso y las admisiones garantizan que, si dos piden la
   última cama, solo una la obtiene. ¿Qué de eso alimenta a este gemelo, y qué decide el
   gemelo que ese proceso no puede: a quién debió tocarle?

## Qué entregas

- El gemelo en SWI-Prolog: hechos del hospital, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra el reparto
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar ingresos simulados o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 15 camas en 5 servicios (medicina interna, cirugía, pediatría, terapia
  intensiva y aislamiento), contra las 120 camas en 6 servicios, 40 ingresos y 40 altas
  al día del escenario original. Los números de camas y pacientes de los ejemplos son
  identificadores del ejercicio.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas se
  puedan repetir. Los instantes se cuentan en minutos.
- Tú defines: cuánto dura cada limpieza dentro del rango del original; qué tipo de cama
  puede sustituir a otro y a qué costo; desde cuándo un alta sin confirmar está en duda;
  qué cuenta como cama ocupada; qué horizonte es «esta noche»; y qué riesgo pesa más en
  el dilema de la situación 5. El original no da esas cifras.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Camas bloqueadas por mantenimiento o por falta de personal.
- Maternidad y pediatría con reglas propias de acompañantes y de edad.
- Separación de pacientes por sexo o por tipo de infección dentro de una misma habitación.
- Derivar a un paciente a otro hospital cuando no hay cama del tipo requerido.
- Cirugías programadas que, al salir de quirófano, necesitan cama de terapia.

---
*Las cifras son de referencia (órdenes de magnitud) y vienen del problema original.
Verifica la fuente vigente antes de citarlas en tu entrega.*
