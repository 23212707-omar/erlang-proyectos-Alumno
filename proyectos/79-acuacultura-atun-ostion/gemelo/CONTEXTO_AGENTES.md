# Contexto para agentes — gemelo digital del proyecto #79 (Acuacultura: atún, ostión)

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
| Jaula | Estructura circular flotante donde se engorda el atún aleta azul; unidad sobre la que se decide alimentar y airear |
| Línea de ostión | Cultivo de ostión en la Bahía de San Quintín; unidad sobre la que se decide cosechar y vender |
| Boya | Plataforma con sensores (temperatura, oxígeno, salinidad, clorofila, corrientes); una boya puede representar a varias unidades y una unidad puede no tener boya propia |
| Oxígeno disuelto | mg/L; por debajo de ~3-5 mg/L hay estrés y mortalidad; cae de noche |
| Conversión alimenticia | Kilos de pescado de alimento por kilo ganado; muy alta, por eso alimentar mal pesa en el costo |
| Bioincrustación | Organismos que cubren el sensor; hace que derive sin dejar de reportar |
| Marea roja | Floración de algas tóxicas; obliga a suspender cosecha y venta del ostión |
| Clorofila | Lo que mide la boya como indicio de algas; no es lo mismo que toxina |
| Aireación | Medida costosa para subir el oxígeno de una jaula |

Cifras de referencia (todas del problema original): oxígeno crítico ~3-5 mg/L; caída
nocturna a 3.5 mg/L en dos jaulas; temperatura óptima del atún ~16-20 °C; ostión a talla
comercial en ~12-18 meses; lecturas cada 5 min. Las 8 jaulas, 20 líneas y 6 boyas son del
escenario original; la escala reducida de `PROBLEMA.md` (3, 3 y 3) y los identificadores
de los ejemplos son del ejercicio, no hechos del mundo.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                          % minutos desde el inicio del turno de observación
rango(Variable, Minimo, Maximo).        % rango físico posible de cada variable
lectura(Boya, Variable, Valor, Minuto). % lo que reportó una boya y cuándo
evento(Sujeto, Tipo, Detalle, Minuto).  % limpieza, aireación, alimentación, cosecha, silencio
jaula(Jaula, Lote, Ingreso).            % jaula de atún con su lote y fecha de ingreso
linea_ostion(Linea, Lote, Ingreso).     % línea de ostión con su lote y fecha de ingreso
biomasa(Jaula, Kilos).                  % biomasa estimada de una jaula
plan_alimentacion(Jaula, Racion, Franja). % lo planeado, no lo suministrado
cubre(Boya, Unidad, Representatividad). % qué boya habla por qué unidad, y qué tan bien
noche(Inicio, Fin).                     % franja de la noche en minutos del turno
```

El azar no entra en las reglas: si el estudiante quiere ruido en las lecturas, el valor
entra ya como hecho (o lo genera Janus fuera de las reglas).

## Contrato del gemelo

- `decide(+Entidad, -Decision, -Explicacion)` — predicado central. La entidad es una
  jaula o una línea; `Decision` es airear, alimentar (con su ración), esperar,
  suspender cosecha o equivalentes; `Explicacion` es una lista de hechos y condiciones
  que justifican la decisión, incluida la regla que bloqueó otras opciones.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  oxígeno en riesgo, sensor poco creíble, línea alcanzada por la marea), consultables en
  cualquier dirección. La evidencia distingue lectura de inferencia.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de jaulas y líneas, la decisión con su explicación
  y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Oxígeno nocturno.** Dos jaulas con la misma lectura baja reciben decisiones
   distintas cuando difieren en tendencia, temperatura o movimiento del agua, y la franja
   de la noche cambia el resultado. Una jaula con una lectura menos mala puede
   quedar en peor situación que otra con 3.5 mg/L. La explicación muestra la cadena.
2. **Sensor sucio.** Un sensor que reporta a tiempo y dentro de rango pero contradicho
   por las otras boyas y sin limpieza reciente es «dudoso», no «falla» ni «bien». Sus
   lecturas dudosas no encienden ni apagan la aireación por sí solas.
3. **Boya callada.** La jaula sin boya confiable recibe una inferencia marcada como tal,
   con las boyas que la sustentan; sin ninguna boya representativa la respuesta es «no se
   sabe». Una boya más cercana puede ser peor testigo que otra más lejana.
4. **Alimentar.** Con la causa del bajo consumo sin sustento, el gemelo no concluye
   «apetito» ni «medición»; elige una ración justificada, dice qué parte (costo o
   engorda) se sacrifica y qué dato permitiría decidir mejor. La consulta inversa
   devuelve ese dato.
5. **Marea roja.** Una línea cuya propia boya está tranquila puede aparecer en riesgo si
   el agua que le llega viene de otra boya con clorofila alta; la clorofila alta sola no
   se presenta como marea roja confirmada. Las líneas en talla se separan de las que no, y
   los lotes ya salidos aparecen para rastrear. La hipótesis de corriente invertida
   cambia el resultado.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el estado de cada jaula y
línea, qué boya la representa y qué tan creíble es su dato, la decisión, la explicación
(distinguiendo lectura de inferencia) y la respuesta a «qué falta». Debe verse bien en
celular y legible de noche (poca luz), con colores de estado.
