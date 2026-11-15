# Contexto para agentes — gemelo digital del proyecto #75 (Carreras simuladas)

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
- Las apuestas son con fichas virtuales, nunca dinero real. La escala (6 pilotos, 10
  vueltas, unas 12 apuestas) y los nombres de los ejemplos son del ejercicio.

## Dominio

| Término | Significado |
|---|---|
| Carrera | Evento con una salida y una serie de vueltas; pasa por etapas que se deducen de sus eventos |
| Etapa | Apuestas abiertas, cerradas, en curso, neutralizada, suspendida, terminada o cancelada |
| Safety car | Neutraliza la carrera y comprime al grupo |
| Pits | Zona de paradas; la parada pierde tiempo respecto a quien sigue en pista |
| Fotofinish | Dos pilotos con el mismo tiempo, medido en milésimas |
| Parimutuel | El pago sale de repartir lo apostado entre los ganadores, menos la comisión |
| Pozo neto | Total apostado menos la comisión de la casa |
| Ficha | Unidad virtual de apuesta; entera, de ahí el residuo del reparto |
| Reembolso | Se devuelven las fichas apostadas |
| Bitácora / cronometraje | Fuentes de eventos: captura manual de la dirección y medición automática |

Cifras de referencia, todas del problema original: parrilla de 20 autos, vuelta de unos
70-100 s, 50-70 vueltas, tiempos en milésimas, parada en pits de 2-3 s con pérdida total
de 20-25 s, escenario de 20 pilotos, 50 vueltas, 1,000 espectadores y 500 apuestas,
safety car en la vuelta 20 y 3 paradas simultáneas. El original no da el porcentaje de
la comisión ni ninguna regla de cierre de apuestas: son del estudiante.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar carreras simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  La suerte de la carrera no se sortea en las reglas: sus eventos y tiempos entran como
  hechos.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Milesimas).                                  % milésimas de segundo desde la apertura de apuestas
carrera(Carrera, Vueltas).
piloto(Piloto, Carrera).                           % inscrito en la carrera
salida_programada(Carrera, Instante).
apuesta(Apuesta, Apostador, Piloto, Fichas).       % a ganador; parimutuel
evento(Fuente, Sujeto, Evento, Instante).          % Fuente: servidor | aparato | cronometraje | direccion | bitacora
rango(Variable, Minimo, Maximo).                   % valores posibles, no los típicos
lectura(Piloto, Vuelta, Variable, Valor, Instante).% Variable: tiempo_vuelta (milésimas)
```

`Sujeto` en `evento/4` puede ser una carrera, un piloto o una apuesta. La etapa de la
carrera, el estado de cada piloto, si una apuesta cuenta y el pago **no son hechos**: se
deducen de los eventos. La comisión, el cierre de apuestas y los plazos son predicados
que añade el estudiante con sus supuestos.

## Contrato del gemelo

- `decide(+Carrera, -Decision, -Explicacion)` — predicado central. `Decision` es lo que
  procede con la carrera en el «ahora»: abrir o cerrar apuestas, dar la salida, seguir,
  neutralizar, reanudar, suspender, cancelar y reembolsar, declarar resultado y liquidar;
  incluye el veredicto de cada apuesta y, si hay resultado, su pago. Cuando se le da una
  secuencia de eventos propuesta o desordenada, devuelve una secuencia válida; al pedir
  más soluciones da los demás órdenes válidos, y si no existe ninguno lo dice y señala el
  evento que lo impide, sin fallar en silencio. `Explicacion` es una lista de hechos,
  condiciones y reglas que justifican la decisión.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  etapa de la carrera, piloto sin dato, apuesta fuera de ventana, evento imposible,
  empate real), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado deducido de la carrera, de los pilotos y de las
  apuestas, la decisión con su explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Apuesta en la salida.** Una apuesta recibida claramente antes de la salida cuenta;
   una claramente después no cuenta. En la frontera, o con un aparato sin hora, el
   resultado es «no se sabe» o lo que decida la regla escrita, con ambos relojes en la
   explicación. Una apuesta rechazada termina en reembolso.
2. **Safety car.** Un adelantamiento registrado mientras la carrera está neutralizada no
   cambia la clasificación. Dos eventos con el mismo instante dan todos los órdenes
   compatibles con las etapas, y uno incompatible se descarta señalando por qué.
3. **Piloto callado.** Un piloto sin reportes aparece como «no se sabe», distinto de
   «abandonó». Si otros pilotos también callan, la explicación apunta al sistema y no
   al piloto, y sus apuestas no se pierden. Un registro tardío de alguien declarado
   fuera se señala como contradicción y no se acepta en silencio.
4. **Fotofinish.** Dos pilotos con el mismo tiempo producen un empate explícito, no un
   ganador elegido al azar. El total repartido cuadra con el pozo neto, sin fichas
   perdidas, y una carrera sin apuestas ganadoras tiene un destino escrito para el pozo.
5. **Suspensión.** Una cancelación que solo anotó la bitácora y no confirmó la dirección
   da «no se sabe». Una carrera cancelada y una suspendida con resultado se tratan
   distinto, y la explicación dice cuál regla separa una de la otra. Una apuesta que
   llega con la carrera detenida se rechaza y se reembolsa.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar la etapa de la carrera, la
línea de tiempo de eventos (válidos, inválidos y en duda), la clasificación vigente, el
estado de cada piloto («sigue», «abandonó», «no se sabe»), cada apuesta con su veredicto
y sus fichas, la liquidación con el pozo, la decisión con su explicación y la respuesta
a «qué falta». Debe verse bien en celular.
