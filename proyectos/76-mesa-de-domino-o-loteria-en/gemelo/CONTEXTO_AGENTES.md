# Contexto para agentes — gemelo digital del proyecto #76 (Mesa de dominó o lotería)

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
- Son juegos de mesa sin dinero. La escala (2 mesas, 9 jugadores) y los nombres y
  fichas de los ejemplos son del ejercicio.

## Dominio

| Término | Significado |
|---|---|
| Dominó doble seis | 28 fichas; 4 jugadores con 7 fichas cada uno; juego por turnos |
| Ficha | Par de números; la mano de cada jugador es privada |
| Extremos | Los dos números abiertos del tablero; se deducen de las jugadas |
| Pasar | No jugar en el turno; qué lo hace legal es regla del estudiante |
| Tranca | La mano termina sin que nadie se quede sin fichas; se gana por puntos |
| Lotería mexicana | 54 cartas; tablas de 4×4 (16 figuras); el gritón canta las cartas |
| Variante | Figura que gana en esa mesa: fila, columna, esquinas o tabla llena |
| Grito | Reclamo «¡lotería!» de un jugador; puede haber dos casi a la vez |
| Sesión | Un dispositivo conectado de un jugador; un jugador puede tener más de una |
| Bot | Sustituto que juega por un jugador ausente |
| Abandonada | Mesa sin quien la juegue; qué la define es regla del estudiante |

Cifras de referencia, todas del problema original: 28 fichas, 4 jugadores con 7 cada
uno, tablas de 4×4 con 16 figuras, 54 cartas, mesas de 2 a 10 jugadores, turno de
20-30 s como ejemplo, regreso a los 40 s, gritos con 50 ms de diferencia, escenario de
200 mesas (150 de dominó y 50 de lotería) y 700 jugadores. El original no da la regla
de puntos de la tranca, el desempate, el tiempo exacto por turno, la jugada del bot
ni cuándo una mesa se considera abandonada: son del estudiante.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar repartos simulados o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Las reglas no barajan ni sortean: el reparto de fichas y de cartas entra como hecho.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Milisegundos).                       % desde que empezó la mano o el juego de la mesa
mesa(Mesa, Juego).                         % Juego: domino | loteria
jugador(Jugador, Mesa, Tipo).              % Tipo: humano | bot
mano(Jugador, Ficha).                      % dominó: fichas repartidas, privadas
tabla(Jugador, Casilla, Carta).            % lotería: 16 casillas por tabla
variante(Mesa, Figura).                    % fila | columna | esquinas | tabla_llena
sesion(Sesion, Jugador, Dispositivo).
evento(Fuente, Sujeto, Evento, Instante).  % Fuente: servidor | aparato (hora que declara el cliente)
```

`Sujeto` en `evento/4` puede ser una mesa, un jugador o una sesión. Jugadas, pases,
cartas cantadas, gritos, caídas y regresos de sesión, y vencimientos de turno son
eventos. El tablero, sus extremos, de quién es el turno, la etapa de la mesa, qué
sesión manda, quién sigue presente y si una jugada o un grito valen **no son hechos**:
se deducen. Los plazos y las reglas de puntos son predicados que añade el estudiante
con sus supuestos. Un evento del aparato trae la hora que declara el cliente, que puede
faltar o contradecir al servidor.

## Contrato del gemelo

- `decide(+Mesa, -Decision, -Explicacion)` — predicado central. `Decision` es lo que
  procede en la mesa en el «ahora»: el siguiente paso válido (jugar una ficha, pasar,
  cantar la siguiente carta, aceptar o rechazar un grito, sustituir a un ausente, dar
  la mano por terminada con su ganador, esperar o cerrar la mesa) o la secuencia válida
  hasta el cierre de la mano. Al pedir más soluciones da las demás alternativas válidas,
  y si no existe ninguna lo dice y señala el evento que lo impide, sin fallar en
  silencio. `Explicacion` es una lista de hechos, condiciones y reglas que justifican la
  decisión; lo que ve cada jugador no incluye las manos ni las tablas de los demás.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  jugada legal, mano trancada, turno vencido, grito válido, sesión vigente, mesa
  abandonada), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado deducido de la mesa y de cada jugador, la decisión
  con su explicación según quién pregunta (jugador o árbitro) y «qué falta para que
  cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Jugada legal.** Una ficha que encaja pero que el jugador no tiene, una que tiene
   pero no encaja, o una enviada fuera de turno se rechazan, cada una por su causa. Un
   «paso» de quien sí tenía jugada se rechaza. La explicación para la mesa no revela
   fichas de otros y la consulta inversa dice qué sí habría sido legal.
2. **Tranca.** Tres pases seguidos no cierran la mano; cuando ya nadie puede jugar, sí,
   y se señala la jugada en que se trancó. Quién gana sale de comparar los puntos
   según la regla escrita y no de quién tiene menos fichas; un empate se trata
   explícitamente. Una mano que termina sin fichas no pasa por puntos.
3. **Turno vencido.** Una caída en el turno vence el turno, el sistema o el bot juega
   una jugada legal (o pasa, si no la hay) y al regresar el jugador recupera su mano
   ya sin esa ficha. La respuesta dice de quién es el turno ahora y qué regla decidió
   entre devolver la ficha o respetar lo jugado; no vale dejarlo sin explicar.
4. **Lotería.** Un grito con una carta marcada que aún no se cantaba no es válido,
   aunque haya llegado primero, y gana el otro. Si ambos son válidos y no se pueden
   ordenar, la respuesta es empate o «no se sabe» según la regla escrita, nunca un
   ganador arbitrario. Una hora declarada imposible se trata como dato dudoso.
5. **Sesiones y abandono.** De dos sesiones del mismo jugador manda una, con razón; la
   otra no recibe una mano distinta ni duplicada. Una sesión callada da «no se sabe»,
   distinto de «cerrada». Una mesa con bots que juegan pero sin humanos presentes se
   reconoce como abandonada, y una con un solo humano no, con su destino explicado.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar la mesa (tablero y
extremos en dominó, cartas cantadas en lotería), la mano o tabla de quien consulta y
nunca las de otros, el turno y el tiempo que queda, la línea de eventos (válidos,
rechazados y en duda), los jugadores con el estado de sus sesiones («conectado»,
«callado», «sustituido»), el veredicto de cada jugada o grito con su explicación y la
respuesta a «qué falta». Debe verse bien en celular.
