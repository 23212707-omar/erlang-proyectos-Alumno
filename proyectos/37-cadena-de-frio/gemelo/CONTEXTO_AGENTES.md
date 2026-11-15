# Contexto para agentes — gemelo digital del proyecto #37 (Cadena de frío)

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
| Cadena de frío | Mantener un producto dentro de su rango de temperatura del productor al consumidor |
| Excursión | Periodo en que la temperatura sale del rango del producto; importan su duración y su magnitud |
| Zona de peligro | Entre 4 °C y 60 °C en alimentos; las bacterias se multiplican con rapidez |
| Tiempo acumulado | Suma de todas las excursiones de un lote, no de la más larga |
| Data logger / sonda | Instrumento que registra temperatura cada 1-15 min; puede guardar lecturas sin transmitirlas |
| Lectura atrasada | Lectura medida en un instante y recibida en otro; el historial se ordena por cuándo se midió |
| Hueco | Periodo sin lecturas (pérdida de señal, falla o descarga de la sonda) |
| Apertura de puertas | Subida temporal al cargar o descargar; distinta de una falla del equipo |
| Verificación | Comparación de una sonda contra una referencia; revela su error |
| Lote | Unidad de producto que se acepta, retiene o rechaza completa |
| Destino | Resolución sobre un lote: liberar, liberar con condición, retener o rechazar (de esta extensión) |
| Evidencia legal | El registro de temperaturas es la prueba ante HACCP, FSMA y COFEPRIS/NOM |

Cifras de referencia (del original): vacunas típicas 2-8 °C, algunas de ARNm hasta -70 °C,
congelados -18 °C o menos; zona de peligro de 4 a 60 °C con un máximo de 2 horas
acumuladas; lecturas cada 1-15 min (el escenario usa cada 2 min); camión sin conexión 3
horas; sonda con 2 °C de error; compresor que sube 1 °C cada 10 min; 12 camiones y 4
cámaras. Marcado como de esta extensión: la escala de 3 camiones y 2 cámaras, la
distribuidora, el hospital, el chofer que anota la puerta, las dos sondas por caja, los
destinos del lote y los números de los ejemplos. El original no da cuánto dura una
apertura normal, ni la tolerancia de las vacunas fuera de su rango, ni cuántas lecturas
faltantes hacen un hueco: son decisiones del estudiante.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  El ruido de las lecturas y las pérdidas de señal entran como hechos, no se sortean.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                         % unidad: minuto
unidad(Unidad, Tipo).                  % Tipo: camion | camara
sonda(Sonda, Unidad, Rol).             % Rol: aire | carga | gobierno
rango(Variable, Minimo, Maximo).       % rango físico de la sonda (lo creíble)
lote(Lote, Producto).
rango_producto(Producto, Minimo, Maximo).  % rango de temperatura permitido
estancia(Lote, Unidad, Desde, Hasta).  % tramo del recorrido del lote
lectura(Sonda, Grados, MedidaEn, RecibidaEn).
evento(Unidad, Tipo, Detalle, Minuto). % puerta_abierta | puerta_cerrada | compresor | sin_senal | senal_recuperada
verificacion(Sonda, Error, Minuto).    % error hallado; el sentido puede no constar
pedido(Lote, Destinatario, Limite).    % quién lo necesita y para cuándo
```

## Contrato del gemelo

- `decide(+Lote, -Decision, -Explicacion)` — predicado central. En el eje experto la
  entidad es un lote (su decisión depende de las unidades y sondas por las que pasó).
  `Decision` incluye el destino y la acción; `Explicacion` es una lista de hechos y
  condiciones que la justifican. Al pedir más soluciones debe dar los demás destinos
  válidos; si ninguno es posible, lo dice y señala el motivo, sin fallar en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  falla de compresor, excursión del lote, hueco sin cubrir, sonda sospechosa),
  consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de unidades y lotes, la decisión con su explicación,
  «qué falta para que cambie» y la consulta hipotética.

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Descarga o compresor.** Una subida con la puerta abierta que se recupera al cerrarla
   no se diagnostica como falla; una que sigue subiendo con la puerta cerrada, sí, aunque
   hubiera una descarga anotada. Sin dato de puerta, el resultado es «no se sabe» y la
   explicación dice qué lo aclararía.
2. **Acumulado.** El tiempo del lote se suma entre excursiones y solo cuenta los tramos en
   que el lote estaba en esa unidad. Un lote hoy en rango puede quedar perdido; una
   excursión de la unidad anterior a su llegada no se le atribuye. La explicación nombra
   el tramo que más gastó.
3. **Hueco.** Lecturas buenas antes y después de un hueco no prueban que no hubo
   excursión: el resultado es «no se sabe». Al llegar lecturas atrasadas que cubren el
   hueco, la misma consulta cambia a «no hubo» o «hubo», y la explicación lo dice.
4. **Sonda sospechosa.** Una lectura dentro de rango pero a menos del error de verificación
   del límite da «no se puede afirmar», distinto de «dentro» y de «fuera». La explicación
   cita qué sonda se prefirió y por qué.
5. **Destino y dilema.** Con evidencia incompleta y un pedido urgente, el gemelo muestra
   los destinos válidos, a quién se le falla con cada uno y qué evidencia cambiaría el
   veredicto; nunca libera por urgencia sin decirlo. Si ninguno es válido, lo dice.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el estado de cada unidad
(sondas, puerta, señal, compresor), la línea de tiempo de cada lote con sus excursiones y
huecos señalados, el tiempo acumulado, el destino con su explicación y la respuesta a
«qué falta». Debe verse bien en celular.
