# Contexto para agentes — gemelo digital del proyecto #17 (Servidor de juego)

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
| Servidor autoritativo | El cliente propone; el servidor decide qué pasó |
| Sala | Una partida con sus jugadores y su registro de eventos |
| Tick | Un paso de la simulación de una sala; el original usa 30 por segundo |
| Presupuesto del tick | Tiempo que tiene un tick para terminar; si se pasa, el tick «se atrasó» |
| Lag / latencia | Retraso entre cliente y servidor; el original cita 400 ms como caso extremo |
| Pérdida | Paquetes que no llegan; el original cita 10 % |
| Número de secuencia | Orden con que el cliente numera sus jugadas (supuesto de esta extensión) |
| Matchmaking | Formar salas balanceadas sin esperar eternamente |
| Bot | Jugador automático que cubre a un desconectado (supuesto de esta extensión) |
| Torneo | Eliminación de 8 jugadores; el ganador de cada partido alimenta al siguiente (inventado) |

Cifras de referencia, todas del problema original: 30 ticks/s; 400 ms de lag y 10 % de
pérdida; salas de 8 jugadores; ≈ 24,000 entradas/s. Inventados por esta extensión y no
presentables como datos reales: 4 salas y hasta 14 jugadores, el torneo, los niveles, los
vetos, los grupos de amigos y la posición de la situación 2.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Los retrasos y la pérdida de paquetes no se sortean: entran como hechos.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Ms).                              % instante del modelo, en milisegundos
rango(Variable, Minimo, Maximo).        % latencia_ms, perdida_pct
lectura(Jugador, Variable, Valor, Ms).  % medición de red, con su instante
jugador(Jugador, Nivel).
sala(Sala, Juego, Estado).              % Juego: tres_en_raya | trivia
participa(Jugador, Sala, Marca).        % Marca: x | o | pulsador
evento(Sala, Tipo, Detalle, Ms).        % jugada, pulsacion, desconexion, regreso, caida, tick_atrasado
en_cola(Jugador, Juego, DesdeMs).
amigos(Jugador1, Jugador2).
veta(Jugador1, Jugador2).
partido(Partido, Ronda, Sala).
alimenta(PartidoOrigen, PartidoDestino).  % el ganador de uno juega en el otro
```

## Contrato del gemelo

- `decide(+Solicitudes, -Decision, -Explicacion)` — predicado central. `Solicitudes` es la
  LISTA de lo que se pregunta (puede ser de una): jugadas a validar, pulsaciones a ordenar,
  jugadores en cola, partidos afectados. `Decision` es el reparto, plan o ruta completo
  (los veredictos por jugada y el tablero resultante; el orden de pulsaciones; la
  formación de salas; la secuencia de jugadas o el plan del torneo). Al pedir más
  soluciones debe dar las demás alternativas válidas. Si no existe ninguna (cola sin
  reparto posible, orden indeterminable) lo dice y señala el motivo, sin fallar en silencio.
  `Explicacion` es una lista de hechos y condiciones que justifican la decisión.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  jugada repetida, indicio de trampa, partido bloqueado), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de las salas, la decisión con su explicación y
  «qué falta para que cambie». Hay información que el jugador no debe ver (por ejemplo,
  los criterios de detección de trampas): la API debe poder separar lo que ve el jugador
  de lo que ve el operador.

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Jugada legal.** Una jugada sobre casilla ocupada, una de quien no tiene el turno y una
   repetida reciben veredictos distintos, cada uno con su razón. Una jugada con hueco
   anterior da «no se sabe», nunca «ilegal», y la explicación nombra la jugada que falta.
   La consulta de jugadas legales usa la misma regla que valida una sola.
2. **Mejor jugada.** En la posición de la situación 2, tomar otra esquina se reconoce como
   la jugada que pierde y la explicación muestra la secuencia de réplicas; las jugadas
   sobre las aristas empatan. Pedir más soluciones devuelve las equivalentes.
3. **Pulsación.** Dos pulsaciones cuyo orden depende del lag producen un veredicto con la
   evidencia que lo sostiene. Quien llegó primero no gana automáticamente. Si el tick se
   atrasó y no hay otro dato, la respuesta es «no se sabe», distinta de «gana alguien».
   Cambiar la latencia como hipótesis cambia la respuesta sin duplicar reglas.
4. **Matchmaking.** Ningún reparto junta a quienes se vetaron; la cola ofrece varias alternativas válidas con la razón de por qué
   cada jugador fue o no incluido. Si no hay reparto, lo dice y nombra la restricción.
5. **Torneo.** Una sala caída marca como bloqueados los partidos que dependen de ella, en
   cascada. Una partida terminada antes de caer tiene resultado; una a medias da
   «no se sabe». El plan nombra la regla que decide a quién se le falla.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar cada sala con su tablero o
sus pulsaciones, la decisión, la explicación (con la vista del jugador separada de la del
operador), la cola con los repartos posibles, el cuadro del torneo con los partidos
bloqueados y la respuesta a «qué falta». Debe verse bien en celular.
