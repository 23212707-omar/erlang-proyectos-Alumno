# Contexto para agentes — gemelo digital del proyecto #80 (Cervecería artesanal)

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
| Receta | Define el estilo (ale o lager), el rango de temperatura y el tiempo de fermentación |
| Lote | Una producción de una receta; pasa por las etapas en orden y puede dividirse |
| Maceración | Etapa de molienda y agua caliente que extrae los azúcares de la malta |
| Cocción | Hervor del mosto con lúpulo |
| Fermentador | Tanque donde fermenta el lote; ocupado, no se puede usar para otro |
| Limpieza y sanitización | Pasos obligatorios, de horas, antes de reutilizar un fermentador |
| Densidad (OG, FG) | Original (antes de fermentar) y final; el alcohol se estima con ambas |
| Atorada | Fermentación que se detiene y deja el lote sin terminar |
| Trazabilidad | Qué insumos, con qué lote del proveedor, usó cada lote |

Cifras de referencia, todas del problema original: etapas en orden (molienda, maceración,
filtrado, cocción, enfriado, fermentación, maduración, carbonatación, embotellado o
barril); maceración ~65-68 °C por ~60 min; cocción 60-90 min con lúpulo; ales 18-22 °C
por 7-14 días y lagers 8-12 °C por 2-4 semanas; alcohol ≈ (OG − FG) × 131.25, con
OG 1.052 y FG 1.010 ≈ 5.5 %; la fermentación termina cuando la densidad se estabiliza
2-3 días; lotes de 200-2,000 L y 3-8 fermentadores; escenario de 5 recetas, 6
fermentadores y 12 lotes en un mes, con un fermentador que sube 5 °C en una noche.

Marcado como del ejercicio, no del original: la escala de 3 recetas, 3 fermentadores y
6 lotes, los 1,000 L por fermentador y los identificadores de los ejemplos (lote 3,
fermentador 2). El estudiante no debe presentarlos como datos reales.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Si hay jitter en las lecturas, entra como hecho o como supuesto, no se sortea.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Hora).                           % horas desde el inicio del mes simulado
rango(Variable, Minimo, Maximo).       % rango físico posible: temperatura, densidad
lectura(Equipo, Variable, Valor, Hora).        % Equipo: fermentador o macerador
receta(Receta, Estilo).                % Estilo: ale | lager
lote(Lote, Receta, Litros).            % una mitad de un lote dividido sigue siendo el lote
etapa(Lote, Etapa, HoraDesde).         % molienda | maceracion | filtrado | coccion | enfriado | fermentacion | maduracion | carbonatacion | envasado
fermentador(Fermentador, CapacidadLitros).
ocupa(Fermentador, Lote, Litros, HoraDesde).   % un lote dividido tiene un hecho por fermentador
reserva(Fermentador, Lote, HoraDesde).
estado_equipo(Fermentador, Estado, Hora).      % sucio | limpio | sanitizado
insumo(Lote, Insumo, LoteProveedor).   % Insumo: malta | lupulo | levadura
evento(Entidad, Evento, Detalle, Hora).        % lupulo, falla de frío, confirmación del maestro cervecero, vaciado, aviso del proveedor
```

## Contrato del gemelo

- `decide(+Lotes, -Decision, -Explicacion)` — predicado central. El primer argumento es
  la LISTA de lotes por atender (puede ser de uno). Con un lote, `Decision` incluye el
  siguiente paso válido (o la secuencia válida hasta la etapa pedida); con varios, además
  el reparto completo de fermentadores. Al pedir más soluciones debe dar las demás
  alternativas válidas. Si no existe ninguna (etapa previa incumplida, falta de
  fermentadores), lo dice y señala el motivo, sin fallar en silencio. `Explicacion` es
  una lista de hechos y condiciones que justifican la decisión.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo etapa
  cumplida, fermentación terminada o atorada, lote en riesgo, lote afectado por un
  insumo), consultables en cualquier dirección. La entidad puede ser un lote, un
  fermentador o un insumo.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de lotes y fermentadores, la decisión con su
  explicación, el reparto de fermentadores con sus alternativas, la trazabilidad de un
  lote o de un insumo y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Avanzar.** Un lote con sus etapas previas cumplidas recibe el siguiente paso válido;
   uno cuyo tiempo transcurrió pero cuya maceración salió del rango recibe una negativa
   con motivo, y uno con un hueco de lecturas recibe «no se sabe», distinto de «no».
   La consulta inversa dice qué falta. Una etapa no se salta.
2. **Terminó o se atoró.** La misma densidad quieta da «terminó», «atorada» o «sensor
   sospechoso» según el resto de los datos, y «no se sabe» cuando no alcanzan. Cumplir
   los días de la receta no basta, y distingue lo que indican los datos de lo que
   confirmó el maestro cervecero.
3. **Riesgo por temperatura.** El mismo aumento pone en riesgo a un lote y no a otro
   según su estilo y su contenido; un tanque vacío no genera riesgo, uno con sensor
   callado da «no se sabe». El tanque que llegó más alto no es necesariamente el más
   grave y la explicación dice por qué.
4. **Reparto.** Con un fermentador ocupado por un lote que no termina, el gemelo
   entrega un reparto válido con sus alternativas, divide el lote grande cuando es
   posible y no toma por disponible un tanque que figura libre pero sin sanitizar. Si no
   alcanza, dice qué lote cede y con qué regla; si no existe reparto, lo dice y señala
   el motivo.
5. **Insumo contaminado.** Un insumo señalado devuelve los lotes, las mitades y los
   fermentadores afectados, cada uno con la cadena que lo sustenta; lo que carece de
   registro queda como «no se sabe» y no como «no afectado». La consulta inversa lista
   los insumos de un lote. Distingue lo que se retira con certeza de lo que se retira
   por precaución.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar cada lote con su etapa, cada
fermentador con su temperatura, su contenido y su estado de limpieza, la decisión con su
explicación, el reparto de fermentadores con sus alternativas, la trazabilidad de un
insumo y la respuesta a «qué falta». Debe verse bien en celular: el maestro cervecero la
consulta de pie, junto a los tanques.
