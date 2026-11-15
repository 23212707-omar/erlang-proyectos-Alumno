# Contexto para agentes — gemelo digital del proyecto #51 (Tablero de avisos)

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
  se marca como supuesto y se le pide al estudiante la fuente. Los nombres, grupos y
  políticas de los ejemplos son del ejercicio, no del mundo.

## Dominio

| Término | Significado |
|---|---|
| Aviso | Mensaje de una persona o área a una audiencia; tiene tipo, prioridad y destino |
| Destino | A quién se dirige: todos, una carrera, un semestre de una carrera o un grupo |
| Audiencia | Quienes de verdad lo reciben; se deduce del destino y de la pertenencia, no se guarda |
| Grupo | Conjunto de alumnos de una materia (~35); un alumno puede estar en varios |
| Prioridad | Urgente (suspensión por clima o contingencia) o informativo (puede agruparse) |
| Resumen | Entrega agrupada de avisos informativos, en lugar de uno por uno |
| Preferencia | Lo que un nivel (campus, carrera, grupo o alumno) dispone sobre cómo se entregan |
| Herencia | Un nivel recibe las reglas del nivel superior y puede modificarlas o no |
| Vigente | Aviso que sigue valiendo hoy; no es lo mismo que «publicado» |
| Sustituir / retirar | Una corrección reemplaza a un aviso; un retiro lo da de baja |
| Acuse | Mensaje del dispositivo: entregado, visto o leído, con el instante que él reporta |

Cifras de referencia (del original): 3,000 alumnos, 12 carreras, 120 grupos, 40 avisos
por día, ~35 alumnos por grupo, aviso urgente en segundos, ausencia de una semana.
Marcados como del ejercicio, sin cifras: los grupos con alumnos de otra carrera, los
avisos que se sustituyen y las políticas por nivel.

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
ahora(Segundo).                          % instante del gemelo, en segundos desde el inicio
carrera(Carrera).
grupo(Grupo, Carrera, Semestre).
alumno(Alumno, Carrera, Semestre).
alta_grupo(Alumno, Grupo, Segundo).      % el alumno entra al grupo en ese instante
baja_grupo(Alumno, Grupo, Segundo).
emisor(Emisor, Rol, Ambito).             % Rol: direccion | coordinacion | docente
aviso(Aviso, Emisor, Tipo, Prioridad, Destino).  % Destino: todos | carrera(C) | semestre(C,S) | grupo(G)
evento_aviso(Aviso, Evento, Segundo).    % programado(Para) | publicado | sustituye(Otro) | retirado | vencido
preferencia(Nivel, Quien, Tipo, Valor).  % Nivel: campus | carrera | grupo | alumno
conexion(Alumno, Estado, Segundo).       % abierta | cerrada
acuse(Alumno, Aviso, Clase, Segundo).    % Clase: entregado | visto | leido; Segundo lo reporta el dispositivo
```

## Contrato del gemelo

- `decide(+Entidad, -Decision, -Explicacion)` — predicado central. La entidad es una
  entrega, es decir, un alumno frente a un aviso (por ejemplo `entrega(Alumno, Aviso)`);
  el estudiante elige cómo representarla. `Decision` dice cómo se entrega (de inmediato,
  en resumen, solo al abrir) o por qué no corresponde (no es destinatario, está retirado,
  está vencido). `Explicacion` es una lista de hechos, reglas y niveles que la justifican.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (destinatario,
  vigente, se enteró, silenciado, regla heredada), consultables en cualquier dirección:
  dado un aviso, la audiencia; dado un alumno, sus avisos.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: la audiencia de un aviso, la decisión de una entrega con su
  explicación, lo que ve un alumno al abrir, quién se enteró (sí, no, no se sabe) y
  «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Audiencia.** Un aviso a carrera, semestre, grupo o todos llega solo a quien
   corresponde, y la evidencia dice por qué camino. Quien pertenece a dos grupos de la
   audiencia aparece una vez, con ambos caminos. Un alumno en un grupo de otra carrera no
   se trata como de esa carrera. La consulta funciona por aviso y por alumno.
2. **Silencio y urgencia.** La decisión nombra la preferencia o regla que cedió y a quién
   se le falla. Cambiar quién puede declarar urgencia cambia el veredicto sin tocar otras
   reglas, y la consulta inversa dice qué tendría que cambiar.
3. **Vigencia.** En el escenario del examen, ningún aviso sobre él queda vigente tras la
   sustitución y el retiro; el recordatorio programado no procede; quien leyó alguno
   queda señalado. El alumno que vuelve tras una semana ve lo vigente y lo retirado que
   le atañe, y no ve lo ya vencido.
4. **Dato dudoso.** «Entregado» no cuenta como «leído». Un acuse con instante anterior a
   la publicación se marca imposible y no cuenta. Ausencia de acuse da «no se sabe», no
   «no». La lista de a quién llamar separa los «no» de los «no se sabe».
5. **Herencia.** Cada decisión nombra el nivel que fijó la regla. Un cambio de política
   de una carrera afecta solo a quienes la heredan, y la consulta hipotética lo muestra
   sin alterar los hechos.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar un aviso con su audiencia y
el porqué de cada destinatario, la vista de un alumno al abrir (lo vigente y lo retirado
que le atañe), el estado de entrega con sus tres respuestas y la política heredada con
el nivel que la fijó. Debe verse bien en celular.
