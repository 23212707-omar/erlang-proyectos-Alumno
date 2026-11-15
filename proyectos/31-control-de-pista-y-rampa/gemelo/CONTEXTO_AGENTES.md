# Contexto para agentes — gemelo digital del proyecto #31 (Control de pista y rampa)

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
| Movimiento | Despegue o aterrizaje; ocupa la pista de 1 a 2 minutos |
| Secuencia | Orden en que los movimientos usan la pista única |
| Separación por estela | Tiempo mínimo entre dos movimientos según la categoría de ambos; mayor si una pesada precede a una ligera |
| Prioridad | Las aeronaves en aproximación pasan a las que esperan salir; las emergencias pasan a todos |
| Emergencia | Médica o de combustible; reordena la secuencia sin violar separaciones |
| Pushback, arranque, rodaje | Pasos de una salida normal; el rodaje dura de 5 a 15 minutos en aeropuertos concurridos |
| A-CDM | Toma de decisiones colaborativa en aeropuerto |
| TOBT | Hora objetivo de fin de rotación |
| TSAT | Hora objetivo de autorización de arranque |
| Servicios de rampa | Pasarela, combustible, equipaje, limpieza, catering y remolque |
| Equipo compartido | Tractores, unidades de energía y camiones de combustible; son pocos y se comparten entre puertas |
| Vuelo crítico | Vuelo que su operador marca como tal; es una convención de esta extensión |

Cifras de referencia, todas del problema original: movimiento de 1 a 2 minutos; rodaje de
5 a 15 minutos; 40 movimientos en 2 horas; una emergencia; un tractor para 3 aviones. La
escala de la extensión (12 movimientos, 4 puertas, 1 tractor), las separaciones, los
tramos de la plataforma, las duraciones de los servicios, sus dependencias y el vuelo
crítico son inventados por esta extensión o por el estudiante.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar movimientos simulados o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Las emergencias, los retrasos de servicio y los reportes perdidos entran como hechos,
  no se sortean.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                          % minutos desde el inicio de la ventana
vuelo(Vuelo, Categoria, Tipo).          % Tipo: llegada | salida; Categoria: la define el estudiante
separacion(CatPrecede, CatSigue, Minutos). % estela entre categorías (inventada)
critico(Vuelo, Motivo).                 % vuelo marcado como crítico por su operador
servicio(Vuelo, Servicio, Duracion, Recurso). % pasarela | combustible | equipaje | limpieza | catering | remolque
precede(Servicio1, Servicio2).          % Servicio1 debe terminar antes de empezar Servicio2
recurso(Recurso, Tipo, Ubicacion).      % tractor | unidad_energia | camion_combustible
tramo(Origen, Destino, Minutos).        % plataforma y rodaje
rango(Variable, Minimo, Maximo).        % rango físico, por ejemplo posición o minutos
lectura(Entidad, Variable, Valor, Minuto). % posicion, estado_equipo, cierre_de_puerta
evento(Minuto, Tipo, Entidad, Detalle). % emergencia | servicio_termina | tobt | tractor_llega | aparece
```

## Contrato del gemelo

- `decide(+Solicitudes, -Plan, -Explicacion)` — predicado central. `Solicitudes` es la
  lista de lo que se pide resolver (movimientos por secuenciar, pushbacks por atender o
  salidas por liberar; puede ser de una). `Plan` es el reparto completo: la secuencia con
  sus horas, el orden de atención del tractor o la liberación de una salida.
  `Explicacion` justifica cada lugar y nombra a quién se le falla. Al pedir más soluciones
  debe dar las demás secuencias o repartos válidos. Si no existe ninguno (no hay hueco
  válido, ningún orden evita perder un turno, no se puede asegurar la separación), lo
  dice y señala el motivo, sin fallar en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre un vuelo,
  una puerta, un equipo o la pista (por ejemplo servicio que fija la salida, TSAT perdido,
  salida afectada en cadena, reporte dudoso), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de pista, puertas y equipos, la secuencia con su
  explicación, y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Emergencia.** La emergencia queda en el primer lugar válido, no necesariamente el
   primero de la cola, y ninguna separación se viola. La respuesta lista a cada afectado
   con su retraso y explica por qué no cabía un lugar antes. Si no hay lugar, lo dice.
2. **Pesada y ligera.** Se obtienen todas las secuencias que respetan separaciones y
   prioridades. La política elegida (mínimo total o proteger al crítico) aparece
   declarada una vez; el cambio de política cambia el veredicto sin tocar otras reglas.
   La explicación nombra a quién se le falla.
3. **Tractor.** El orden respeta que el tractor solo está en un lugar y que los tramos
   consumen tiempo. Se obtienen todos los órdenes válidos, y la explicación dice qué salida
   pierde su turno. Si ninguno evita perder uno, lo dice y señala el recurso que falta.
4. **Servicio retrasado.** La respuesta distingue el servicio que se retrasó del que
   fija la salida: un retraso fuera del camino que decide la salida no mueve el TSAT. Si
   el TSAT se pierde, la evidencia lista la cadena de salidas afectadas hasta la última.
5. **Dato dudoso.** Una posición vieja, un TOBT sin hito que lo respalde y un reporte
   viejo del tractor dan «no se sabe», distinto de «no se cumple»; nunca se libera una
   salida por un dato que no se puede creer. La respuesta marca la inferencia y nombra
   el dato que la resolvería.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar la secuencia de la pista
como línea de tiempo con cada movimiento y su categoría, las puertas con el avance de sus
servicios, el tractor y su recorrido propuesto, la emergencia y a quiénes desplaza, el
TOBT y el TSAT de cada salida, los datos dudosos marcados como inferencia, la explicación
de cada decisión con a quién se le falla, y la respuesta a «qué falta». Debe verse bien
en celular.
