# Contexto para agentes — gemelo digital del proyecto #73 (Quiniela del Mundial)

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
| Quiniela | Grupo privado de participantes con un reglamento propio de puntos y desempates |
| Pronóstico | Marcador o ganador que un participante fija para un partido antes de que inicie |
| Bloqueo | Momento desde el cual un pronóstico ya no se puede enviar ni cambiar |
| Marcador exacto | Acierto completo del resultado; vale 3 puntos en las reglas comunes |
| Ganador o empate | Acierto del sentido del resultado sin el marcador; vale 1 punto |
| Bono de fase | Puntos extra por acertar campeón o goleador, entre otros |
| VAR | Revisión en video; puede anular un gol minutos después de contado |
| Tiempo extra / penales | Prolongación y definición de un partido empatado en eliminación directa |
| Fuente externa | API de resultados: con límites de uso, retrasos y posibles inconsistencias |
| Desempate | Criterio, y su orden, que separa a participantes con igual puntaje |

Cifras de referencia, todas del problema original: 3 puntos por marcador exacto; 1 por
acertar ganador o empate; bonos por fases (campeón, goleador); Mundial 2026 con 48
selecciones y 104 partidos; Qatar 2022 con 32 selecciones y 64 partidos; escenario de
5,000 participantes, 50 quinielas, 4 partidos en simultáneo, 64 partidos y 2,000
pronósticos en los 60 segundos previos a un inicio.

Del ejercicio, no del original: la escala reducida (6 participantes, 2 quinielas, 8
selecciones, 7 partidos), los nombres, los marcadores de los ejemplos y todo reglamento
más allá de 3 puntos, 1 punto y «bonos por fases». Márcalos como tales.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar pronósticos simulados o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundo).                         % segundos desde el origen que elija el estudiante
partido(Partido, Fase, Local, Visitante).
inicio_programado(Partido, Segundo).
evento(Partido, Tipo, Detalle, Segundo).   % gol, anulacion_var, entretiempo, tiempo_extra...
miembro(Participante, Quiniela).
regla_quiniela(Quiniela, Concepto, Valor). % reglamento propio; lo define el estudiante
pronostico(Id, Participante, Partido, Marcador).
recepcion(Id, Fuente, Reloj, Segundo).     % Fuente: servidor | dispositivo
pronostico_especial(Participante, Tipo, Valor). % campeon | goleador
resultado_fuente(Partido, Fuente, Marcador, Segundo). % lo que publicó cada API externa
```

## Contrato del gemelo

- `decide(+Entidad, -Decision, -Explicacion)` — predicado central. `Entidad` dice qué se
  decide: un pronóstico (¿vale?) o un participante dentro de una quiniela (¿qué lugar
  tiene?, ¿aún puede ganar?); el estudiante fija la forma de esos términos y la
  documenta. `Explicacion` es una lista de hechos y condiciones que justifican la
  decisión.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  pronóstico fuera de tiempo, empate provisional o participante sin posibilidad de
  ganar), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el ranking de cada quiniela con sus empates, la decisión sobre
  un pronóstico con su explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus reglamentos.

1. **Bloqueo.** Un pronóstico recibido claramente antes del inicio se acepta y uno
   claramente después se rechaza, aun si el reloj de quien lo envió dice lo contrario.
   Un caso con datos insuficientes da «no se sabe», con el dato que falta para decidir.
2. **Puntos por quiniela.** Un mismo pronóstico sobre un mismo partido produce puntos
   distintos en dos quinielas con reglamentos distintos, con el desglose que explica la
   diferencia y sin predicados duplicados por quiniela.
3. **Corrección del VAR.** Tras una anulación, el marcador vigente cambia, los afectados
   incluyen a quienes ganan puntos además de a quienes los pierden, y se señala qué
   parte del ranking publicado quedó desactualizada. Con fuentes contradictorias y sin
   criterio para elegir, el marcador es «no se sabe», no uno de los dos.
4. **Desempate.** Los mismos participantes pueden quedar en lugares distintos en dos
   quinielas; la explicación nombra el criterio decisivo. Un empate que ningún criterio
   rompe se reporta como empate, y uno que aún depende de partidos pendientes se marca
   provisional.
5. **¿Todavía puede ganar?** Distingue «ya no puede», «puede» y «depende». Un bono
   cuyo dato aún no existe es «depende», no «no». La consulta inversa dice qué tendría
   que ocurrir para que alguien alcance el primer lugar.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el ranking de cada
quiniela con posiciones, empates y puntos por partido; el veredicto de cada pronóstico
con su explicación; el marcador vigente de cada partido y qué cambió tras una
corrección; y, por participante, si aún puede ganar y qué le falta. Debe verse bien en
celular.
