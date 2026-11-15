# Contexto para agentes — gemelo digital del proyecto #36 (Mantenimiento predictivo)

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
| RMS, pico, curtosis | Resúmenes de la señal de vibración que se envían en lugar de la señal completa |
| FFT / espectro | Descomposición por frecuencias; el defecto de un rodamiento aparece en frecuencias características |
| Banda del defecto | Rango de frecuencias donde se espera la huella del defecto del rodamiento |
| ISO 10816/20816 | Clasifica la severidad por velocidad RMS (mm/s) en zonas A (bueno) a D (peligro), según el tipo de máquina |
| Línea base | Comportamiento normal de esa máquina; se compara contra ella, no solo contra un umbral fijo |
| Régimen | Condición de carga y velocidad; cambiarlo mueve la línea base |
| Regla de Montsinger | Cada 10 °C sobre la temperatura nominal reduce a la mitad la vida del aislamiento de un motor |
| Niveles de alerta | normal, vigilancia, alarma, paro |
| Sensor pegado | Repite un valor fijo; sensor desconectado: deja de reportar |
| Respaldo | Máquina que cubre a otra si esta falla; sin respaldo, su falla detiene la línea |
| Anticipo | Tiempo que mantenimiento necesita para planear una intervención |

Cifras de referencia (del original): zonas ISO A a D y 4.5-7 mm/s como alerta en máquinas
medianas; regla de Montsinger de 10 °C; vibración de un rodamiento que crece 2 % por día
durante 3 semanas; 20 máquinas; muestreo de 5 a 50 kHz; costos de paro no planeado de
miles de dólares por minuto en automotriz. Marcado como de esta extensión: la escala de
5 máquinas en 2 líneas, la planta de autopartes, el montacargas, el controlador de línea,
los eventos de paro, la refacción y la ventana únicas, los regímenes y los números de los
ejemplos. El original no da cuántas lecturas hacen una tendencia ni un sensor pegado, ni
el anticipo que necesita mantenimiento: son decisiones del estudiante.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  El ruido de las lecturas y los fallos de sensor entran como hechos, no se sortean.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Hora).                           % unidad: hora
maquina(Maquina, Linea, Tipo).         % Tipo: pequena | mediana | grande (clase ISO)
respaldo(Maquina, Otra).               % Otra cubre a Maquina si falla
rango(Variable, Minimo, Maximo).       % rango físico de cada variable
lectura(Maquina, Variable, Valor, Hora).  % rms | pico | curtosis | banda_defecto | temperatura
linea_base(Maquina, Regimen, Variable, Valor).
temp_nominal(Maquina, Grados).
evento(Maquina, Tipo, Detalle, Hora).  % cambio_regimen | golpe | paro | arranque | orden
refaccion(Parte, Cantidad).
ventana_paro(Linea, Desde, Hasta).
```

## Contrato del gemelo

- `decide(+Maquina, -Decision, -Explicacion)` — predicado central. En el eje experto la
  entidad es una máquina (la decisión de una puede depender de las otras, como en la
  situación 5). `Decision` incluye el nivel y la acción; `Explicacion` es una lista de
  hechos y condiciones que la justifican. Al pedir más soluciones debe dar las demás
  alternativas válidas; si no hay plan posible, lo dice y señala el motivo, sin fallar
  en silencio.
- `situacion(?Maquina, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  degradación de rodamiento, golpe aislado, sensor pegado), consultables en cualquier
  dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de las máquinas, la decisión con su explicación,
  «qué falta para que cambie» y la consulta hipotética.

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Golpe y tendencia.** Un pico con golpe registrado y sin tendencia previa no escala el
   nivel; el mismo pico con una tendencia previa sostenida sí, y la explicación separa lo
   atribuido al golpe de lo atribuido a la tendencia.
2. **Régimen.** La misma lectura se juzga contra la línea base del régimen vigente a esa
   hora. Si el criterio absoluto y el relativo discrepan, la explicación nombra cuál
   mandó. Sin hora del cambio de régimen, el resultado es «no se sabe».
3. **Evidencia combinada.** La vibración creciente con temperatura aún nominal es
   degradación en etapa temprana, no «normal». La temperatura alta sin vibración no se
   diagnostica como rodamiento. La explicación encadena las razones.
4. **Dato dudoso.** Un sensor pegado y uno desconectado dan «no se sabe», distinto de
   «normal», y nunca producen alarma ni tranquilidad. Un silencio con paro registrado no es
   una falla. Una señal contradictoria del otro sensor se cita en la explicación.
5. **Plan.** Con refacción y ventana insuficientes, el gemelo muestra qué máquina recibe
   cada recurso, la regla de prioridad que lo decidió y a quién se acepta el riesgo; si
   no hay plan que dé el anticipo requerido, lo dice y señala qué falta.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el estado de cada máquina
(nivel, tendencia y confiabilidad de sus sensores), la decisión, la explicación, la
respuesta a «qué falta» y el plan de refacción y ventana. Debe verse bien en celular.
