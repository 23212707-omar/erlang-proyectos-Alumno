# Contexto para agentes — gemelo digital del proyecto #38 (Andon digital)

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
| Andon | Botón o cordón con que un operador pide ayuda, incluso deteniendo la línea |
| Llamada | Una petición de ayuda de una estación; tiene una historia de eventos |
| Escalamiento | Subir la llamada al siguiente nivel si el tiempo de respuesta se vence |
| Escalera | Líder de grupo, supervisor, gerente de área, gerente de planta |
| Acuse | Constancia de que una persona recibió el aviso |
| Tiempo de respuesta / de solución | Hasta que alguien atiende / hasta que se resuelve |
| Traspaso | Entrega de una llamada abierta al turno que entra |
| Llamada falsa | Llamada sin problema real; muchas hacen que la gente deje de atender |
| Colores | Verde normal, amarillo ayuda, rojo línea detenida, azul material, blanco calidad |

Cifras de referencia, todas del original: respuesta objetivo de 1 a 2 minutos para el
líder y de 5 a 10 para el supervisor; una llamada sin atender durante 6 minutos; ocho
llamadas simultáneas; 40 estaciones y 3 líderes; línea detenida de cientos o miles de
dólares por minuto. Inventado por la extensión (no es del original): la planta, sus
nombres, las 8 estaciones, los 2 líderes por turno y el gerente de planta del ejemplo.
Los tiempos de los niveles altos y de las llamadas falsas los fija el estudiante.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar eventos simulados o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                          % minutos desde el inicio del escenario
estacion(Estacion, Linea).
persona(Persona, Nivel, Area).          % Nivel: lider | supervisor | gerente_area |
                                        %        gerente_planta
turno(Persona, Desde, Hasta).           % minutos en que la persona está de turno
llamada(Llamada, Estacion, Tipo, Minuto).  % Tipo: ayuda | paro | material | calidad;
                                           % Minuto: cuando se pulsó
evento(Fuente, Sujeto, Evento, Minuto). % Fuente: tablero | persona | captura | sistema
                                        % Sujeto: una llamada, una persona o el sistema
tablero(Estacion, Color, Minuto).       % lo que muestra la estación, con su instante
falsa(Estacion, Llamada).               % llamadas ya clasificadas como falsas
```

`Evento` puede ser avisado, acusado, en_sitio, resuelto, cancelado, escalado,
entra_turno, sale_turno, caido o levantado. La etapa de una llamada, su nivel actual y
si alguien la tiene a su cargo **no son hechos**: se deducen de los eventos. Los
tiempos objetivo por nivel, qué cuenta como traspaso y quién puede cancelar son
predicados que añade el estudiante con sus supuestos.

## Contrato del gemelo

- `decide(+Llamada, -Decision, -Explicacion)` — predicado central. La entidad es una
  sola llamada. `Decision` incluye el siguiente paso válido (avisar, esperar, escalar,
  reasignar, cerrar o rechazar un cierre o cancelación) y la secuencia de pasos posibles
  que sigue; al pedir más soluciones da las demás alternativas válidas, y si no existe
  ninguna lo dice y señala el evento que lo impide, sin fallar en silencio.
  `Explicacion` es una lista de hechos, condiciones y reglas que justifican la decisión,
  incluida la regla que perdió cuando hubo conflicto.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  etapa de una llamada, llamada sin responsable, cancelación procedente, historia
  imposible, aviso pendiente por el hueco), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado deducido de llamadas y personas, la decisión con
  su explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Escalera.** Con la historia de una llamada de paro de seis minutos sin respuesta,
   el gemelo da su etapa, su nivel y su responsable; los avisos que ya tuvieron que
   salir aparecen aunque nadie los haya registrado, y un cierre sin atención previa se
   rechaza con la razón. Mover un solo minuto del «ahora» cambia el nivel. El
   resultado depende del turno de quien debía recibir el aviso.
2. **Dilema.** Con un solo líder libre, una llamada de paro de línea reciente y una
   de calidad más antigua de una estación con muchas falsas: no gana la más antigua por
   serlo; la explicación nombra las dos reglas en choque, cuál prevalece, a quién se le
   falla y qué tendría que cambiar para que el veredicto fuera el contrario. La llamada
   desplazada no se descarta: sigue su escalera.
3. **Cancelación.** Una cancelación registrada antes del escalamiento lo deja sin
   efecto; una posterior no borra el aviso ya emitido. Dos eventos en el mismo minuto
   sin orden dan «no se sabe», distinto de «improcedente». Quien no puede cancelar no
   logra cerrarla, y la explicación señala a quién se le carga la falta.
4. **Turno.** Una llamada «atendida» por quien ya salió de turno, sin traspaso,
   aparece sin responsable aunque el tablero la muestre atendida; la evidencia lista
   las tres cosas encadenadas y los pasos válidos que siguen. Con traspaso registrado,
   la misma llamada sí tiene responsable.
5. **Hueco sin registro.** Para las llamadas abiertas durante un hueco de eventos, el gemelo da
   el nivel alcanzado por el tiempo corrido y el aviso que corresponde hoy, y marca
   como «no se sabe» si hubo acuse en el hueco; nunca lo da por hecho ni por
   inexistente. La hipótesis sobre una atención durante el hueco cambia el veredicto.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el tablero de estaciones
con su color y el estado deducido de cada llamada (distinto del color), la escalera con
quién está de turno y ocupado, la historia de eventos de la llamada elegida, la decisión
con su explicación y la respuesta a «qué falta» y a las hipótesis. Debe marcar con
claridad lo que «no se sabe». Debe verse bien en celular.
