# Contexto para agentes — gemelo digital del proyecto #74 (Radio o streaming)

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
| Cola | Lista de canciones propuestas que esperan turno, ordenadas por criterios de la radio |
| Propuesta | Canción que una cuenta pide agregar a la cola |
| Voto | Apoyo de una cuenta a una canción de la cola; su valor lo decide la radio |
| Cuenta / persona | La cuenta se ve; la persona detrás no. Una persona puede tener varias cuentas |
| Señal de cuenta | Dato observable (dispositivo, red, hora de alta) que sugiere, sin probar, identidad |
| Segmento | Trozo de audio de 2 a 10 segundos con el que se difunde (HLS/DASH) |
| Retraso del oyente | Diferencia entre lo que sale del servidor y lo que el oyente oye |
| Cierre de decisión | Instante, antes del fin de la canción, en que se fija la siguiente para no dejar silencio |
| Licencia | Condición bajo la cual se puede emitir: libre (Creative Commons) o con derechos de ejecución pública que cobra una sociedad de gestión |
| Elegible | Canción que la radio puede emitir ahora; no es lo mismo que tener votos |
| Respaldo | Música que suena cuando ninguna canción de la cola es elegible |

Cifras de referencia, todas del problema original: segmentos de 2 a 10 segundos; escenario
de 500 oyentes, 80 votantes activos y 200 canciones; 100 votos en 10 segundos desde 3
cuentas; el voto de alguien con 5 cuentas. (128 kbps, 16 KB/s, ~58 MB por hora y ~29 GB
por hora son del lado de Erlang y no se usan aquí.)

Del ejercicio, no del original: la escala reducida (10 canciones, 5 votantes, 8 oyentes),
los títulos, las cuentas y los ejemplos, el reglamento de la radio (licencias que puede
emitir, peso del voto, límite por proponente, desempates, respaldo) y toda señal o
umbral de sospecha. Márcalos como tales.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar ráfagas de votos simulados o graficar. Prolog nunca es una librería de Python
  aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundo).                          % segundos desde el inicio de la emisión
cancion(Cancion, Titulo, Duracion).      % Duracion en segundos
licencia(Cancion, Tipo).                 % libre | gestion_colectiva | sin_dato (o los tipos que defina el estudiante)
propuesta(Cancion, Cuenta, Segundo).     % quién la propuso y cuándo
voto(Id, Cuenta, Cancion, Segundo).      % Segundo: instante en que lo recibió el servidor
senal_cuenta(Cuenta, Tipo, Valor).       % Tipo: dispositivo | red | alta; lo observable, no la persona
oyente(Oyente, Cuenta).
retraso_oyente(Oyente, Segundos, Segundo). % retraso medido y cuándo se midió; puede faltar
evento(Entidad, Tipo, Detalle, Segundo). % inicio_cancion, fin_cancion, archivo_danado, reconexion...
regla_radio(Concepto, Valor).            % reglamento propio de la radio; lo define el estudiante
```

## Contrato del gemelo

- `decide(+Entidad, -Decision, -Explicacion)` — predicado central. `Entidad` dice qué se
  decide: un voto (¿cuenta y cuánto vale?), una canción (¿puede sonar?) o el momento de
  elegir (¿qué suena después?, ¿qué suena si no hay nada?); el estudiante fija la forma de
  esos términos y la documenta. `Explicacion` es una lista de hechos y condiciones que
  justifican la decisión.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  cuentas probablemente de la misma persona, voto fuera de tiempo, canción no elegible,
  empate provisional o cola efectivamente vacía), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: la cola ordenada con el criterio de cada posición, la decisión
  sobre un voto o una canción con su explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y su reglamento.

1. **Personas, no cuentas.** Una avalancha de votos desde pocas cuentas no gana a una
   canción apoyada por más personas distintas. Una cuenta sospechosa solo por compartir
   red con otra se marca como sospecha («no se sabe»), no como duplicado probado, y la
   explicación lista las señales. Cambiar un hecho (que dos cuentas son de personas
   distintas) cambia el resultado sin tocar las reglas.
2. **Frontera del voto.** Un voto recibido claramente antes del cierre entra y uno
   claramente después no, aun si el aparato declara otra hora. Con el retraso del oyente
   sin medir, el veredicto es «no se sabe» y dice qué dato falta. Un voto tardío tiene un
   destino explícito, no se pierde en silencio.
3. **Elegibilidad.** La canción más votada con licencia que no cubre la radio no sale
   como siguiente, y la explicación nombra la licencia como causa. Una licencia sin dato da
   «no se sabe» y tampoco suena. La consulta inversa dice qué tendría que cambiar.
4. **Orden y límites.** Un proponente no copa las primeras posiciones aunque tenga más
   votos, y la explicación nombra el límite. Cada posición nombra su criterio decisivo,
   y un empate que ningún criterio rompe se reporta como empate o como provisional si
   aún se vota; nunca se inventa un orden.
5. **Cola vacía.** Una cola con canciones pero ninguna elegible cuenta como vacía y suena
   el respaldo permitido. Un archivo reportado por un solo oyente se distingue de uno
   confirmado como dañado. La explicación dice qué pasa con la canción cortada.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar qué suena y qué sigue, la
cola ordenada con el criterio de cada posición, cada voto con su validez, su peso y la
razón, las cuentas bajo sospecha marcadas como sospecha y no como hecho, la licencia y la
elegibilidad de cada canción, y la respuesta a «qué falta para que cambie». Debe verse
bien en celular.
