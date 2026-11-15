# Contexto para agentes — gemelo digital del proyecto #61 (Cotizador de divisas)

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
| Cotización | Valor del dólar en pesos, de una fuente y en un instante |
| Fuente | Quien da cotizaciones: una API de mercado, o el FIX de Banxico |
| FIX | Tipo de cambio que Banxico publica cada día hábil, cerca de las 12:00 |
| Compra / venta | Precios que publica una casa de cambio; compra es lo que paga por tus dólares |
| *Spread* | Diferencia entre venta y compra de una casa |
| Obsoleta | Cotización cuya edad ya no permite llamarla actual (el estudiante fija cuándo) |
| Alerta | Aviso que un usuario pide, por ejemplo «cuando baje de 17.50» |
| Cruce | La cotización pasa de un lado del umbral al otro |
| Rebote | Cruces repetidos alrededor del umbral en poco tiempo |
| Armada / rearmada | Términos del ejercicio, no del original: la alerta puede avisar / vuelve a poder avisar |
| Cuota | Peticiones que el plan de una fuente permite por periodo |

Cifras de referencia: FIX cerca de las 12:00 en día hábil; peso/dólar entre ~16 y ~21 en
los últimos años; variación normal de 0.5 a 1 % en un día y de 2 % o más en horas en
eventos; *spread* típico de 0.10 a 0.40 pesos; APIs públicas con decenas a miles de
peticiones al mes y retraso de minutos u horas; mercados cerrados en fin de semana, con
el último valor del viernes vigente hasta el lunes; consulta cada 30 s; 2 fuentes; 5,000
alertas; 300 consultas por segundo en pico; salto de 2 % en 10 minutos; valor absurdo
(un cero o un 1700); ejemplo de umbral 17.50. Los nombres de casas y usuarios, la cuota
del escenario reducido y los números de ejemplo son del ejercicio, no cifras reales.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar cotizaciones simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Si la simulación necesita azar (una fuente que falla, un valor absurdo, un salto), el
  valor entra como hecho; las reglas no sortean nada.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                          % instante del gemelo, en minutos desde un origen fijo
fuente(Fuente, Tipo).                   % Tipo: mercado | fix
cotizacion(Fuente, Valor, Minuto).      % lectura en pesos por dólar, con su instante
rango(Variable, Minimo, Maximo).        % lo plausible; los valores los define el estudiante
mercado(Estado, Desde).                 % Estado: abierto | cerrado
habil(Desde, Hasta).                    % intervalo de minutos que es día hábil (lo fija el estudiante)
estado_fuente(Fuente, Estado, Desde).   % Estado: responde | caida
cuota(Fuente, Usadas, Limite).          % peticiones gastadas y permitidas en el periodo
periodo_cuota(Fuente, Inicio, Fin).     % cuándo se reinicia la cuota
oferta(Casa, Compra, Venta, Minuto).    % lo que una casa de cambio publicó y cuándo
alerta(Alerta, Usuario, Fuente, Condicion, Umbral).  % Condicion: baja_de | sube_de
evento(Alerta, Suceso, Minuto).         % Suceso: creada | pausada | reanudada | aviso_enviado | entrega_confirmada | entrega_fallida
```

El cruce, el «ya avisó», la alerta armada y la cotización vigente no son hechos: se
deducen de los demás.

## Contrato del gemelo

- `decide(+Entidad, -Decision, -Explicacion)` — predicado central. La entidad es una
  sola: una alerta (¿avisar?), una fuente (¿consultarla?, ¿cuál es la cotización
  vigente?) o la oferta de una casa (¿es creíble?, ¿a quién conviene?). `Decision` es la
  determinación (avisar, no avisar o no se sabe; consultar o servir lo guardado marcado
  como atrasado; oferta recomendada, descartada o no avalable) e incluye las
  alternativas al pedir más soluciones (por ejemplo, las demás ofertas elegibles en
  orden). `Explicacion` es una lista de hechos y reglas que la justifican, y distingue
  lo sabido, lo inferido y lo ignorado.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (cotización
  obsoleta, cruce válido, rebote, alerta armada, salto brusco, cuota en riesgo, oferta
  incongruente, aviso dudoso), consultables en cualquier dirección: dada una entidad, sus
  situaciones; dada una situación, qué entidades la cumplen.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- Toda inferencia (por ejemplo, una cotización vigente escogida entre dos fuentes
  que discrepan) se marca como inferencia y cita los hechos que la sustentan.
- La API expone al menos: la cotización vigente con su edad y su fuente, el estado de las
  alertas, la decisión con su explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Cotización actual.** Con las dos fuentes de acuerdo y recientes, la vigente se
   entrega con su fuente y su edad. Un valor absurdo no se elige aunque sea el más
   reciente. Un sábado con el mercado cerrado, el último valor del viernes sigue
   vigente; la misma edad con el mercado abierto lo vuelve obsoleto y se marca. Con dos
   fuentes que discrepan y sin razón para descartar ninguna, la respuesta es «no se
   sabe», no una de las dos al azar.
2. **Rebote.** Un cruce con una cotización vigente en una alerta armada produce un
   aviso. Los cruces siguientes sin rearmar no producen otro, y la explicación nombra el
   aviso anterior. Cuando se rearma, el siguiente cruce sí avisa. Un cero o un valor
   absurdo, aunque «cruce» cualquier umbral, no dispara ninguna alerta.
3. **Salto y cuota.** Con salto brusco y cuota disponible, se consulta la fuente que
   conviene; con la cuota casi agotada, el gemelo decide entre gastar o servir lo
   guardado, y lo servido lleva la marca de atrasado. La explicación nombra el choque
   entre urgencia y cuota, y la consulta inversa dice qué tendría que cambiar.
4. **Casa de cambio.** Una oferta con la compra por encima de la venta, o vieja frente a
   un salto, no se recomienda aunque tenga el mejor precio, y la razón queda dicha. El
   «mejor» depende de si el usuario vende o compra dólares. El spread normal cambia en
   un salto. Un empate se resuelve por un criterio declarado, no al azar. Si ninguna es
   creíble, la respuesta es «no se sabe».
5. **Rendición de cuentas.** Una alerta que debió sonar y no sonó da su causa; una que no
   debía sonar dice por qué; un aviso enviado sin confirmación da «no se sabe». La
   respuesta usa lo que se sabía en el instante reclamado, no lo posterior. La consulta
   al revés dice qué habría tenido que ocurrir para que el aviso saliera.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar la cotización vigente con
su fuente, su edad y su marca (vigente, obsoleta o «no se sabe»), el estado de cada
alerta, las ofertas de las casas con las creíbles y las descartadas, la cuota de cada
fuente, la decisión con su explicación y la respuesta a «qué falta». Debe verse bien en
celular.
