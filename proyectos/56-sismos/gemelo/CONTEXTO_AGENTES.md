# Contexto para agentes — gemelo digital del proyecto #56 (Sismos)

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
  se marca como supuesto y se le pide al estudiante la fuente. Las fuentes, ubicaciones,
  niveles y sismos de los ejemplos son del ejercicio, no del mundo.

## Dominio

| Término | Significado |
|---|---|
| Reporte | Lo que una fuente cuenta de un sismo en un momento; trae una revisión |
| Sismo | La identidad que el gemelo deduce a partir de varios reportes |
| Revisión | Corrección posterior de un reporte; la magnitud inicial puede cambiar 0.3 o más |
| Fuente | Red o feed que reporta (por ejemplo, un feed GeoJSON como el del USGS) |
| Magnitud | Escala logarítmica de energía; cada punto son ~32 veces más energía |
| Intensidad | Efecto en un lugar (Mercalli); depende de la distancia y del suelo |
| Profundidad | A qué hondura se originó el sismo; complemento de esta extensión |
| Ondas P y S | P a ~6 km/s; S, las destructivas, a ~3.5 km/s |
| Ventana de alerta | Diferencia entre la llegada de P y de S; ~13 s a 100 km |
| Réplica | Sismo menor posterior, relacionado con uno principal |
| Enjambre | Grupo de sismos pequeños sin un principal que los explique |
| Ubicación de interés | Lugar donde importa el efecto (hospital, escuela, puerto) |
| Aviso | Mensaje de un cierto nivel enviado a una ubicación |

Cifras de referencia (del original): ondas P a ~6 km/s y S a ~3.5 km/s; ~13 s entre
ellas a 100 km; feeds actualizados cada minuto; cada punto de magnitud ~32 veces más
energía; revisión de 0.3 o más; un M4 a 20 km se siente y a 800 km no; 50 eventos por
hora; M6.5 cercano con 3 revisiones en 10 minutos; El Mayor-Cucapah, Mw 7.2, 4 de abril
de 2010. Marcados como del ejercicio, sin cifras: 3 fuentes, 4 ubicaciones, coordenadas,
suelos, tipo de ubicación, niveles de alerta y profundidades.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar reportes simulados o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Si la simulación necesita azar (un retraso de fuente, un reporte fuera de orden), el
  valor entra como hecho; las reglas no sortean nada.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundo).                         % instante del gemelo, en segundos desde un origen fijo
fuente(Fuente).                         % red o feed que reporta
reporte(Id, Fuente, Revision, Llegada). % Llegada = segundo en que llegó al gemelo
origen(Id, Segundo, Latitud, Longitud). % hora y lugar de origen según ese reporte
medida(Id, Magnitud, Profundidad).      % si el reporte no trae profundidad, no hay hecho
ubicacion(Lugar, Latitud, Longitud, Suelo). % ubicación de interés
tipo_ubicacion(Lugar, Tipo).            % hospital | escuela | puerto | oficina
rango(Variable, Minimo, Maximo).        % rango físico: magnitud, profundidad
velocidad_onda(Onda, KmPorSegundo).     % Onda: p | s
aviso(Sismo, Lugar, Nivel, Segundo).    % aviso ya enviado, con su instante
suceso(Fuente, Suceso, Segundo).        % Suceso: cae | vuelve
```

## Contrato del gemelo

- `decide(+Entidad, -Decision, -Explicacion)` — predicado central. La entidad es un
  reporte (¿a qué sismo pertenece?), un sismo o un par sismo-ubicación; el estudiante
  elige cómo representarla. Para un par sismo-ubicación, `Decision` es qué aviso
  corresponde (nada, temprano, informativo, aclarar, escalar, rectificar) o por qué no
  se sabe; para un reporte, a qué sismo se asocia o por qué no se puede decidir. En el
  eje experto la entidad es una sola, no una lista. `Explicacion` es una lista de
  hechos, reportes, reglas y evidencias que la justifican.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (mismo sismo,
  réplica, enjambre, revisión vigente, reporte atrasado, fuente en silencio, efecto
  probable), consultables en cualquier dirección: dada una ubicación, sus situaciones;
  dada una situación, quiénes la cumplen.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- Toda inferencia (por ejemplo, el efecto probable sin profundidad) se marca como
  inferencia y cita los reportes que la sustentan; nunca se presenta como un dato.
- La API expone al menos: los sismos con sus reportes, el estado de las fuentes, la
  decisión por ubicación con su explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Identidad.** Dos reportes de fuentes distintas con datos algo diferentes se
   reconocen como un solo sismo y la explicación dice en qué coinciden y en qué
   discrepan. Dos reportes casi idénticos separados por una réplica quedan como dos
   sismos. Si la evidencia no decide, la respuesta es «no lo sé» y no se avisa doble.
2. **Revisión.** Una revisión que no cambia el nivel en una ubicación no provoca aviso
   nuevo ahí, y la misma revisión sí lo provoca en otra donde cruza un nivel. Una
   revisión que llega tarde de una fuente atrasada no desplaza a una más vigente. La
   respuesta dice a quién se le falla con esa política.
3. **Efecto.** Un sismo menor, cercano y somero puede pesar más en una ubicación que
   uno mayor y lejano, y la explicación cita distancia, profundidad y suelo. Sin
   profundidad, la respuesta es «no lo sé» y dice qué faltaría. Un aviso que llegaría
   después de las ondas S se marca informativo, no temprano.
4. **Fuente caída.** Con una fuente caída, «sin sismos» da «no lo sé», distinto de «no
   hay sismo». Un reporte atrasado de un sismo ya conocido no produce aviso nuevo, y
   el de uno desconocido se trata como información para la respuesta.
5. **Réplicas.** Tras un sismo principal, las réplicas se agrupan y se resumen; la que
   produce un efecto relevante en alguna ubicación sale con aviso propio y la
   explicación nombra por qué rompió la regla general. Un enjambre sin principal se
   distingue de las réplicas.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar la lista de sismos con
los reportes que los componen, el estado de las fuentes, el aviso por ubicación con su
explicación y la respuesta a «qué falta». Debe distinguir a la vista lo reportado de lo
inferido y verse bien en celular.
