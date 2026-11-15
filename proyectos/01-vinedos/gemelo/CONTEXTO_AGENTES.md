# Contexto para agentes — gemelo digital del proyecto #1 (Viñedos)

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
| Parcela | Bloque de la finca; agrupa hileras y tiene posición alta o baja |
| Hilera | Fila de vides; unidad sobre la que se decide |
| VWC | Contenido volumétrico de agua del suelo, 0-100 % |
| Hoja mojada | Sensor resistivo, valor aproximado 0-15 |
| Brotación | Etapa en que salen los brotes (marzo-abril); desde ahí la helada daña |
| Mildiu | Hongo *Plasmopara viticola* |
| «Tres 10» | ~10 mm de lluvia, ~10 °C de mínima, brotes de ~10 cm |
| Riego deficitario | Regar por debajo de la demanda a propósito, por calidad |

Cifras de referencia: helada entre 0 y -2 °C tras la brotación; infección con hoja
mojada continua 6-8 h o más y 18-25 °C; hileras a 200 m difieren 2-3 °C; descenso de
1.5 °C/hora en la noche de helada; 10 % de sensores sin reportar.

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
ahora(Minuto).
parcela(Parcela, Posicion).            % Posicion: alta | baja
hilera(Hilera, Parcela).
vecina(Hilera1, Hilera2).
etapa(Hilera, Etapa).                  % dormancia | brotacion | floracion | envero | madurez
rango(Variable, Minimo, Maximo).
lectura(Hilera, Variable, Valor, Minuto).
lluvia(Parcela, Milimetros).
temp_minima(Parcela, Grados).
```

## Contrato del gemelo

- `decide(+Hilera, -Decision, -Explicacion)` — predicado central. `Explicacion` es una
  lista de hechos y condiciones que justifican la decisión.
- `situacion(?Hilera, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  riesgo de mildiu o helada), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de las hileras, la decisión con su explicación y
  «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Mildiu.** Una hilera que cumple los «tres 10» aparece en riesgo y la evidencia
   lista los tres criterios. Una a la que le falta uno solo aparece como «vigilar» y
   dice cuál falta. Hoja mojada prolongada fuera de 18-25 °C no cuenta como infección.
2. **Helada y etapa.** La misma temperatura bajo cero produce alerta en una hilera en
   brotación y no en una en dormancia.
3. **Conflicto.** Suelo seco con helada activa: no se riega, y la explicación nombra la
   helada como la causa. La consulta inversa devuelve qué tendría que cambiar.
4. **Dato dudoso.** Una lectura fuera de rango y un sensor sin reportar dan «no se
   sabe», distinto de «no se cumple», y nunca producen riego ni alerta.
5. **Vecinas.** Una hilera sin dato en zona baja, con vecinas en helada, recibe una
   inferencia marcada como tal y con las vecinas que la sustentan.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el estado de cada hilera,
la decisión, la explicación y la respuesta a «qué falta». Debe verse bien en celular.
