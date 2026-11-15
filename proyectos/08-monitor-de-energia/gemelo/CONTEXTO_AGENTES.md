# Contexto para agentes — gemelo digital del proyecto #8 (Monitor de energía)

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
| Medidor | Aparato Modbus que reporta V, A, kW, kVAr, kWh acumulado, Hz y THD |
| Bus | Línea RS-485 donde los medidores se consultan uno por uno, en orden |
| Timeout | Consulta sin respuesta a tiempo; es frecuente y no siempre culpa del medidor |
| Demanda máxima | Promedio de potencia en una ventana de 15 min; define un cargo mensual |
| Factor de potencia | kW / kVA; hay penalización si es menor a 0.90 y bonificación si es mayor |
| Contador kWh | Acumulado que puede reiniciarse o desbordarse |
| Medidor compartido | Un medidor que atiende a más de un área, cuyo consumo hay que repartir |
| Aguas arriba / abajo | Relación eléctrica: un medidor general alimenta a los que cuelgan de él |
| Acometida | Entrada del edificio; su medidor ve todo lo que pasa dentro |

Cifras de referencia (todas del problema original): red de 127 V monofásico / 220 V
trifásico a 60 Hz; ventanas de 15 min para la demanda; factor de potencia de 0.90;
RS-485 a 9600 baud, respuestas de decenas de ms; consulta cada 5 s; horizonte de 24 h;
30 medidores en 3 buses en el escenario original. Son de esta extensión, y así hay que
tratarlos: 7 medidores en 2 buses y los nombres taller, laboratorio, oficinas, aulas,
bomba, compresor y extractor. Los límites, umbrales y potencias de los motores no vienen
del original: son supuestos del estudiante.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  El azar de las lecturas simuladas (ruido, timeouts) entra como hechos o queda como
  supuesto.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundo).                       % instante actual; unidad: segundos desde el inicio del día
medidor(Medidor, Lugar, Bus, Orden).  % Lugar: acometida | piso1 | piso2 | piso3; Orden: turno en el bus
cuelga_de(Medidor, MedidorGeneral).   % topología eléctrica: aguas abajo de
area(Area, Medidor).                  % un medidor puede atender a varias áreas
horario(Area, Desde, Hasta).          % franja habitual de uso, en segundos del día
rango(Variable, Minimo, Maximo).      % rango físico posible de cada variable
lectura(Medidor, Variable, Valor, Segundo).  % Segundo: instante de la medición
consulta(Medidor, Resultado, Milisegundos, Segundo).  % Resultado: ok | timeout
evento(Entidad, Suceso, Segundo).     % Entidad: medidor o motor; Suceso: arranque | reinicio | ...
limite(Concepto, Valor).              % demanda, caída de voltaje...; los valores los fija el estudiante
```

## Contrato del gemelo

- `decide(+Entidad, -Decision, -Explicacion)` — predicado central. `Entidad` es un
  medidor, un piso, un área o la ventana de demanda del edificio. `Decision` es una
  alarma (anticipada, vigente, ninguna, no puedo decir), una causa, un medidor a aislar o
  un reparto con su grado de certeza. `Explicacion` es una lista de hechos y condiciones,
  en orden, que justifican la decisión.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (rebase
  proyectado, contador reiniciado, medidor lento, lectura atrasada, caída por arranque,
  consumo nocturno esperado), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de cada medidor y piso, la decisión con su
  explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Pico futuro.** La alarma anticipada depende de lo acumulado, el tiempo restante y la
   carga esperada, no de la lectura instantánea. Un pico muy alto y muy breve al inicio
   de la ventana no dispara el rebase si el resto tiene margen; una carga moderada
   sostenida hacia el final, con mucho ya acumulado, sí. La explicación nombra qué
   arranque diferir y a quién se le falla. Con lecturas faltantes, la proyección se
   marca como menos firme.
2. **Contador.** Un salto hacia abajo no produce consumo negativo ni un consumo enorme
   aceptado en silencio. El consumo del piso sale en tres categorías (se sabe, está entre
   tales valores, no se puede saber) y la respuesta dice qué lecturas y qué medidor
   general la sustentan.
3. **Medidor lento.** El gemelo distingue al causante de las víctimas según el orden en
   el bus, no por el conteo de timeouts. Las alarmas que dependían de lecturas viejas
   pasan a «no sé», y se ve cuáles.
4. **Red o motores.** La misma caída de voltaje da causas distintas según dónde se ve y
   cuándo: acometida, otros pisos sin motores, orden entre la potencia y la caída. Con
   timeouts que impiden decidir, la respuesta es «no se puede decir», no una causa
   inventada. La explicación nombra la explicación que descartó.
5. **Reparto.** Para el medidor compartido, el reparto sale con su regla y su certeza
   marcada como estimación. El consumo nocturno del laboratorio no se reporta como
   anomalía si el horario y los equipos lo explican. La respuesta nombra a quién se le
   falla si la regla se equivoca, y quien más consume no es siempre quien más pesa en la
   demanda.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar los medidores por piso y
por bus (con su turno y su retraso), la demanda de la ventana en curso con su
proyección, las alarmas con su causa y su certeza, el reparto por área y la respuesta a
«qué falta». Debe verse bien en celular.
