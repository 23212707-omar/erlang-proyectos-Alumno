# Contexto para agentes — gemelo digital del proyecto #2 (Invernadero)

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
| Nave | Unidad de invernadero; tiene zonas y 4 actuadores compartidos; unidad sobre la que se decide |
| Zona | Parte de una nave con sus propios sensores; dos zonas de una nave pueden pedir cosas contrarias |
| Ventana cenital / lateral | Actuadores de ventilación; abrirlas ventila y enfría, pero tira el CO2 y puede dejar entrar humedad o plaga |
| Nebulización | Sube la humedad y baja la temperatura; aumenta el riesgo de hongos |
| Botrytis y cenicilla | Hongos que favorece la humedad arriba de ~90 % por varias horas |
| Enriquecimiento con CO2 | Subir a 800-1000 ppm de día; solo sirve con las ventanas cerradas |
| Modo seguro | Postura del controlador cuando no puede creer sus lecturas; qué hace cada actuador en él lo define el estudiante |
| Sensor «pegado» | Sensor que reporta siempre lo mismo; término de esta extensión, no del original |
| Manual / automático | Quién manda a un actuador: una persona o el controlador (del diseño OTP sugerido) |

Cifras de referencia: tomate óptimo de 21-26 °C de día y 13-16 °C de noche; arriba de
~32 °C aborto de flores; debajo de ~10 °C se detiene el crecimiento; humedad ideal
60-80 %; CO2 de ~420 ppm en la atmósfera y 800-1000 ppm enriquecido; sensor que
reporta cada 10-60 s; abrir y cerrar un actuador cada 10 s lo destruye; 4 naves de ~1 ha
con 6 sensores y 4 actuadores cada una (el gemelo trabaja a escala reducida: ver
«Supuestos» en `PROBLEMA.md`).

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas y fallas simuladas o graficar. Prolog nunca es una librería de
  Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundo).                        % segundos desde el inicio del escenario
zona(Zona, Nave).
sensor(Sensor, Zona).
actuador(Actuador, Nave, Tipo).        % Tipo: cenital | lateral | nebulizacion | calefaccion
rango(Variable, Minimo, Maximo).       % rango físico válido de la variable
lectura(Sensor, Variable, Valor, Segundo).
meta(Variable, Momento, Minimo, Maximo).   % Momento: dia | noche
periodo(Nave, Momento, Desde).         % Momento: dia | noche
evento(Sujeto, Evento, Segundo).       % Evento: orden(Accion) | manual | automatico |
                                       %   corte_energia | regreso_energia | viento_fuerte | viento_calma
limite(Nombre, Valor).                 % Nombre: cambio_minimo | silencio | humedad_alta_horas ...
```

El estado de un actuador no es un hecho; se deduce de sus eventos. Los valores de
`limite/2` los fija el estudiante. Si la simulación usa azar (fallas, ruido de sensores),
las reglas no sortean nada: el resultado entra como hecho.

## Contrato del gemelo

- `decide(+Nave, -Decision, -Explicacion)` — predicado central. `Decision` incluye lo que
  se ordena a cada actuador, el modo del controlador (entre ellos el seguro) y los
  siguientes pasos válidos; al pedir más soluciones debe dar las demás decisiones
  válidas. `Explicacion` es la lista de hechos, conclusiones y reglas que la justifican,
  con la meta que se sacrifica cuando dos chocan.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  sensor no creíble, actuador atorado, meta inalcanzable, causa de una falla),
  consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe. En
  particular: el sensor es creíble, no lo es, no se sabe; el actuador obedeció, no obedeció,
  no se sabe. Un valor estimado se marca como estimado y nombra los sensores que lo
  sustentan.
- La API expone al menos: el estado deducido de sensores y actuadores, la decisión con su
  explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Dos zonas, una ventana.** Con una zona fría y otra con humedad alta prolongada, la
   decisión nombra a la zona a la que se le falla y la prioridad que lo justifica. Si el
   estudiante cambia la prioridad, la decisión cambia sin tocar otra cosa. La consulta
   inversa devuelve qué tendría que cambiar para no fallarle a ninguna.
2. **El sensor que miente.** Con la mayoría de los sensores de la nave en calor y uno
   inmóvil en un valor cómodo, el inmóvil no se cree, aunque sea el único «dentro del
   rango óptimo», y la temperatura de la zona sale de los que sí se creen, marcada como
   estimada. El mismo valor inmóvil con ambiente estable no se condena. Una lectura fuera
   de rango y un sensor callado dan «no se sabe», nunca ventilar ni alertar por ellas.
   Si no queda lectura creíble, la nave entra a modo seguro y lo dice.
3. **El viento.** Con viento fuerte las ventanas laterales aparecen bloqueadas, y las
   metas que dejan de ser alcanzables (por ejemplo, enriquecer con CO2 si hay que abrir
   las cenitales por calor) se nombran con la cadena de causas. Al terminar el viento, lo
   que se reabre respeta el tiempo mínimo entre cambios.
4. **Actuador atorado.** Una orden sin efecto observable da «no obedeció» solo con
   evidencia suficiente y «no se sabe» si pudo no haber pasado tiempo o si hubo un corte
   de energía en medio. Nunca se ordena a un actuador cambiar antes de su tiempo mínimo
   ni operar junto a otro con el que choca, y un atorado se compensa con otros. Una
   historia de órdenes que no pudo ocurrir se rechaza señalando el primer paso que la rompe.
5. **Rendición de cuentas.** La causa de una temperatura peligrosa se reparte entre modo
   manual, sensor engañoso y actuador que no obedeció, con la evidencia de cada una; lo
   no demostrable aparece como «no se sabe», no como culpa. La pregunta hipotética
   («¿y si hubieran estado en automático?») se contesta con las mismas reglas
   cambiando un hecho.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar las naves con sus zonas, la
credibilidad de cada sensor (incluido «no se sabe»), el estado deducido de cada actuador,
el modo del controlador, la decisión con su explicación y la respuesta a «qué falta».
Debe verse bien en celular.
