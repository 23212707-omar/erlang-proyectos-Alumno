# Contexto para agentes — gemelo digital del proyecto #66 (Mercado de abastos / tianguis)

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
| Locatario | Dueño de un puesto del mercado; fija sus precios y sabe qué le queda |
| Pasillo | Zona del mercado donde están varios puestos; ordena los recorridos |
| Pedido | Compra de un cliente que puede incluir líneas de varios locatarios |
| Línea | Un producto, una cantidad y un precio dentro de un pedido, con su locatario |
| Surtir | Apartar existencia de un locatario para una línea |
| Pedido parcial | Pedido al que le falta al menos una línea; puede entregarse o cancelarse |
| Repartidor | Quien recoge en los puestos y entrega; va en moto o en bicicleta |
| Lote | Tanda de un producto perecedero con su día de llegada |
| Precio visto / vigente | El que se le mostró al cliente / el que rige en un instante dado |
| Pago mixto | Parte por transferencia y parte en efectivo |

Cifras de referencia, todas del problema original: hojas verdes duran 2-3 días y fresa
3-5; 100 locatarios, 20 repartidores y 300 pedidos entre 7 y 11 a. m.; un locatario sin
tomate con 12 pedidos que lo incluyen; un repartidor retrasado con un pedido de 4
locatarios; espera de 30 minutos en un puesto como problema a evitar.

Términos y números del escenario reducido (6 locatarios, 3 pasillos, 3 repartidores,
unos 10 pedidos, minutos de camino y de preparación, días de llegada de los lotes): son
del ejercicio, no hechos del mundo. No los presentes como datos reales.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar pedidos simulados o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                              % minutos desde las 7:00 del día
locatario(Locatario, Pasillo).
repartidor(Repartidor, Vehiculo).           % Vehiculo: moto | bicicleta
pedido(Pedido, Cliente, MinutoLlegada).
linea(Pedido, Locatario, Producto, Cantidad, PrecioVisto, MinutoVisto).
existencia(Locatario, Producto, Cantidad).
precio(Locatario, Producto, Monto, MinutoCambio, MinutoRegistro).  % cuándo y cuándo se supo
lote(Lote, Locatario, Producto, DiaLlegada). % DiaLlegada: 0 hoy, negativo antes; puede faltar
camino(Punto1, Punto2, Minutos).
pago(Pedido, Medio, Monto, Minuto).         % Medio: efectivo | transferencia
evento(Entidad, Suceso, Minuto).            % listo, recogido, agotado, retrasado...
```

Sin reglas aquí. Si el dominio pide algo aleatorio (qué tanto tarda un puesto en
preparar), no se sortea: el valor entra como hecho o queda como supuesto del estudiante.
Si el cliente acepta entrega parcial o la edad de un lote falta, el estudiante decide
cómo se representa, sin renombrar los hechos de arriba.

## Contrato del gemelo

- `decide(+Pedidos, -Reparto, -Explicacion)` — predicado central. `Pedidos` es una lista
  de pedidos (puede ser de uno); `Reparto` es el reparto completo: qué existencia va a
  cada pedido, qué repartidor lo lleva y en qué orden pasa por los puestos;
  `Explicacion` justifica cada pieza. Al pedir más soluciones debe dar los demás repartos
  válidos. Si no existe ninguno (no alcanza la existencia, no hay repartidor), lo dice y
  señala el motivo, sin fallar en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre un pedido,
  un locatario, un lote o un repartidor (por ejemplo pedido parcial, espera excesiva,
  precio en disputa, lote vencido al llegar), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de pedidos y puestos, el reparto con su explicación
  y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Escasez.** Con más pedidos que existencia, el gemelo reparte lo que hay, nunca
   promete más de lo que existe y dice a qué pedidos les falla y por qué; con varias
   formas válidas de repartir, las da todas. Un pedido que ya pagó y uno que paga al
   recibir no se tratan igual sin que la explicación lo diga.
2. **Pedido parcial.** Con la misma línea faltante, el veredicto cambia según la
   aceptación de la cliente, el medio de pago y si lo recogido es perecedero, y la
   explicación muestra la cadena. La consulta inversa dice qué habría cambiado el
   veredicto.
3. **Repartidores.** Cada pedido tiene un repartidor y un orden de paradas; la espera por
   parada se calcula, no se supone. Un orden por simple cercanía que produce más espera
   que otro válido no es la respuesta. Si el retraso de un repartidor lo exige, el gemelo
   reasigna y lo explica; si no hay forma, lo dice.
4. **Precio.** Un cambio de precio registrado antes del pago y uno registrado después no
   dan el mismo cobro, y la explicación dice quién absorbe la diferencia. Cuando el orden
   de los instantes no se puede establecer, la respuesta es «no se sabe» con lo que
   faltaría, distinta de «no cambió».
5. **Frescura.** La vida restante de un lote al llegar con la cliente se deduce de su día,
   su producto y el tiempo del viaje; un lote sin día de llegada da «no se sabe», nunca
   «fresco» ni «vencido», y no se asigna como si fuera seguro. El lote más viejo no gana
   por viejo si su viaje lo entrega pasado.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar los pedidos con su estado
y sus líneas (incluidas las que fallan), los puestos con su existencia, los repartidores
con su recorrido y su espera por parada, y el reparto propuesto con su explicación y la
respuesta a «qué falta». Los «no se sabe» deben verse distintos de los «no». Debe verse
bien en celular, con letra grande: el mercado es ruidoso, con mala conectividad y sus
usuarios no son técnicos.
