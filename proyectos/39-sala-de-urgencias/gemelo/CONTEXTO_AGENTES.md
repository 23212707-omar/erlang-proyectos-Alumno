# Contexto para agentes — gemelo digital del proyecto #39 (Sala de urgencias)

Este archivo es para el agente (OpenCode u otro) que acompaña al estudiante. Léelo
completo, junto con [`PROBLEMA.md`](PROBLEMA.md) y
[`../problema/readme.md`](../problema/readme.md), antes de proponer cualquier cosa.
Es una simulación educativa de gestión de colas, no un dispositivo médico: no ofrezcas
criterios clínicos como si fueran válidos.

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
| Triage | Clasificación rápida que decide quién se atiende primero |
| Nivel | Rojo, naranja, amarillo, verde o azul (escala Manchester); el ESI usa 5 niveles |
| Límite de espera | Tiempo máximo para llegar al médico según el nivel |
| Retriage | Repetición periódica del triage; puede subir el nivel de un paciente |
| Puerta-a-médico | Tiempo entre la llegada y el primer contacto con un médico |
| Inanición | Un paciente de nivel bajo que nunca pasa |
| Desbordamiento | No hay camillas libres para quien llega |
| Ingreso pendiente | Atendido en urgencias, espera una cama del hospital y ocupa su camilla |

Cifras de referencia (todas del original): rojo inmediato, naranja hasta 10 min, amarillo
hasta 60, verde hasta 120, azul hasta 240; 5 médicos; 12 camillas; accidente con 8 heridos;
verde que empeora a rojo tras 90 minutos; 100 llegadas en 12 horas. Marcado como inventado
por esta extensión: los pacientes 14 y 17, el hospital general de Tijuana y los ~20
pacientes en pantalla.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar llegadas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Las llegadas y las tomas de signos entran como hechos, no se sortean.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                         % minutos desde la apertura del turno
llegada(Paciente, Minuto).
nivel_triage(Paciente, Nivel, Minuto). % rojo|naranja|amarillo|verde|azul; cada triage es un hecho
limite_espera(Nivel, Minutos).         % del original; el rojo es inmediato
rango(Signo, Minimo, Maximo).          % valores posibles de un signo
lectura(Paciente, Signo, Valor, Minuto).
medico(Medico).
camilla(Camilla).
evento(Paciente, Tipo, Detalle, Minuto). % inicio/fin de atencion, alta, ingreso_pendiente
cama_hospital(Cama, Estado, Minuto).   % lo que dice el sistema del hospital
```

## Contrato del gemelo

- `decide(+Entidad, -Decision, -Explicacion)` — predicado central. `Entidad` es un
  paciente, o la **lista** de pacientes a repartir (accidente, camillas, el médico que se
  libera). Con lista, `Decision` es el reparto completo de médicos y camillas; al pedir
  más soluciones, da las demás alternativas válidas; y si no existe ninguno que cumpla
  los límites, lo dice y señala el motivo, sin fallar en silencio. `Explicacion` es una
  lista de hechos y condiciones que justifican la decisión.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  empeoramiento, camilla ocupada de facto, sala saturada), consultables en cualquier
  dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de la sala, la decisión con su explicación y «qué
  tendría que cambiar» para que otro paciente pase antes.

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Ocho heridos.** El reparto cubre a quienes alcanzan dentro de su límite y nombra a
   quien no, con el motivo. Con recursos suficientes el gemelo reparte a todos; sin ellos
   no falla en silencio. Camillas libres no implican médicos libres.
2. **Verde que empeora.** Un cambio de signos entre tomas sube el nivel y el límite que
   se aplica es el del nivel nuevo. Un paciente sin tomas recientes da «no se sabe», no
   «estable», y la explicación pide la toma que falta.
3. **Inanición.** Con gravedad y espera en conflicto, el gemelo ordena, nombra a quién se
   le falla y la regla que decidió. Ni el nivel más grave pasa siempre ni un paciente
   queda sin pasar indefinidamente. La consulta inversa devuelve qué tendría que cambiar.
4. **Camilla fantasma.** Una camilla que urgencias da por libre pero cuyo paciente espera
   cama aparece ocupada, con la explicación. Si los registros se contradicen sin forma
   de saber cuál es cierto, la respuesta es «no se sabe». El rojo recibe un lugar o la
   explicación de por qué no hay.
5. **Saturación.** La sala puede estar saturada con camillas libres y no estarlo con
   todas ocupadas. La respuesta trae el primer momento de alerta y la evidencia. Cada
   incumplimiento de límite queda como inevitable o evitable, con su causa. La hipótesis
   de 8 heridos se contesta sin modificar los hechos reales.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el tablero de la sala
(pacientes por nivel con su espera y su límite, médicos y camillas), la decisión con su
explicación, las camillas libres de verdad contra las que marca el tablero, y la
respuesta a «qué tendría que cambiar». Debe verse bien en celular.
