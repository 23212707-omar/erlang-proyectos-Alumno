# Contexto para agentes — gemelo digital del proyecto #43 (Citas médicas)

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
| Hueco | Intervalo de la agenda de un médico en que cabe una cita; «libre» exige también consultorio y preparación |
| Consultorio | Espacio que una cita ocupa; es un recurso distinto del médico |
| Bloque | Guardia, vacaciones, cirugía o limpieza que quita tiempo a un médico o a un consultorio |
| Tipo de cita | Consulta general, primera vez o procedimiento; cada uno dura distinto |
| Preparación y limpieza | Tiempo alrededor de la consulta en que el consultorio no puede usarse |
| No-show | Paciente que no se presenta a su cita |
| Sobre-agenda | Dar más citas que huecos, apostando a los no-show (*overbooking*) |
| Recordatorio | Aviso a 48 h y a 2 h antes de la cita, con opción de confirmar o cancelar |
| Lista de espera | Pacientes a quienes se ofrece un hueco liberado por una cancelación |
| Cambio de horario | Día en que el reloj se adelanta o atrasa; altera «a 48 h» y «a 2 h» |

Cifras de referencia, todas del problema original: no-show entre 15 % y 30 % (20 % en el
escenario); consulta general de ~15-30 min y primera vez o procedimiento de ~45-60 min,
con tiempos de preparación y limpieza sin cifra; recordatorios a 48 h y 2 h; el escenario
completo tiene 10 médicos, 4 consultorios y 200 citas al día, y un médico enfermo deja 15
citas sin atender. Los 4 médicos, 2 consultorios, el contexto de clínica en Tijuana, los
pacientes y los números de los ejemplos son del ejercicio, no cifras del dominio.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar citas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Los no-show no se sortean: el resultado entra como hecho o como supuesto del estudiante.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                                  % los instantes se cuentan en minutos
recurso(Recurso, Clase).                        % Clase: medico | consultorio
bloqueo(Recurso, Motivo, Desde, Hasta).         % Motivo: guardia | vacaciones | cirugia | limpieza
duracion(Tipo, Consulta, Preparacion).          % Tipo: general | primera_vez | procedimiento
cita(Cita, Paciente, Medico, Consultorio, Tipo, Inicio).
evento_cita(Cita, Evento, Minuto).              % Evento: agendada | confirmada | cancelada | atendida | no_asistio
recordatorio(Cita, Momento, Estado, Minuto).    % Momento: h48 | h2; Estado: programado | enviado | entregado | fallido
preferencia(Paciente, Clase, Valor).            % Clase: medico | momento; si no hay hecho, no se sabe
espera(Paciente, Tipo, Medico, Desde).          % lista de espera; Medico puede ser cualquiera
inasistencia(Paciente, Cita, Minuto).           % cita a la que no se presentó
cambio_horario(Minuto, AjusteMinutos).          % instante del cambio y cuánto mueve el reloj
```

## Contrato del gemelo

- `decide(+Solicitudes, -Reparto, -Explicacion)` — predicado central. `Solicitudes` es una
  lista de peticiones (puede ser de una): citas nuevas, citas a reubicar o pacientes de la
  lista de espera frente a un hueco. `Reparto` asigna a cada una médico, consultorio e
  inicio sin traslape. `Explicacion` justifica cada asignación. Al pedir más soluciones
  debe dar los demás repartos válidos. Si no existe ninguno (huecos insuficientes), lo
  dice y señala qué solicitud queda sin lugar y por qué, sin fallar en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre un hueco,
  una cita, una franja o un paciente (por ejemplo hueco utilizable, recordatorio debido,
  recordatorio en duda, riesgo de ausencia, elegible para un hueco), consultables en
  cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: la agenda con huecos reales, el reparto con su explicación, los
  recordatorios debidos, cumplidos y en duda, el riesgo por franja y «qué falta para que
  cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Hueco real.** Un horario libre en la agenda del médico pero con consultorio ocupado,
   en limpieza o pisando un bloque no se ofrece, y la explicación nombra qué recurso
   falla. Con dos solicitudes que compiten, el gemelo atiende a ambas si existe un
   reparto que lo permite, aunque no siga el orden de llegada. Si no, dice quién queda sin
   lugar y por qué. Nunca produce un traslape de médico ni de consultorio.
2. **Reubicación masiva.** Un conjunto de citas sin médico se reparte sin traslape; la
   explicación nombra la preferencia cedida en cada caso y los repartos alternativos. Si
   no alcanza, nombra a quién se le falla y qué hueco lo resolvería. Quien no dio
   preferencia aparece como «no se sabe», no como «cualquiera».
3. **Sobre-agenda.** La misma tasa de no-show da respuestas distintas en franjas con
   distintas confirmaciones. Una franja casi confirmada no admite cita extra; la de
   «no se sabe» lo dice y no se trata como «sí» ni «no». El peor caso (todos llegan) se
   puede consultar, y la hipótesis «este paciente confirma» cambia la respuesta.
4. **Recordatorios.** Para cada cita, el gemelo separa lo que debió salir, lo que consta,
   lo que falló y lo que está en duda; «sin constancia» nunca se vuelve «no salió» sin
   avisarlo. Tras un reinicio no propone duplicar un aviso con constancia. En el día del
   cambio de horario, el instante del aviso de 2 h es el correcto y la explicación lo dice.
5. **Hueco liberado.** Quien no cabe en el hueco, o a quien ya no da tiempo de avisar, no
   es elegible aunque vaya primero. Entre elegibles, la explicación dice por qué uno gana
   y a quién se le falla. Si nadie es elegible, lo dice y por qué.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar la agenda por médico y
consultorio con los huecos reales (y los que solo lo parecen), el reparto propuesto con su
explicación, el estado de cada recordatorio (incluido «en duda»), el riesgo de ausencia
por franja, la lista de espera frente a un hueco y la respuesta a «qué falta». Debe verse
bien en celular.
