# Contexto para agentes — gemelo digital del proyecto #18 (Subasta o reservas)

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
- Las políticas de la casa (incremento mínimo, lectura de la frontera, extensión del
  cierre, desempate, empate de máximos, duración del hold, peso del sello del banco) no
  vienen del original: las define el estudiante y las declara como supuestos.
  Pregúntaselas; no las decidas tú.

## Dominio

| Término | Significado |
|---|---|
| Subasta | Venta de un lote al mejor postor, con un cierre |
| Puja | Oferta de un postor por un lote, con monto e instante de llegada |
| Incremento mínimo | Lo que una puja debe superar al precio actual para ser válida |
| Puja automática | El sistema puja por el postor hasta un máximo que solo él conoce |
| Cierre publicado / efectivo | El que dice la página / el que resulta tras las extensiones |
| Soft close | Extender el cierre unos minutos si llega una puja tardía |
| Sniping | Pujar en los últimos segundos para que nadie alcance a responder |
| Hold | Reserva temporal de un lugar; se libera si no se paga a tiempo |
| Cupo | Lugares totales de un evento |
| Reintento | Reenvío de la misma puja por mala red; lleva una clave de reintento |
| Bitácora | Registro numerado e inalterable de eventos; un hueco en la numeración es dato |
| Sello del banco | Hora en que el banco aprobó el pago, distinta de la hora en que se registró |

Cifras de referencia, todas del problema original: cierre extendido de 2 a 5 minutos;
hold de 5 a 15 minutos; 200 subastas activas; 500 postores; 300 pujas en los últimos 10
segundos; 50 personas por 5 lugares; reinicio 30 segundos antes del cierre; pujas
estrictamente mayores a la actual más un incremento mínimo. Los nombres, lotes y
cantidades de los ejemplos de `PROBLEMA.md` son ilustrativos, no datos.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar pujas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  El gemelo no sortea desempates ni genera ids: razona sobre pujas y pagos que entran
  como hechos.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Milisegundo).                     % ms desde el inicio del escenario
subasta(Subasta, Lote, CierrePublicado).
politica(Ambito, Parametro, Valor).     % incremento, extension, duracion de hold...
puja(Puja, Subasta, Postor, Monto, Clave, Milisegundo).   % Clave: de reintento
puja_auto(Postor, Subasta, Maximo, Milisegundo).          % el Maximo es secreto
cupo(Evento, Lugares).
solicitud(Solicitud, Evento, Persona, Milisegundo).       % orden de llegada
hold(Hold, Solicitud, Inicio, Duracion).
pago(Pago, Hold, Registro).             % hora en que la plataforma lo anotó
sello_banco(Pago, Milisegundo).         % puede no existir: no es lo mismo que cero
evento(Numero, Sujeto, Evento, Milisegundo).  % bitácora: reinicio, liberado, cancelado...
```

El precio actual, el líder, el cierre efectivo, la validez de una puja, cuántos lugares
quedan y quién tiene un lugar **no son hechos**: se deducen. Si hay azar, entra como
hecho o como supuesto del estudiante.

## Contrato del gemelo

- `decide(+Entidad, -Decision, -Explicacion)` — predicado central. `Entidad` es una puja,
  una subasta, un evento o un hold, y `Decision` cambia según el caso: puja aceptada,
  rechazada, repetida o dudosa; ganador y precio de una subasta; reparto de los lugares
  de un evento. Al pedir más soluciones da las demás lecturas posibles cuando los datos
  admiten varias historias (por ejemplo, si un pago llegó a tiempo o no), cada una con
  a quién favorece; y si no existe ninguna lo dice y señala el motivo, sin fallar en
  silencio. `Explicacion` es una lista de hechos, condiciones y políticas, incluida la
  regla que perdió cuando hubo conflicto y a quién se le falla. Debe poder entregarse
  completa (auditor) y sin lo secreto (postor).
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo cierre
  movido por una puja, líder oculto detrás de un máximo, lugar con dos pretendientes,
  puja repetida, hueco de bitácora), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado deducido de subastas y eventos, la decisión con su
  explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus políticas.

1. **Empate.** Dos pujas iguales en el mismo milisegundo reciben respuestas distintas y la
   explicación nombra el desempate usado y a quién se le falla. La puja de la frontera
   se trata como el estudiante declaró su lectura, de forma coherente en todas las
   consultas. La consulta inversa dice qué tendría que cambiar para que ganara el otro.
2. **Cierre.** El cierre efectivo se deduce de las pujas válidas y cambia si se quita
   una. Una puja inválida no mueve el cierre; una posterior a la hora publicada puede
   contar y una anterior puede no hacerlo. Cada reclamación recibe «procede» o «no
   procede» con su cadena de razones.
3. **Máximo secreto.** El líder y el precio se obtienen en cualquier instante sin que
   ningún hecho los guarde. La explicación completa muestra el máximo; la pública no lo
   muestra, pero sigue siendo suficiente para entender el resultado. Quien más ofreció no
   se da por pagando su oferta sin comprobarlo.
4. **Hold y pago.** Los lugares disponibles se deducen de cupo, pagos y holds vigentes.
   Un pago registrado después del vencimiento, con sello anterior, no se da por tarde ni
   por a tiempo: se enumeran las lecturas y a quién favorece cada una. Un pago sin sello
   da «no se sabe». La explicación dice a quién se le falla.
5. **Reintento y reinicio.** Un reenvío con la misma clave no se cuenta como puja nueva
   ni se rechaza por bajo sin más. Con un hueco en la bitácora, la respuesta distingue
   «ya estaba registrada», «no se registró» y «no se sabe», con sus consecuencias para el
   ganador, y nombra la evidencia que decidiría.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar los lotes con su precio y
líder deducidos, el cierre publicado frente al efectivo, la línea de tiempo de la bitácora
con sus huecos marcados, los lugares del evento con sus holds y vencimientos, la
decisión con su explicación en vista pública y de auditoría, las lecturas alternativas
cuando haya duda y la respuesta a «qué falta». Debe verse bien en celular.
