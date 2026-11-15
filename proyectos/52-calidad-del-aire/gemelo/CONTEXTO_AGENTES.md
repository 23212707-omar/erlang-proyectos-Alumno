# Contexto para agentes — gemelo digital del proyecto #52 (Calidad del aire)

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
  se marca como supuesto y se le pide al estudiante la fuente. Las zonas, los números de
  sensor, las escuelas y la clínica de los ejemplos son del ejercicio, no del mundo.

## Dominio

| Término | Significado |
|---|---|
| PM2.5 | Partículas menores a 2.5 µm; se mide en µg/m³ |
| Sensor de bajo costo | Láser barato (clase PMS5003); se sobrestima con humedad y se degrada |
| Estación de referencia | Estación oficial; sirve para contrastar a los sensores baratos |
| Zona | Área de la ciudad con su nivel; puede no tener sensor propio |
| Lectura válida / imposible / vieja | Dentro del rango físico y reciente / fuera de rango / sin reporte reciente |
| Pegado | Sensor que repite un valor mientras su entorno cambia |
| Promedio móvil | Promedio sobre una ventana de ~1 a 12 h; sirve para avisos rápidos |
| Promedio de 24 h | El de las normas y del índice; con huecos, puede o no ser válido |
| Episodio | Subida real de la contaminación en una o varias zonas; no se mide, se deduce |
| Categoría (AQI, EPA 2024) | Bueno, Moderado, Dañino para grupos sensibles, Dañino, Muy dañino |
| Grupos sensibles | Personas con asma o enfermedades del corazón, entre otras |
| Inferencia | Nivel estimado de una zona sin sensor; no es una lectura |

Cifras de referencia (del original): OMS 2021, 15 µg/m³ en 24 h y 5 anual;
NOM-025-SSA1-2021, 33 µg/m³ en 24 h y 10 anual; categorías Bueno 0-9.0, Moderado
9.1-35.4, Dañino para grupos sensibles 35.5-55.4, Dañino 55.5-125.4, Muy dañino
125.5-225.4; lectura cada 1-2 min; el humo puede subir 10 veces en 20 minutos; el
escenario sube de 10 a 150 en una hora, tiene 25 sensores y un sensor pegado en 999.
Marcados como del ejercicio, sin cifras: la humedad de cada sensor, las zonas, las
escuelas y la clínica.

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
ahora(Minuto).                           % instante del gemelo, en minutos desde el inicio
zona(Zona).
sensor(Sensor, Zona, Meses).             % Meses: tiempo en servicio
vecino(Entidad1, Entidad2).              % entre sensores o entre zonas
estacion_referencia(Estacion, Zona).
punto(Punto, Zona, Tipo).                % Tipo: escuela | clinica
rango(Variable, Minimo, Maximo).         % rango físico: pm25 | humedad
lectura(Sensor, Variable, Valor, Minuto).% pm25 en µg/m³, humedad en %; Minuto lo trae el dato
categoria(Nombre, Minimo, Maximo).       % bandas AQI de la EPA en µg/m³
norma(Fuente, Horas, Limite).            % oms | nom, promedio en horas, µg/m³
```

## Contrato del gemelo

- `decide(+Entidad, -Decision, -Explicacion)` — predicado central. La entidad es una
  zona (por ejemplo `zona(este)`) o un sensor; el estudiante elige cómo representarla.
  Para una zona, `Decision` es el nivel con su recomendación por audiencia (población
  general, grupos sensibles, escuela, clínica) o por qué no se puede dar; para un
  sensor, qué se hace con sus lecturas (usarlas, descartarlas, vigilarlas).
  `Explicacion` es una lista de hechos, lecturas, reglas y evidencias que la justifican.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (lectura pegada,
  episodio real, artefacto de humedad, cumplimiento de una norma, nivel inferido),
  consultables en cualquier dirección: dado un sensor, sus problemas; dada una situación,
  quiénes la cumplen.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de zonas y sensores, la decisión con su explicación,
  qué lecturas se descartaron y por qué, el cumplimiento de cada norma y «qué falta para
  que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Sensor pegado.** Una lectura fuera de rango se descarta y se cuenta. Un sensor que
   repite un valor creíble mientras su entorno cambia queda marcado como pegado, con el
   instante en que empezó; si su entorno tampoco cambia, la respuesta es «no se sabe».
   Un sensor excluido no entra en promedios ni alertas, y nunca produce un aviso.
2. **Episodio.** Con varios sensores de confianza que suben a la vez, el episodio se
   declara real y la evidencia los lista. Un sensor aislado sin vecinos da «no puedo
   confirmarlo», distinto de «no hay episodio». El aviso rápido usa un promedio móvil, no
   el de 24 h, y el veredicto cambia sin tocar otras reglas si cambia cuántos coinciden.
3. **Humedad.** Con humedad alta, la lectura se corrige y la respuesta separa lo medido de
   lo corregido. Si la referencia o los sensores de aire más seco también suben, el
   episodio sigue siendo real aunque el valor corregido sea menor; si no, se marca como
   artefacto. La evidencia muestra cada paso de la cadena.
4. **Huecos.** Un promedio de 24 h con pocas horas de datos no se acepta como válido.
   Cada norma da «cumple», «excede» o «no se sabe», con las horas con datos y las que
   faltan; una zona puede cumplir una norma y exceder la otra. La consulta inversa dice
   qué tendrían que haber medido las horas faltantes para cambiar la respuesta.
5. **Zona sin sensor.** El nivel de la zona sin sensor sale marcado como inferencia, con
   las zonas vecinas que lo sustentan. Si cae a ambos lados de una frontera de categoría
   lo dice. La recomendación distingue grupos sensibles de población general y usa un
   promedio vigente, no una lectura de un instante.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el mapa o la lista de zonas
con su nivel y su categoría, cada sensor con el estado de su lectura (válida, descartada,
pegada, no se sabe), la recomendación por audiencia con su explicación, el cumplimiento de
cada norma con sus tres respuestas, las inferencias marcadas como tales y la respuesta a
«qué falta». Debe verse bien en celular.
