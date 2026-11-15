# Contexto para agentes — gemelo digital del proyecto #72 (Torneo de esports)

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
| Cuadro (*bracket*) | Estructura de partidas; cada una alimenta a otra con su ganador (y, en doble eliminación, su perdedor al cuadro de perdedores) |
| Eliminación simple | Con N equipos se juegan N−1 partidas |
| Doble eliminación | Cuadro de ganadores y de perdedores; un equipo sale tras dos derrotas; unas 2N−2 partidas y una final que puede reiniciar el cuadro |
| *Bye* | Pase directo cuando N no es potencia de 2; no es una victoria |
| Serie | Al mejor de 1, 3 o 5 mapas; el marcador se actualiza mapa a mapa |
| *No-show* | Equipo que no se presenta |
| Disputa | Resultado reportado de forma contradictoria; no hay ganador conocido |
| Partida lista | Alimentadoras terminadas, equipos definidos, sin disputa |

Cifras de referencia, todas del original: N−1 partidas (cuadro de 16: 4 rondas y 15
partidas), unas 2N−2 en doble eliminación, series de 1, 3 o 5 mapas, escenario de 64
equipos, 8 mesas y 300 espectadores. **Inventado por esta extensión:** 12 equipos, 3 mesas,
2 árbitros, la serie al mejor de 3 con marcador 1-0 y la liga escolar con becas de los
ejemplos; el escenario no es una estadística real.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar resultados simulados o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                       % minutos desde que abre el torneo
equipo(Equipo).
partida(Partida, Cuadro).            % Cuadro: ganadores | perdedores | final
alimenta(Origen, Cual, Destino).     % Cual: ganador | perdedor
entra_en(Equipo, Partida).           % equipo que entra directo a una partida (incluye byes)
serie(Partida, MejorDe).             % 1 | 3 | 5
mesa_de(Partida, Mesa).
arbitro_de(Partida, Arbitro).
evento(Sujeto, Suceso, Instante).    % Sujeto: partida o equipo; Suceso: programada, inicia,
                                     % reporta(Equipo, Marcador), confirma(Arbitro, Ganador),
                                     % no_show(Equipo), descalificado
```

## Contrato del gemelo

- `decide(+Solicitudes, -Decision, -Explicacion)` — predicado central. `Solicitudes` es la
  LISTA de cosas por resolver (un reporte, una corrección, una descalificación, partidas que
  piden mesa; puede ser una sola). `Decision` es el plan completo: estado del cuadro,
  partidas anuladas o por definir, orden de uso de mesas. Al pedir más soluciones debe dar
  las demás alternativas válidas. Si no existe ninguna, lo dice y señala el motivo, sin
  fallar en silencio. `Explicacion` es una lista de hechos, condiciones y caminos del
  cuadro que justifican la decisión.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (partida en
  disputa, partida lista, equipo afectado por una corrección, ronda de un equipo),
  consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el cuadro con el estado de cada partida, la decisión con su
  explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario.

1. **Corrección.** Corregir un resultado antiguo marca como anuladas las partidas que
   dependían de él, en ambos cuadros, cada una con su camino; no marca las que no
   dependían. Un equipo antes eliminado puede reaparecer como vivo.
2. **Disputa.** Dos reportes contradictorios dan «en disputa», no un ganador. Las partidas
   que dependen del resultado quedan «por definir» y las demás siguen. La política sobre
   programar con un ganador provisional queda dicha y justificada.
3. **Descalificación.** El rival avanza, el descalificado no cae al cuadro de perdedores
   como perdedor y la serie en curso termina por una secuencia de estados válida. La política
   sobre quien perdió contra él es explícita y la explicación nombra a quién le falla.
4. **Rondas y byes.** La ronda de cada equipo sale del árbol; «sin rival» se distingue de
   «rival por definir»; el total de partidas reales se explica sin tratar un *bye* como
   victoria.
5. **Mesa y árbitro.** Se listan los órdenes válidos; si no hay ninguno se dice y se señala
   el choque. Un *no-show* de una partida que nunca pudo empezar no se atribuye al equipo.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el cuadro (ganadores y
perdedores) con el estado de cada partida y marcar las disputadas o anuladas, la decisión,
la explicación con el camino por el cuadro y la respuesta a «qué falta». Debe verse bien en
celular.
