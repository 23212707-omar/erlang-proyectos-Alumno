# Contexto para agentes — gemelo digital del proyecto #59 (Punto de venta)

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
  se marca como supuesto y se le pide al estudiante la fuente. Las promociones, cupones,
  topes, roles y la sucursal del interior son del ejercicio, no de una tienda real.

## Dominio

| Término | Significado |
|---|---|
| Ticket | Comprobante de una venta: partidas, descuentos, impuestos, total y formas de pago |
| Partida | Renglón del ticket: un producto, su cantidad y su precio |
| IVA | General de 16 %; en la región fronteriza el decreto de estímulo ha permitido 8 % (vigencia por verificar) |
| CFDI 4.0 / PAC | Factura electrónica y proveedor autorizado que la timbra; si el timbrado falla, la venta ya ocurrió y la factura se emite después |
| Pago mixto | Un mismo ticket pagado con varias formas: efectivo, tarjeta, dólares |
| Terminal bancaria | Aparato de cobro con tarjeta; puede fallar a mitad de un cobro |
| Redondeo por partida o por total | Dos maneras de redondear que pueden diferir en centavos |
| Corte de caja | Conciliación por turno y por cajero del efectivo contado contra el esperado |
| Venta en proceso | Cobro iniciado sin desenlace conocido al momento del corte |
| Promoción, cupón, tope | Complemento del ejercicio: descuentos con condiciones, de un solo uso o con límite por rol |
| Autorización | Complemento: permiso de un gerente, con su instante, para pasar un tope |

Cifras de referencia (del original): IVA de 16 % y de 8 % en la región fronteriza
(vigencia por verificar); CFDI versión 4.0; 4 cajas, 600 tickets al día y 800 productos
en el escenario; 200-1,000 tickets diarios con 2-6 cajas y ~1-2 minutos por cliente en
hora pico. Marcados como del ejercicio, sin cifras: la sucursal del interior, el número
de cajas, turnos y tickets de la escala reducida, las promociones y cupones, los topes,
los roles, el plazo para cancelar y cuándo una diferencia de corte es «pequeña».

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Si la simulación necesita azar (una terminal que no responde, un tipo de cambio que
  se mueve), el valor entra como hecho; las reglas no sortean nada.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                          % instante del gemelo, en minutos desde un origen fijo
sucursal(Sucursal, Zona).               % Zona: frontera | interior
turno(Turno, Caja, Cajero, Apertura, Cierre).  % Cierre: un minuto, o abierto
rol(Persona, Rol).                      % Rol: cajero | gerente
ticket(Ticket, Turno, ClaveEnvio).      % ClaveEnvio: la que lleva el envío de la venta por la red
partida(Ticket, Producto, Cantidad, PrecioUnitario).
promocion(Promocion, Producto, Tipo).   % Tipo: promocion | cupon | cortesia (condiciones: las defines)
pago(Ticket, Forma, Moneda, Monto).     % Forma: efectivo | tarjeta; Moneda: mxn | usd
tipo_cambio(Moneda, Valor, Minuto).     % cotización registrada con su instante
estimulo(Tasa, Desde, Hasta, Confirmado). % vigencia del estímulo y minuto en que se confirmó
evento(Ticket, Suceso, Minuto).         % Suceso: abierto | cobro_enviado | aprobado | rechazado | sin_respuesta | timbrado | timbrado_fallido | cancelado | devuelto
conteo(Turno, Tipo, Moneda, Monto).     % Tipo: fondo | retiro | contado
```

## Contrato del gemelo

- `decide(+Entidad, -Decision, -Explicacion)` — predicado central. La entidad es una
  sola: un ticket (venta, tasa, descuentos, cancelación) o un turno (corte). `Decision`
  es la determinación (la venta ocurrió, no ocurrió o no se sabe; los descuentos
  aplicados y los descartados; la tasa y el desglose; si procede la cancelación y en qué
  corte se anota; si el corte cuadra, no cuadra o no se sabe) e incluye el siguiente
  paso válido de la venta. Al pedir más soluciones debe dar las demás alternativas
  válidas. `Explicacion` es una lista de hechos, eventos y reglas que la justifican, y
  distingue lo sabido, lo inferido y lo ignorado.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (cobro dudoso,
  reintento duplicado, venta ocurrida, tasa dudosa, descuento no elegible, tope
  excedido, corte pendiente, historia imposible), consultables en cualquier dirección:
  dada una entidad, sus situaciones; dada una situación, qué entidades la cumplen.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- Toda inferencia (por ejemplo, una tasa deducida sin confirmación vigente) se marca como
  inferencia y cita los hechos que la sustentan; nunca se presenta como un dato.
- La API expone al menos: el estado de tickets y turnos, la decisión con su explicación,
  el historial de eventos de un ticket y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Venta a medias.** Un cobro con tarjeta sin respuesta y un cargo que la clienta
   asegura da «no se sabe» y no «ocurrió» ni «no ocurrió». Dos envíos con la misma
   clave se tratan como un solo cobro repetido; dos envíos con claves distintas no se
   asumen iguales. La respuesta dice qué evidencia resolvería la duda y a quién se le
   falla con cada salida. El efectivo recibido no se pierde ni se da por vendido.
2. **Cancelación de ayer.** La cancelación de un ticket de un turno ya cerrado no
   modifica ese corte: el movimiento aparece en el turno actual, se devuelve con la
   tasa y el tipo de cambio del ticket original y requiere la autorización que
   corresponda. La explicación recorre toda la cadena. Con timbrado pendiente la
   respuesta cambia y dice en qué.
3. **Tasa.** La misma partida lleva tasa distinta según zona y fecha de la venta. Si la
   vigencia no está confirmada, la respuesta es «no lo sé» con qué confirmar y a quién
   se le falla, no una tasa asumida. Un ticket que cruza el cambio de vigencia se
   explica por el instante en que la venta ocurre. Los dos redondeos se comparan y la
   diferencia de centavos se atribuye a la causa.
4. **Descuentos.** Una promoción y un cupón sobre la misma partida producen un
   resultado único con el descartado y su razón. Un cupón de un solo uso presentado en
   dos cajas no se aplica dos veces. Un descuento sobre el tope del rol sin una
   autorización vigente no se aplica, y la respuesta dice quién puede darla. El orden
   respecto del IVA queda explicado.
5. **Corte.** El esperado se deduce por moneda; una venta en proceso vuelve la respuesta
   «no se sabe todavía», no «no cuadra». La diferencia se parte en causas y lo que no
   se explica queda a la vista. Comparar todo en una moneda convertida al cierre no
   produce una diferencia falsa en la respuesta del gemelo.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar las cajas con sus tickets
y turnos, la decisión con su explicación, el historial de eventos de un ticket, el
corte por moneda con la diferencia partida en causas y la respuesta a «qué falta».
Debe distinguir a la vista lo sabido de lo inferido y de lo que no se sabe, y verse bien
en celular.
