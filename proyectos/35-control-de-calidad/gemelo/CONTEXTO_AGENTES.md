# Contexto para agentes — gemelo digital del proyecto #35 (Control de calidad)

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
| Carta de control | Gráfica de una característica en el tiempo con la media y límites a ±3 desviaciones estándar |
| Causa especial | Señal de que el proceso se desvió, distinta de la variación normal |
| Western Electric / Nelson | Patrones: 8 puntos del mismo lado de la media, 6 en tendencia, 2 de 3 cerca del límite |
| Cpk | Mide si el proceso cabe en la tolerancia; mínimo común 1.33, 1.67 en características críticas |
| Característica crítica | La que, si falla, afecta seguridad o función del producto; exige un Cpk más alto |
| Muestreo por aceptación (AQL) | Se inspecciona una muestra del lote y se acepta o rechaza según los defectos hallados |
| Semáforo | Verde acepta, amarillo retiene, rojo rechaza |
| Contención | Segregar el lote, rastrear lotes vecinos y notificar |
| Lote vecino | Lote que comparte materia prima con otro |
| Reinspección | Nueva inspección de un lote rechazado o retenido |
| Medición tardía | Capturada después de otra posterior; el orden real es el del minuto de medición |

Cifras de referencia (del original): límites de ±3 desviaciones estándar; 8 puntos del
mismo lado, 6 en tendencia, 2 de 3 cerca del límite; Cpk de 1.33 y 1.67; Seis Sigma = 3.4
defectos por millón; lote de 1,000 piezas con muestra de 80; 6 características cada
15 minutos; 20 lotes por turno; deriva de 3 horas; un lote rechazado que comparte materia
prima con otros 4. Marcado como de esta extensión: la escala de 3 características,
2 estaciones y 8 lotes, la planta y sus dos clientes (automotriz y de dispositivos
médicos), la causa del rechazo pendiente, la materia prima mezclada, el lote sin registro
y los números de los ejemplos. El original no da cuántos defectos acepta el plan de
muestreo ni qué significa «cerca del límite»: son decisiones del estudiante.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar mediciones simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  El ruido de las mediciones, las capturas tardías y las faltantes entran como hechos,
  no se sortean.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                           % minutos desde el inicio de la ventana del escenario
caracteristica(Caracteristica, Estacion, Criticidad).   % Criticidad: critica | normal
referencia(Caracteristica, Media, Desviacion).          % media y desviación del proceso
tolerancia(Caracteristica, Inferior, Superior).
rango(Caracteristica, Minimo, Maximo).   % rango físico posible de la medición
medicion(Lote, Caracteristica, Valor, MinutoMedido, MinutoCaptura).
lote(Lote, Estacion, Tamano, MinutoProduccion).
materia_prima(Lote, Materia).            % puede haber varias por lote o ninguna registrada
plan_muestreo(Producto, TamanoMuestra, MaxDefectos).    % lo define el estudiante
inspeccion(Lote, Muestra, Defectos, Minuto).            % puede haber varias por lote
envio(Lote, Cliente, Minuto).
evento(Lote, Tipo, Quien, Minuto).       % en_inspeccion|retenido|rechazado|reinspeccion|reabierto|aprobado
```

## Contrato del gemelo

- `decide(+Entidad, -Decision, -Explicacion)` — predicado central. `Entidad` es una
  estación, una característica o un lote según la situación. `Decision` dice qué hacer
  (parar la línea o solo avisar, el semáforo del lote, qué contener y a quién notificar,
  si procede reabrir o que no se puede concluir); `Explicacion` es una lista de hechos
  y condiciones que lo justifican, y nombra la regla que perdió cuando dos se
  contradicen.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  proceso con señal de causa especial, lote del tramo en duda, lote afectado por un
  rechazo, medición imposible o tardía), consultables en cualquier dirección, incluida la
  trazabilidad hacia adelante y hacia atrás.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de cada estación y característica con sus señales,
  el semáforo de cada lote con su explicación, los lotes afectados por un rechazo según
  cada causa, el semáforo reconstruido a un minuto dado y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Deriva.** Una característica con todas sus mediciones dentro de límites y buen Cpk,
   pero con una racha que cumple un patrón del original, aparece con señal, y la
   evidencia dice qué patrón y desde qué medición. La misma racha en una característica
   no crítica produce una reacción distinta de la crítica. Los lotes del tramo pasan a
   retención y la consulta inversa dice qué cambiaría el resultado.
2. **Muestra contra proceso.** Con la muestra aceptable y el proceso en señal, el lote
   no sale verde, y la explicación nombra tanto a la regla que decidió como a la que
   perdió y a quién se le falla. Con el mismo resultado de muestra en un lote producido
   antes de la señal, o en una característica no crítica, la decisión puede cambiar con
   las mismas reglas.
3. **Datos dudosos.** Una medición imposible no cuenta como evidencia ni dispara
   alertas. Una tardía se ordena por su minuto de medición, no por el de captura. Con
   huecos o pocos datos la respuesta es «no se sabe», distinta de «no se cumple», nunca
   verde por omisión y nunca rojo por una racha sin confirmar, y dice qué medición la
   resolvería.
4. **Contención.** Un rechazo alcanza a los lotes que comparten materia prima, también
   al que la usó mezclada, y dice dónde está hoy cada uno y cuáles se enviaron después
   del rechazo. Con la causa pendiente, la lista incluye también los lotes por tiempo en
   la línea, cada uno con su motivo. El lote sin materia registrada da «no se sabe». La
   consulta hacia atrás, desde un lote enviado, devuelve de qué viene.
5. **Reapertura.** Una reinspección limpia no reabre por sí sola un lote cuya causa sigue
   activa o con vecinos retenidos; el historial conserva el rechazo, y la respuesta dice
   qué falta y quién autoriza. El semáforo a un minuto pasado puede diferir del actual
   porque había mediciones aún sin capturar, con las mismas reglas.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar, por estación, la carta de
control de cada característica con las señales marcadas; el semáforo de cada lote con su
decisión y explicación, la regla que perdió y a quién se le falló; las mediciones
válidas, imposibles, tardías y faltantes distinguidas; el árbol de contención de un
rechazo con la ubicación o el cliente de cada lote y los «no se sabe» marcados; el
historial de un lote con un selector de minuto pasado; y la respuesta a «qué falta».
Debe verse bien en celular.
