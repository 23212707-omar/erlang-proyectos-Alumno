# Contexto para agentes — gemelo digital del proyecto #45 (Control de laboratorios)

Este archivo es para el agente (OpenCode u otro) que acompaña al estudiante. Léelo
completo, junto con [`PROBLEMA.md`](PROBLEMA.md) y
[`../problema/readme.md`](../problema/readme.md), antes de proponer cualquier cosa.

## Tu papel

- El proyecto es individual y se califica el razonamiento del estudiante. **Explica,
  pregunta y propone; no entregues la solución completa.**
- Antes de escribir una regla, pide al estudiante que la diga en español.
- Primero la prueba plunit, después la regla.
- Trabaja una situación a la vez, en el orden de `PROBLEMA.md`.
- No inventes cifras. Las de `PROBLEMA.md` vienen del problema original; cualquier otra
  se marca como supuesto y se le pide al estudiante la fuente.

## Dominio

| Término | Significado |
|---|---|
| Laboratorio | Sala con aforo fijo y un calendario de reservas |
| Equipo prestable | Instrumento o kit que se presta a un responsable y debe devolverse; vive en un laboratorio |
| Reserva | Bloque de un laboratorio, y a veces de equipos, para un grupo |
| Clase fija | Reserva del horario del semestre; tiene prioridad sobre las prácticas libres |
| Práctica libre | Reserva voluntaria de un grupo; cede ante una clase |
| Serie | Reserva recurrente: la misma sala y bloque en varias semanas |
| Mantenimiento y calibración | Bloques en que un laboratorio o equipo no puede usarse |
| Adeudo | Equipo prestado y no devuelto; bloquea al responsable |
| Reserva fantasma | Reserva aprobada a la que nadie llega y que ocupa un bloque |
| Lista de espera | Grupos que esperan un bloque que se libere |

Cifras de referencia, todas del problema original: bloques de 1 a 2 h; aforo de ejemplo de
20 a 30 estaciones; semana de proyectos con 5 veces la demanda normal; el escenario
completo tiene 12 laboratorios, 150 equipos prestables y 1,000 reservas por semana. Los 3
laboratorios, los 8 equipos, los 5 grupos, la docena de reservas, el aforo de cada sala y
los números de los ejemplos son del ejercicio, no cifras del dominio.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar reservas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Quién llega o no llega a una reserva no se sortea: entra como hecho o como supuesto.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                                  % los instantes se cuentan en minutos
laboratorio(Lab, Aforo).
equipo(Equipo, Tipo, LabBase).                  % LabBase: donde vive habitualmente
grupo(Grupo, Responsable, Tamano).
reserva(Reserva, Grupo, Lab, Tipo, Inicio, Fin).  % Tipo: clase | practica
uso_equipo(Reserva, Equipo).
serie(Serie, Reserva).                          % reservas que forman una recurrente
bloqueo(Recurso, Motivo, Desde, Hasta).         % Motivo: mantenimiento | calibracion; Hasta puede ser desconocido
evento_reserva(Reserva, Evento, Minuto).        % Evento: solicitada | aprobada | entrada | salida | cancelada
evento_equipo(Equipo, Evento, Responsable, Minuto).  % Evento: prestado | devuelto
espera(Grupo, Lab, Desde).                      % lista de espera
```

## Contrato del gemelo

- `decide(+Solicitudes, -Reparto, -Explicacion)` — predicado central. `Solicitudes` es una
  lista de peticiones (puede ser de una): reservas nuevas, una clase fija que entra en un
  calendario ocupado, una serie por colocar o reservas a reubicar. `Reparto` asigna a cada
  una laboratorio, equipos e inicio sin traslape de sala, de equipo ni de aforo, e incluye
  las reservas desplazadas. `Explicacion` justifica cada asignación. Al pedir más
  soluciones debe dar los demás repartos válidos. Si no existe ninguno (bloques o equipos
  insuficientes), lo dice y señala qué solicitud queda sin lugar y por qué, sin fallar en
  silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre una reserva,
  un equipo, un bloque o un responsable (por ejemplo reserva afectada, equipo disponible,
  reserva fantasma, adeudo, ocurrencia de una serie en riesgo), consultables en cualquier
  dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el calendario de cada laboratorio con los bloques realmente
  disponibles, el reparto con su explicación, los equipos con su estado real, los adeudos
  y las reservas en duda, y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Clase fija.** Una clase que entra en un calendario ocupado produce un plan completo:
   las reservas desplazadas se reubican sin traslape cuando existe lugar, y la explicación
   nombra el motivo de cada movimiento y los planes alternativos. Si no alcanza, dice a
   quién se le falla, por qué a él y qué bloque lo resolvería. Una práctica sin dónde ir
   no se cancela sin explicación.
2. **Serie y mantenimiento.** Cada ocurrencia sale como afectada, libre o «no se sabe»; un
   mantenimiento sin fin conocido nunca vuelve «libre» a una ocurrencia posterior sin
   avisarlo. Las ocurrencias no afectadas se conservan. Las reubicadas respetan sala,
   equipo y aforo, y la explicación nombra qué se cedió.
3. **Equipo en el límite.** Dos reservas que se tocan por un minuto no se resuelven solo
   con la hora: el gemelo considera dónde está el equipo y si la devolución consta. «No
   consta» da «no se sabe», distinto de «no se devolvió». La hipótesis «el responsable lo
   devolvió» cambia la respuesta.
4. **Reserva fantasma.** «No consta la entrada» no se trata como «no llegó» sin avisarlo.
   Un equipo sin devolver produce un adeudo, el adeudo bloquea otras reservas del
   responsable, y la explicación muestra la cadena completa. Liberar un bloque nombra a
   quién entra y a quién se le falla si el responsable aparece.
5. **Semana de proyectos.** Con varias solicitudes a la vez, el gemelo atiende a todas si
   existe un reparto que lo permite, aunque no siga el orden de llegada; que sobren horas
   libres no basta. Si no existe, nombra el cuello de botella, a quién se le falla y qué
   bloque o equipo lo resolvería. Nunca produce un traslape de sala, de equipo ni de aforo.
6. **Las cinco preguntas** de «Por qué no basta un script» se contestan con consultas
   sobre las mismas reglas, sin predicados duplicados por pregunta.

## Verificación

```bash
swipl -g run_tests -t halt tests/reglas_tests.pl   # pruebas plunit
swipl servidor.pl                                   # arranca el gemelo y su interfaz
```

Nombres de archivo sugeridos: `hechos.pl`, `reglas.pl`, `servidor.pl`,
`tests/reglas_tests.pl`, `web/`. No afirmes que algo pasa si no lo ejecutaste.

## Interfaz

Se diseña en Google Stitch antes de programarla. Debe mostrar el calendario por laboratorio
con los bloques realmente disponibles, el estado de cada equipo (incluido «sin constancia
de devolución»), el reparto propuesto con su explicación, las reservas en duda o
fantasma, los adeudos, la lista de espera frente a un bloque y la respuesta a «qué falta».
Debe verse bien en celular.
