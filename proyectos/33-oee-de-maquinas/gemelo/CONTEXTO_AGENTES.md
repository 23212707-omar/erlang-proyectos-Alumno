# Contexto para agentes — gemelo digital del proyecto #33 (OEE de máquinas)

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
| OEE | Eficiencia General del Equipo: Disponibilidad × Rendimiento × Calidad |
| Disponibilidad | Tiempo produciendo / tiempo planeado |
| Rendimiento | Producción real / producción ideal a velocidad nominal |
| Calidad | Piezas buenas / piezas totales |
| Tiempo planeado | Tiempo en que se espera que la máquina produzca; lo define el estudiante |
| Clases de tiempo | Produciendo, paro planeado, paro no planeado, velocidad reducida |
| Seis grandes pérdidas | Fallas, cambios y ajustes, microparos, velocidad reducida, defectos de arranque, defectos en proceso |
| Microparo | Paro de menos de ~5 min; no se anota a mano |
| Señal | Estado digital de la máquina: en marcha, paro, alarma; tiene ruido |
| Contador | Piezas y rechazos acumulados; se reinicia (el de piezas llega cada segundo) |
| PLC | Controlador de la máquina; se consulta con OPC UA o Modbus |
| Turno | Periodo de trabajo; la planta tiene 3 |

Cifras de referencia (del original): ejemplo 90 % × 95 % × 99 % ≈ 84.6 %; OEE de clase
mundial ~85 %, promedio en muchas plantas cerca de 60 %; microparos menores a ~5 min;
ráfaga de microparos de 30 s durante 2 horas en una máquina; 10 máquinas y 3 turnos;
contador cada segundo. Marcado como de esta extensión: la escala de 4 máquinas y los
identificadores de los ejemplos.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  El ruido de la señal y los reinicios del contador entran como hechos, no se sortean.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundo).                          % segundos desde el inicio de la ventana del escenario
maquina(Maquina, VelocidadNominal).      % piezas por minuto; la define el estudiante
turno(Turno, Inicio, Fin).               % segundos; de ahí sale el tiempo planeado
calendario(Maquina, Tipo, Desde, Hasta). % Tipo: produccion | paro_planeado | relevo
rango(Variable, Minimo, Maximo).         % por ejemplo, el contador de piezas
lectura(Maquina, Variable, Valor, Segundo). % contador_piezas | contador_rechazos; Segundo es cuando se midió
evento(Segundo, Tipo, Maquina, Detalle). % marcha | paro | alarma_on | alarma_off | sin_reporte | cambio_turno
motivo(Maquina, Inicio, Causa, Capturado). % Capturado: segundo en que alguien lo anotó
gran_perdida(Causa, Perdida).            % relaciona una causa con una de las seis grandes pérdidas
```

## Contrato del gemelo

- `decide(+Maquina, -Decision, -Explicacion)` — predicado central. `Decision` dice qué
  clase de tiempo es cada tramo de la ventana de esa máquina, a qué turno se carga y qué
  se hace (por ejemplo, pedir el motivo, avisar a mantenimiento o no concluir);
  `Explicacion` es una lista de hechos y condiciones que lo justifican. El orden de «qué
  atacar primero» sale de consultar todas las máquinas, sin un predicado aparte.
- `situacion(?Maquina, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  paro sin clasificar, ráfaga de microparos, velocidad reducida, reinicio de contador,
  paro que cruza turno, máquina sin datos), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de las máquinas, la clase de cada tramo, la decisión
  con su explicación, el OEE por máquina y turno con lo dudoso marcado, y «qué falta
  para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Paro sin motivo.** Cada tramo de un paro recibe una clase con su evidencia
   (señal, alarma, calendario). Con el motivo vacío la clase sale como provisional o
   «sin clasificar», no como no planeada por omisión. Al llegar el motivo, la misma regla
   da otro veredicto. La consulta inversa dice qué dato la confirmaría.
2. **Ráfaga.** Varios paros cortos de la misma máquina en una misma ventana aparecen
   como un solo problema, con los paros que lo componen y el tiempo que suman. Un paro
   corto aislado no lo dispara. Una señal que nunca baja con el contador por debajo del
   ritmo nominal se clasifica como velocidad reducida, no como microparo.
3. **Contador.** Una bajada del contador con paro de por medio se trata como reinicio
   y se suman los tramos; sin evidencia que la apoye da «no se sabe». Un contador de
   rechazos mayor que el de piezas es dato imposible y no produce calidad. Un parpadeo de
   un instante de la señal no cuenta como paro.
4. **Cruce de turno.** El paro se reparte entre los turnos que cruza, el relevo
   planeado no cuenta, y la explicación nombra la regla de reparto y a quién se le
   falla. Si el motivo llega tarde, los OEE de ambos turnos y del día cambian con las
   mismas reglas. Dar el motivo antes o no darlo produce veredictos distintos y
   explicables.
5. **Faltante.** Una máquina sin señal pero con contador que avanza no se declara parada
   en ese tramo; una sin ningún dato da «no se sabe», no cero paros ni paro total. El
   orden de qué atacar dice si se sostiene para toda posibilidad sobre la máquina dudosa
   o si no se puede decidir. Una lectura fuera de rango no produce alertas ni paros.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar cada máquina con una línea
de tiempo de sus tramos coloreados por clase (incluidos «sin clasificar» y «no se sabe»),
la decisión con su explicación, el OEE por máquina y turno con las partes dudosas
marcadas, la ráfaga de microparos con los paros que la forman, el reparto de un paro
entre turnos, el orden de qué atacar primero y la respuesta a «qué falta». Debe verse
bien en celular.
