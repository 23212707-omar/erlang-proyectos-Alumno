# Contexto para agentes — gemelo digital del proyecto #62 (Billetera virtual)

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
| Movimiento | Línea inmutable de la bitácora: cuenta, monto entero en centavos, instante |
| Saldo | Suma de los movimientos de una cuenta; no es un campo que se sobreescribe |
| Partida doble | Toda transferencia es un débito y un crédito por el mismo monto; el sistema suma cero |
| Doble gasto | Dos operaciones leen el mismo saldo y ambas lo gastan |
| Clave de idempotencia | Identificador único por operación; distingue un reintento de una operación nueva |
| Pendiente | Transferencia a un banco externo que aún no se confirma ni se devuelve |
| Nivel de cuenta / verificación | Datos que determinan el límite aplicable (el estudiante fija los valores) |
| Comprometido | Dinero que ya salió del saldo pero cuya transferencia no termina (término del ejercicio) |
| Conciliación | Demostrar que la suma de saldos coincide con los movimientos |

Cifras de referencia: 100 pesos de saldo con dos transferencias simultáneas de 80;
"enviar 200 pesos" que llega 2 o 3 veces por mala señal; transferencias externas que
tardan minutos; 10,000 cuentas; 50 transferencias por segundo; 5 % con reintento; 100
operaciones simultáneas contra una cuenta con saldo insuficiente; SPEI las 24 horas, todos
los días; dinero siempre en enteros (centavos). Los nombres de personas y bancos, los
límites por nivel y los números de ejemplo son del ejercicio, no cifras reales.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar solicitudes simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Si la simulación necesita azar (una caída, un banco mudo, un reintento), el valor entra
  como hecho; las reglas no sortean nada.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                          % instante del gemelo, en minutos desde un origen fijo
cuenta(Cuenta, Titular, Nivel).         % incluye la cuenta del sistema; Nivel lo define el estudiante
verificacion(Titular, Estado, Minuto).  % Estado: aprobada | pendiente | vencida; desde cuándo
limite(Nivel, Concepto, Centavos).      % Concepto: p. ej. por_operacion | por_dia; valores del estudiante
dia(Inicio, Fin).                       % intervalo de minutos que cuenta como «hoy»
movimiento(Id, Cuenta, Centavos, Transferencia, Minuto).  % entero con signo; inmutable
solicitud(Id, Clave, Origen, Destino, Centavos, Llegada, Orden).  % Destino: cuenta | externo(Banco); Orden: lugar en la bitácora
evento(Transferencia, Suceso, Minuto).  % Suceso: recibida | debito | credito | enviada_banco | confirmada | devuelta | rechazada | reintento
banco(Banco, Estado, Desde).            % Estado: responde | sin_respuesta
```

La etapa de una transferencia, el saldo, lo comprometido, el reintento, el acumulado del
día y la transferencia a medias no son hechos: se deducen de los demás.

## Contrato del gemelo

- `decide(+Entidad, -Decision, -Explicacion)` — predicado central. La entidad es una
  sola: una solicitud (¿aceptar?, ¿es un reintento?, ¿qué límite aplica?) o una
  transferencia (¿en qué etapa está?, ¿qué sigue?, ¿cómo se repara?). `Decision` es la
  determinación (aceptar, rechazar o exigir una acción; reintento, operación nueva, clave
  reutilizada o no se sabe; aplicar, ignorar o marcar imposible un aviso; completar,
  compensar o no se sabe) e incluye el siguiente paso o la secuencia válida, con las
  alternativas al pedir más soluciones. `Explicacion` es una lista de hechos y reglas
  que la justifican, y distingue lo sabido, lo inferido y lo ignorado.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (saldo
  disponible, dinero comprometido, reintento, etapa de la transferencia, límite
  excedido, transferencia a medias, desviación de la suma), consultables en cualquier
  dirección: dada una entidad, sus situaciones; dada una situación, qué entidades la
  cumplen.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- Toda inferencia (por ejemplo, una etapa deducida de sucesos incompletos) se marca como
  inferencia y cita los hechos que la sustentan.
- La API expone al menos: el saldo y lo comprometido de cada cuenta, la etapa de cada
  transferencia, la decisión con su explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Doble gasto.** Con dos órdenes que no caben en el saldo, una se acepta y la otra se
   rechaza, y la explicación dice cuál criterio de orden se usó y con qué saldo se
   evaluó. Con dinero comprometido por una transferencia pendiente, el saldo que cuenta
   es menor que el de los movimientos, y si lo que queda no alcanza para ninguna de las
   dos, ninguna pasa.
   Si los hechos no permiten ordenarlas, el veredicto es «no se sabe», no una elección
   al azar.
2. **Reintento.** La misma clave y el mismo contenido son un reintento: se devuelve el
   resultado original y no se crea ningún movimiento. La misma clave con otro monto se
   marca como clave reutilizada y no mueve dinero. Una clave nueva con todo lo demás
   igual jamás se descarta como reintento: es operación nueva marcada como posible
   duplicado, o «no se sabe». Para el reintento de una operación rechazada, el gemelo
   declara su política y la explicación la cita.
3. **Transferencia externa.** Cada aviso del banco se acepta solo si la secuencia lo
   permite; una confirmación repetida no mueve dinero otra vez; una devolución después de
   una confirmación se marca como imposible. Con el banco sin respuesta, la etapa es
   «no se sabe», el dinero comprometido sigue comprometido y no se libera por el solo
   paso del tiempo. El gasto de Ana nunca usa lo comprometido.
4. **Límites.** Lo ya enviado hoy se calcula de los movimientos, y la explicación dice
   cuáles contaron y cuáles no. Una verificación vencida cambia el veredicto frente a la
   misma operación con verificación aprobada. Sin dato de verificación el resultado es
   «no se sabe», nunca permitir por omisión. La consulta inversa dice qué tendría que
   cambiar (el monto, la verificación o el día) para que la operación pase.
5. **Caída y conciliación.** Una transferencia con débito sin crédito y una con crédito
   sin débito se detectan y se distinguen. Nunca se propone borrar un movimiento: la
   salida es completar o compensar con uno nuevo, y si el destino fue bloqueado la
   explicación nombra el dilema. La desviación de la suma del sistema se explica con las
   transferencias que la causan; si no hay causa identificable, «no se sabe».
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el saldo y lo comprometido
de cada cuenta, las transferencias con su etapa (y las que están a medias), las
solicitudes con su veredicto (aceptada, rechazada, reintento, no se sabe), el límite del
día con su margen, la desviación de la conciliación, la decisión con su explicación y la
respuesta a «qué falta». Debe verse bien en celular.
