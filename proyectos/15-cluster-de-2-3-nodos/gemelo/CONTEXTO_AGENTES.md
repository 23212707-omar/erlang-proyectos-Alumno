# Contexto para agentes — gemelo digital del proyecto #15 (Cluster de 2-3 nodos)

Este archivo es para el agente (OpenCode u otro) que acompaña al estudiante. Léelo
completo, junto con [`PROBLEMA.md`](PROBLEMA.md) y
[`../problema/readme.md`](../problema/readme.md), antes de proponer cualquier cosa.

## Tu papel

- El proyecto es individual y se califica el razonamiento del estudiante. **Explica,
  pregunta y propone; no entregues la solución completa.**
- Antes de escribir una regla, pide al estudiante que la diga en español.
- Primero la prueba plunit, después la regla.
- Trabaja una situación a la vez, en el orden de `PROBLEMA.md`.
- No inventes cifras. Las reales vienen del problema original; el hospital y su
  reglamento son un escenario inventado por esta extensión y el estudiante fija sus
  números como supuestos. Cualquier otra cifra se marca como supuesto y se le pide la
  fuente.

## Dominio

| Término | Significado |
|---|---|
| Nodo | Máquina del clúster: Sótano, Torre o Mexicali (escenario inventado) |
| Latido | Señal periódica con la que un nodo comprueba que otro sigue vivo |
| Partición | La red se parte y cada lado sigue vivo creyéndose el único (*split brain*) |
| Mayoría (quórum) | Con 2 nodos no hay mayoría posible; con 3 se tolera la caída de 1 |
| Líder | Nodo que manda sobre un dato; su legitimidad se deduce, no se declara |
| Consistencia / disponibilidad | Rechazar escrituras en la minoría, o aceptarlas y reconciliar después |
| Reconciliar | Combinar lo escrito en lados distintos al sanar la red |
| Convenio | Contrato de confidencialidad con el hospedaje de Mexicali; tiene vigencia (inventado) |
| Controlado | Medicamento de entrega registrada; la farmacéutica responde por cada una (inventado) |

Cifras reales de referencia (todas del problema original): latidos por omisión cada ~60 s
(`net_ticktime`), por lo que detectar una caída puede tardar decenas de segundos; mayoría
de 2 entre 3 nodos; latencia menor a 1 ms en red local y de 50 a 200 ms con pérdidas
entre ciudades; un nodo con reloj adelantado 5 s. **Inventado y marcado como tal:** el
hospital, las personas, el convenio, capacidades, tamaños, copias mínimas y el reglamento
(a)-(g) de `PROBLEMA.md`.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar latidos y escrituras simulados o graficar. Prolog nunca es una librería de
  Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Las fallas, los retardos y el desfase de los relojes entran como hechos, no se sortean.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundo).                         % instante del modelo, en segundos
nodo(Nodo, Sitio).                      % Sitio: campus | fuera_campus
enlace(Nodo1, Nodo2, Medio).            % Medio: fibra | internet
capacidad(Nodo, Unidades).
dato(Dato, Tamano, CopiasMinimas).
copia(Dato, Nodo, Version).             % dónde está cada copia y qué versión guarda
convenio(Nodo, VenceSegundo).           % vigencia de confidencialidad
latido(Observador, Observado, Segundo). % último latido recibido por el observador
rango(Variable, Minimo, Maximo).        % rango físico: latencia, desfase de reloj, batería
lectura(Nodo, Variable, Valor, Segundo).
evento(Nodo, Tipo, Detalle, Segundo).   % corte, regreso, escritura, entrega, cambio de líder
```

## Contrato del gemelo

- `decide(+Solicitudes, -Decision, -Explicacion)` — predicado central. El primer argumento
  es la LISTA de solicitudes (puede ser de una): datos por colocar, escrituras por
  confirmar, registros que regresan. `Decision` es el reparto, el plan o la lista de
  veredictos completo, y `Explicacion` la lista de hechos y condiciones que lo justifican.
  Al pedir más soluciones debe dar las demás alternativas válidas. Si no existe ninguna
  (recursos insuficientes, convenio vencido) lo dice y señala el motivo; no falla en
  silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (nodo aislado,
  grupo con mayoría, copia ilegal, escritura obsoleta), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de nodos, enlaces y copias, la decisión con su
  explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Reparto.** Dado el escenario, el gemelo da repartos que cumplen capacidad, copias
   mínimas, copia fuera del campus y convenio vigente. Al vencer el convenio señala que
   la copia fuera del campus del expediente deja de ser posible, nombra el nodo y la regla,
   y dice qué tendría que cambiar. Nunca devuelve «fallo» sin motivo.
2. **Muerto o lento.** Si un nodo no es visto por uno pero sí por otro, no se declara
   caído: se concluye que falla el enlace entre ellos. Con un solo testigo y poca
   evidencia, la respuesta es «no se sabe», y dice qué observación la resolvería. Nunca
   se nombra un segundo responsable de los controlados mientras haya duda.
3. **Partición.** El Sótano, sano, con el dato más reciente y antes líder, queda en la
   minoría y no confirma controlados ni expediente; sí puede registrar camas como
   provisionales. La explicación nombra el grupo con mayoría y la regla que perdió urgencias.
   La consulta inversa devuelve qué tendría que cambiar.
4. **Regreso.** Un nodo que regresa no manda ni responde consultas críticas hasta ponerse
   al corriente. Sus escrituras reciben veredicto individual; las que se apoyaron en un
   expediente vencido llevan aviso y señalan a la persona que debe decidir.
5. **Entrega doble.** Con dos entregas y relojes que difieren, el gemelo contesta «sí»,
   «no» o «no se sabe», distingue una copia replicada de una entrega nueva y dice qué
   dato faltante resolvería la duda. No ordena hechos cuya diferencia cabe en el desfase.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar los tres nodos y sus
enlaces con colores de estado (bien, dudoso, caído), el reparto de las copias, la
decisión con su explicación y la respuesta a «qué falta». Debe verse bien en celular.
