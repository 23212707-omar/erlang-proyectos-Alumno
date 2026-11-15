# Contexto para agentes — gemelo digital del proyecto #28 (Puerto de Ensenada)

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
| Muelle | Posición de atraque; recurso exclusivo: un buque a la vez |
| Grúa de muelle | Mueve contenedores; se asigna a un buque, de una a tres por buque |
| Movimiento | Un contenedor movido por una grúa; unidad de avance de la operación |
| Fondeado | Buque que espera en la bahía porque no tiene muelle o ventana; cuesta dinero |
| Práctico y remolcadores | Recursos compartidos que todo atraque necesita |
| Ventana de marea y calado | Intervalo en que un muelle admite a un buque |
| Hora límite de zarpe | Marea que se cierra o abordaje de pasajeros que debe cumplirse |
| Margen | Diferencia entre la hora límite y la hora estimada de terminar; no la mide ningún dato |
| Crucero y carguero | Tipos de buque con prioridades y costos de espera distintos |
| Pila y altura | Posición de un contenedor en el patio; se apilan 3-5 alturas |
| Remoción | Mover contenedores de encima para sacar uno enterrado |
| Cascada de retraso | Efecto de una falla o retraso sobre los turnos que siguen |

Cifras de referencia, todas del problema original: 25-35 movimientos por hora por grúa;
1-3 grúas por buque; pilas de 3-5 alturas; un buque que llega 8 horas tarde; 3 muelles,
5 grúas, 12 buques y 2 cruceros en una semana; miles de dólares por hora en muelle. Los
tipos de muelle, las ventanas, los movimientos pendientes, las pilas y el tiempo de
reposicionar una grúa son inventados por esta extensión.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar llegadas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Los retrasos, las fallas y las reparaciones entran como hechos, no se sortean.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                          % minutos desde el inicio de la ventana de prueba
muelle(Muelle, Tipo).                   % Tipo: contenedores | cruceros | mixto (inventado)
grua(Grua).
buque(Buque, Tipo, Movimientos).        % Tipo: carguero | crucero; Movimientos: pendientes
limite_zarpe(Buque, Minuto).            % marea que se cierra o abordaje que se cumple
turno_programado(Buque, Muelle, Inicio, Fin). % plan previo, no decisión del gemelo
ventana(Recurso, Inicio, Fin).          % marea y calado de un muelle, práctico, remolcadores
destino(Contenedor, Buque).             % buque en que debe salir el contenedor
patio(Contenedor, Pila, Altura, Minuto). % registro de posición, con el instante del registro
rango(Variable, Minimo, Maximo).        % por ejemplo, grúas por buque, ritmo, alturas de pila
lectura(Entidad, Variable, Valor, Minuto). % estado de grúa y asignación, o reporte del patio
evento(Minuto, Tipo, Entidad, Detalle). % llega | atraca | zarpa | retraso | falla | repara | reporte
```

## Contrato del gemelo

- `decide(+Buques, -Plan, -Explicacion)` — predicado central. `Buques` es la lista de
  buques por atender (puede ser de uno); `Plan` da a cada uno su muelle, su turno y sus
  grúas, o «sin turno»; `Explicacion` justifica cada asignación y nombra a quién se le
  falla. Al pedir más soluciones debe dar los demás planes válidos. Si no existe ninguno,
  lo dice y señala el motivo (qué buque, qué recurso o ventana), sin fallar en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre un buque,
  un muelle, una grúa o un contenedor (por ejemplo buque en riesgo de perder su ventana,
  retraso en cascada, contenedor en duda), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de muelles, grúas, buques y patio, el plan con su
  explicación, y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Dos buques, un muelle.** Con turnos traslapados, ningún plan pone a dos buques en un
   muelle a la vez ni atraca sin práctico, remolcadores y ventana. La explicación nombra
   el criterio y a quién se le falla, y se obtienen todos los planes válidos. Si no hay
   ninguno, lo dice y señala el motivo. Un buque tarde mueve a los que dependen de él.
2. **Grúas.** El reparto respeta el mínimo y el máximo de grúas por buque. El margen sale
   de cruzar pendientes, grúas, ritmo y límite, y el buque con más pendientes no recibe
   grúas por ese solo hecho. Si no hay reparto que cumpla para todos, el gemelo dice qué
   buque queda mal y qué tendría que cambiar.
3. **Grúa averiada.** La falla produce la cascada completa con la razón de cada eslabón y
   no se queda en el primer buque. Sin estimado de reparación, el veredicto distingue
   «con reparación pronto», «sin ella» y «no se sabe». La hipótesis «la reparación tarda
   más» cambia el veredicto con las mismas reglas.
4. **Crucero o carguero.** Un carguero que cabe completo antes de que el crucero necesite
   el muelle se atiende primero, y la explicación lo dice. Si con un retraso deja de
   caber, manda el crucero y se nombra a quién se le falla y cuánto. La prioridad vive
   en un solo lugar: cambiarla ahí cambia los veredictos de todos los casos.
5. **Patio.** «No se sabe dónde está» es distinto de «no está» y de «está en el registro».
   Los registros viejos o en conflicto no se toman como ciertos. Para cada posición
   posible se cuentan las remociones, y el gemelo dice a qué buque se le quitan
   movimientos y qué inspección resolvería la duda.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar una línea de tiempo de los
tres muelles con los turnos y los buques fondeados, las grúas por buque (operativas y
averiadas), los buques en riesgo de perder su ventana y la cascada de una falla, el plan
propuesto con su explicación y a quién se le falla, las pilas del patio con la posición
dudosa de un contenedor, y la respuesta a «qué falta». Debe verse bien en celular.
