# Contexto para agentes — gemelo digital del proyecto #5 (Estación meteorológica)

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
| Zona de aviso | Área para la que se emite un aviso; agrupa una o más estaciones |
| Estación | Conjunto de sensores en un sitio; de red oficial o escolar |
| Muestra | Una medición de un sensor, con su instante |
| Ventana / promedio móvil | Los valores de los últimos diez minutos y su promedio |
| Ráfaga | Máximo del viento en un lapso corto (~3 s) |
| Santa Ana | Viento fuerte y seco de otoño-invierno; con humedad muy baja dispara incendios |
| Cero fijo | Un sensor que marca el mismo cero muestra tras muestra: ¿calma o falla? |
| Lote atrasado | Muestras viejas que llegan juntas cuando una estación vuelve |

Cifras de referencia (todas del problema original): ráfagas de 60 a 100 km/h y humedad
relativa por debajo de 15 % en Santa Ana; viento promedio de 10 minutos; ráfaga en ~3 s;
muestras entre 1 y 60 s; estación apagada 40 minutos; 5 estaciones y 8 sensores por
estación en el escenario original. Son de la escala reducida de esta extensión, y así hay
que tratarlos: 3 estaciones, 2 zonas, 5 sensores, los nombres Costa, Loma y Secundaria.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar muestras simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  El azar de las muestras simuladas entra como hechos o queda como supuesto.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundo).                         % instante actual; unidad: segundos
temporada(Temporada).                   % otono_invierno | primavera_verano
estacion(Estacion, Red, Zona).          % Red: oficial | escolar
sensor(Estacion, Sensor, Tipo).         % Tipo: viento | temperatura | humedad | presion | lluvia
vecina(Estacion1, Estacion2).
rango(Variable, Minimo, Maximo).        % rango físico posible de cada variable
lectura(Estacion, Sensor, Valor, Segundo).        % Segundo: instante de la medición
llegada(Estacion, Sensor, Segundo, SegundoLlegada). % cuándo llegó esa medición al gemelo
evento(Estacion, Suceso, Segundo).      % Suceso: apagada | encendida | ...
aviso(Zona, Tipo, Segundo).             % aviso emitido en esa zona
```

## Contrato del gemelo

- `decide(+Entidad, -Decision, -Explicacion)` — predicado central. `Entidad` es una zona
  de aviso o una estación. `Decision` es un aviso (emitir, no emitir, no puedo decir) o
  un veredicto sobre la confianza en una estación. `Explicacion` es una lista de hechos y
  condiciones, en orden, que justifican la decisión.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (condición Santa
  Ana, riesgo de incendio, anemómetro sospechoso, lectura atrasada), consultables en
  cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de cada estación y zona, la decisión con su
  explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Santa Ana.** Con promedios válidos, viento fuerte, humedad muy baja y temporada, la
   zona recibe aviso de riesgo de incendio y la explicación muestra la cadena completa.
   Si falta un solo eslabón, no hay aviso y se nombra el eslabón que falta.
2. **Ventana pobre.** Una ventana con muy pocas muestras no produce «no hay viento
   fuerte»: produce «no se sabe», salvo que la evidencia presente ya baste para afirmar
   lo contrario. La respuesta dice qué muestras la sustentan.
3. **Cero fijo.** El mismo cero da calma, falla o duda según lo que digan los demás
   sensores de la estación y sus vecinas. Al declarar la falla, las conclusiones que
   usaban ese viento quedan en duda y se ve cuáles.
4. **Lote atrasado.** El gemelo responde distinto a «qué se sabía entonces» y «qué se sabe
   ahora». Una marca de tiempo ambigua por cambio de hora se marca como ambigua, no se
   acepta ni se descarta en silencio.
5. **Dos versiones.** Con dos estaciones de la misma zona en desacuerdo, la decisión
   nombra la regla de peso que se aplicó y a cuál lado se le falla si se equivoca. La
   respuesta no es «gana la oficial» sin más.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar las estaciones por zona,
con el estado de sus sensores y la confianza en cada una, el aviso por zona con su
cadena de razones, la línea de tiempo de lo que se sabía y cuándo, y la respuesta a
«qué falta». Debe verse bien en celular.
