# Contexto para agentes — gemelo digital del proyecto #53 (Paneles solares)

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
  se marca como supuesto y se le pide al estudiante la fuente. Los paneles, los equipos,
  el acumulador y el corte de luz de los ejemplos son del ejercicio, no del mundo.

## Dominio

| Término | Significado |
|---|---|
| kWp | Potencia pico del arreglo de paneles; el sistema del ejemplo es de 4 kWp |
| Irradiancia | Energía solar que llega al panel; es la condición de la que más depende lo esperado |
| Producción esperada | Lo que el sistema debería entregar con la irradiancia y la temperatura del momento |
| Inversor | Convierte la energía de los paneles; reporta potencia, voltaje, corriente, temperatura y fallas |
| Medición neta | La energía inyectada a la red se compensa con la consumida (CFE) |
| Excedente / déficit | Producción menos consumo, positivo o negativo, en un mismo instante |
| Capa marina | Niebla matutina costera (primavera y verano) que baja la producción de la mañana |
| Sombra / suciedad / falla | Tres causas de rendimiento anormal; ninguna se mide, se deducen |
| Desfase de relojes | Diferencia entre el reloj del medidor de producción y el de consumo |
| Acumulador | Batería de la casa; complemento de esta extensión (foco: almacenar) |
| Equipo continuo / partible | Debe correr sin interrumpirse / puede hacerse en ratos; ejemplo del ejercicio |

Cifras de referencia (del original): 5 a 5.5 horas solares pico en Tijuana; paneles de
400 a 550 W y ~20 % de eficiencia; 3 a 5 kWp producen unos 15 a 25 kWh/día; cada °C sobre
25 °C resta ~0.3-0.4 %; medición neta hasta 500 kW; escenario de 4 kWp con datos cada
minuto, una nube que baja 70 % por 10 minutos y un panel con sombra desde las 3 p. m.
Marcados como del ejercicio, sin cifras: 8 paneles en 2 cadenas, lectura por panel,
irradiancia, acumulador, equipos y su tipo, corte de luz, pronóstico y su historial.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Si la simulación necesita azar (una nube, un pronóstico que falla), el valor entra como
  hecho; las reglas no sortean nada.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                            % instante del gemelo, en minutos desde la medianoche
panel(Panel, Cadena).
medidor(Medidor, Tipo).                   % Tipo: produccion | consumo | irradiancia | acumulador
equipo(Equipo, Tipo).                     % Tipo: continuo | partible
plazo(Equipo, Minuto).                    % hasta cuándo debe estar terminado
rango(Variable, Minimo, Maximo).          % rango físico: potencia, temperatura, irradiancia
lectura(Medidor, Variable, Valor, Minuto).% el Minuto es el del reloj de ese medidor
evento(Medidor, Evento, Detalle, Minuto). % falla, corte de luz, arranque de un equipo
pronostico(Periodo, Cielo, Emitido).      % Cielo: despejado | nublado | capa_marina
```

## Contrato del gemelo

- `decide(+Entidad, -Decision, -Explicacion)` — predicado central. La entidad es un
  panel, un equipo, un minuto o la casa; el estudiante elige cómo representarla. Para un
  panel, `Decision` es qué se hace con su producción (normal, vigilar, revisar o por qué
  no se puede saber); para un minuto, si hay excedente y qué hacer con él (consumir,
  guardar o inyectar). `Explicacion` es una lista de hechos, lecturas, reglas y
  evidencias que la justifican. Para repartir equipos (situación 4) el primer argumento
  puede ser la LISTA de equipos y `Decision` el reparto completo; al pedir más soluciones
  debe dar los demás repartos válidos, y si no existe ninguno lo dice y señala el motivo,
  sin fallar en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (nube, falla,
  sombra, suciedad, desfase de relojes, excedente seguro), consultables en cualquier
  dirección: dado un panel, sus problemas; dada una situación, quiénes la cumplen.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de paneles y medidores, la decisión con su
  explicación, el desfase deducido y con qué eventos, el reparto de equipos y «qué falta
  para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Nube o falla.** Una caída de todos los paneles que coincide con la caída de la
   irradiancia y se recupera sale como nube; una caída de un solo panel con irradiancia
   normal y sin recuperación, como falla probable, con o sin código del inversor. Sin
   irradiancia en esos minutos la respuesta es «no se sabe», distinta de «no hay falla»,
   y una lectura ausente nunca cuenta como cero ni produce alerta.
2. **Baja esperada y baja anormal.** La baja matutina con capa marina se marca como
   esperada y la de la tarde en un solo panel como anormal, con la causa más probable y
   las descartadas. Si dos causas quedan empatadas, lo dice y nombra qué observación las
   separaría.
3. **Relojes.** Dos eventos vistos por ambos medidores permiten deducir el desfase, y la
   evidencia los cita. Con desfases contradictorios no se inventa uno: el excedente sale
   como «posible» o «no se sabe». Ningún excedente se afirma comparando el mismo minuto
   de los dos relojes sin haber alineado.
4. **Reparto.** Cada equipo respeta su tipo y su plazo. Si no caben todos, la respuesta
   dice quién cede y por qué; una recomendación que solo vale si el pronóstico acierta lo
   declara. Un pronóstico con mal historial genera menos recomendaciones, no más.
5. **Consumir, guardar o inyectar.** La recomendación cita la producción restante (con
   la sombra), el excedente, el espacio del acumulador y el consumo previsto, y nombra
   la prioridad que decidió. Una carga del acumulador vieja se declara como tal y la
   decisión lo refleja.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar la producción real contra
la esperada por panel, la causa de cada baja con sus tres respuestas, el desfase deducido
con sus eventos, el reparto de equipos con quién cede, la recomendación de consumir,
guardar o inyectar con su explicación, lo inferido marcado como tal y la respuesta a
«qué falta». Debe verse bien en celular.
