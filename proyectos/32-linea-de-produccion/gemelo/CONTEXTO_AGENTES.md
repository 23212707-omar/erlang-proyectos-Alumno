# Contexto para agentes — gemelo digital del proyecto #32 (Línea de producción)

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
| Estación | Puesto de trabajo de la línea; procesa una pieza a la vez |
| Ciclo | Tiempo que tarda una estación en procesar una pieza; varía ±10 % |
| Takt | Tiempo disponible entre demanda; cada cuántos segundos debe salir una unidad |
| Cuello de botella | Estación que fija la capacidad real de la línea; puede moverse |
| Buffer | Espacio de capacidad finita entre dos estaciones; absorbe variaciones |
| Bloqueada | Estación con pieza terminada que no puede entregarla porque el buffer siguiente está lleno |
| Inanición | Estación que espera piezas porque el buffer anterior está vacío |
| Paro | Detención por falta de material, falla de máquina, cambio de modelo o calidad |
| Cambio de modelo | Cambia el producto; alarga el ciclo de una estación (+20 % en la 6) |
| Pieza en proceso | Pieza que ya entró a la línea y aún no sale; en conjunto, el WIP |
| Técnico | Persona que atiende un paro; en el escenario hay uno solo (inventado) |

Cifras de referencia, todas del problema original: 8 estaciones; ciclos de 25 a 40 s con
±10 %; 7.5 h netas de turno (27,000 s) y 900 unidades por turno, takt de 30 s; buffers de
5 piezas; falla de 3 minutos en la estación 4; +20 % de tiempo en la estación 6 por cambio
de modelo; un paro de 5 minutos en el cuello pierde 5 minutos de toda la línea. Los
ciclos concretos por estación, los modelos, el técnico único con sus tiempos, y el paro
por calidad en la 6 son inventados por esta extensión.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  La variación de ±10 % de los ciclos y las fallas entran como hechos, no se sortean.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundo).                         % segundos desde el inicio de la ventana del escenario
estacion(Estacion, Orden, CicloNominal). % lugar en la línea (1 es la primera); ciclo en s
buffer(Buffer, Origen, Destino, Capacidad). % buffer entre dos estaciones consecutivas
turno(SegundosNetos, Demanda).         % tiempo disponible y unidades pedidas; de ahí sale el takt
modelo_vigente(Modelo, Desde).          % modelo en curso y desde qué segundo
ajuste_modelo(Modelo, Estacion, Porcentaje). % cuánto alarga el modelo el ciclo de la estación
tecnico(Tecnico, Ubicacion).            % técnico disponible y dónde está
rango(Variable, Minimo, Maximo).        % por ejemplo, nivel de buffer o contador de una estación
lectura(Estacion, Variable, Valor, Segundo). % estado reportado, contador, nivel; Segundo es cuando se midió
evento(Segundo, Tipo, Entidad, Detalle). % entra | sale | paro | reanuda | cambio_modelo | rechazo_calidad | conteo_fisico | llega_tecnico
```

## Contrato del gemelo

- `decide(+Paros, -Plan, -Explicacion)` — predicado central. `Paros` es la lista de paros
  por atender (puede ser de uno); `Plan` es el orden de atención completo con el efecto
  en cascada de cada paro sobre las demás estaciones; `Explicacion` justifica el orden y
  nombra a quién se le falla. Al pedir más soluciones debe dar los demás planes válidos.
  Si no existe ninguno (por ejemplo, no hay técnico), lo dice y señala el motivo, sin
  fallar en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre una
  estación, un buffer o una pieza (por ejemplo cuello de botella, bloqueada, en inanición,
  tiempo anómalo, pieza en duda), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de estaciones y buffers, la decisión con su
  explicación, la cascada de un paro y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Cuello.** La estación limitante se deduce del conjunto de la línea, no de su ciclo
   solo: una estación de ciclo largo que está bloqueada o sin piezas no se señala. Tras
   un cambio de modelo o un paro, la respuesta puede cambiar con las mismas reglas. Se
   indica qué estaciones están cerca de relevarla y si la línea alcanza el takt. La
   consulta inversa dice qué tendría que cambiar para que otra estación limite.
2. **Cascada.** Un paro produce la lista ordenada de estaciones bloqueadas hacia atrás y
   sin piezas hacia adelante, con el instante y el motivo de cada una. Si los buffers
   absorben el paro, la cascada se detiene y el gemelo dice dónde y por qué. El mismo
   paro en el cuello y fuera de él da efectos distintos en la salida. La hipótesis
   «¿y si el paro fuera en otra estación?» se contesta con las mismas reglas.
3. **Dilema.** Con dos paros y un solo técnico, el gemelo da el orden de atención, nombra
   a quién se le falla y cuánto cuesta, y explica por qué no el otro orden. La prioridad
   vive en un solo lugar: cambiarla ahí cambia los veredictos de todos los casos. La
   consulta inversa devuelve qué tendría que cambiar para invertir el orden. Si ningún
   plan es posible, lo dice con el motivo.
4. **Pieza a medias.** Cada pieza en duda recibe «está en tal lugar», «no está» o «no se
   sabe», y para las dudosas se indica qué conteo físico la resolvería. Un faltante y un
   sobrante que se compensan no se dan por buenos. Un conteo físico que llega tarde
   cambia los veredictos con las mismas reglas. Reanudar no pierde ni duplica piezas.
5. **Tiempo y modelo.** El tiempo esperado depende del modelo con que la pieza entró a la
   estación. La misma duración sale normal en una estación o modelo y anómala en otro; una
   estación que no se alargó cuando debía se marca. Un estado «procesando» contradicho por
   la salida da «no se sabe», nunca una conclusión firme. Una lectura fuera de rango no
   produce alertas ni paros.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar la línea completa como una
cadena de estaciones y buffers con su nivel, el estado de cada estación y la limitante
marcada, la cascada de un paro en orden, los paros pendientes con el orden de atención
propuesto y a quién se le falla, las piezas en duda con el conteo que las resolvería, y la
respuesta a «qué falta». Debe verse bien en celular.
