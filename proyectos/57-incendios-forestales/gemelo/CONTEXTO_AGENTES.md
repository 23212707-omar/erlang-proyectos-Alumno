# Contexto para agentes — gemelo digital del proyecto #57 (Incendios forestales)

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
| Cañón | Barranco donde se reparten los sensores; unidad sobre la que se decide el riesgo |
| Enlace | Colindancia entre dos cañones, con rumbo y pendiente; por ahí puede pasar el fuego |
| Bandera roja | Alerta meteorológica: humedad relativa baja con viento sostenido, por varias horas |
| Santa Ana | Viento seco y fuerte que baja hacia la costa y empuja los incendios |
| Combustible muerto | Hojarasca y ramas secas; si su humedad es muy baja, el fuego se propaga fácil |
| Pendiente | Inclinación de la ladera; el fuego sube más rápido de lo que baja |
| Punto de calor | Detección satelital (tipo NASA FIRMS) con retraso respecto a la hora detectada |
| Quema autorizada | Quema agrícola con permiso; fuente de humo que no es un incendio |
| Lugar expuesto | Colonia, rancho u otro punto que se debe proteger, ligado a un cañón |
| Silencio | Sensor que dejó de reportar: falla de energía o señal, o destruido por el fuego |

Cifras de referencia (del original): bandera roja con humedad relativa ≤ 15 % y viento
sostenido ≥ ~40 km/h durante varias horas; velocidad del fuego que se duplica
aproximadamente cada 10° de pendiente; combustible muerto bajo ~8-10 % de humedad;
puntos de calor satelitales cada pocas horas y con retraso; escenario de 40 sensores en 5
cañones con lectura cada minuto; día de Santa Ana con 10 % de humedad y 60 km/h. Marcados
como del ejercicio, sin cifras: 4 cañones, 10 sensores, enlaces, rumbos, pendientes,
lugares expuestos, registro de quemas y cobertura de sensores.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Si la simulación necesita azar (un retraso del satélite, un sensor que falla), el valor
  entra como hecho; las reglas no sortean nada.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                          % instante del gemelo, en minutos desde un origen fijo
canon(Canon).
sensor(Sensor, Canon, Tipo).            % Tipo: humo_temp | clima | combustible
cerca(Sensor1, Sensor2).                % vecindad entre sensores; el estudiante decide la simetría
enlace(Origen, Destino, Rumbo, Pendiente). % cañones colindantes; Pendiente en grados
rango(Variable, Minimo, Maximo).        % rango físico de cada variable
lectura(Sensor, Variable, Valor, Minuto).
evento(Sensor, Suceso, Minuto).         % Suceso: calla | vuelve
punto_calor(Id, Canon, Detectado, Recibido). % satélite; ambos instantes en minutos
quema_autorizada(Id, Canon, Desde, Hasta).
expuesto(Lugar, Canon).                 % colonia o rancho a proteger
```

## Contrato del gemelo

- `decide(+Entidad, -Decision, -Explicacion)` — predicado central. La entidad es un
  cañón, un sensor o un lugar expuesto; el estudiante elige cómo representarla. Para un
  cañón o un lugar, `Decision` es el nivel de vigilancia o alerta que corresponde (o por
  qué no se sabe); para un sensor, qué crédito merece su dato o su silencio. En el eje
  experto la entidad es una sola, no una lista. `Explicacion` es una lista de hechos,
  fuentes, reglas y evidencias que la justifican.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (cañón en
  riesgo, fuente que coincide, sensor callado por falla o por fuego, cañón amenazado,
  cañón sin vigilancia, punto de calor vigente), consultables en cualquier dirección:
  dado un cañón, sus situaciones; dada una situación, quiénes la cumplen.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- Toda inferencia (por ejemplo, el avance estimado o el combustible de un cañón sin
  medición) se marca como inferencia y cita los hechos que la sustentan; nunca se presenta
  como un dato.
- La API expone al menos: el estado de los cañones y sensores, la decisión con su
  explicación, el orden estimado de llegada y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Bandera roja.** Un cañón que cumple todos los criterios de forma sostenida aparece
   en riesgo y la evidencia lista cada criterio; uno al abrigo del viento, o al que falta
   un criterio, aparece como «vigilar» y dice cuál falta. Sin medición de combustible, la
   respuesta es «no lo sé» y dice qué faltaría, no «no».
2. **Dos contra tres.** Dos sensores en alarma con vecinos que no pueden ver ese punto no
   se anulan por conteo: la respuesta pide confirmación y explica qué fuentes cuentan.
   Una quema autorizada vigente explica el humo y baja el nivel, y la respuesta dice a
   quién se le falla con esa política. Si los vecinos sí podrían verlo, el nivel baja.
3. **Silencio.** Un sensor que calla tras subir la temperatura y con vecinos cercanos en
   alarma se declara probablemente quemado; uno que calla junto con su red, sin subida
   previa, se declara falla; con evidencia mixta la respuesta es «no lo sé». Ningún
   silencio produce alerta por sí solo.
4. **Avance.** Con un fuego confirmado, la respuesta ordena los cañones y lugares por
   llegada probable y lo marca como estimación. Un lugar cercano con viento y pendiente en
   contra puede ir después de uno más lejano. Si el viento gira, el orden cambia y la
   explicación dice qué enlace lo cambió. Un cañón sin sensor vivo se marca sin
   confirmación.
5. **Satélite.** Un punto de calor viejo en un cañón sin sensores no se trata como el
   fuego de ahora, pero tampoco se ignora: la respuesta dice dónde puede estar y qué
   cañón carece de vigilancia. «Sin alerta» en un cañón sin ojos da «no lo sé», distinto
   de «no hay fuego».
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el estado de cada cañón y
sensor, la decisión por cañón y lugar con su explicación, el orden estimado de llegada y
la respuesta a «qué falta». Debe distinguir a la vista lo medido de lo inferido y de lo
que no se sabe, y verse bien en celular.
