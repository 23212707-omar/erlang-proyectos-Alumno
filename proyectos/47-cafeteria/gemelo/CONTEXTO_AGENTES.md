# Contexto para agentes — gemelo digital del proyecto #47 (Cafetería)

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
  (tiempo exacto de cada producto dentro de su rango, margen de una promesa, cambios de
  componente admisibles, criterio de prioridad y de desempate, antigüedad máxima de un
  conteo, espera antes de dar un pedido por no recogido, capacidad de una estación) se
  marca como supuesto y se le pide al estudiante la fuente.
- Es un ejercicio con datos simulados, no el sistema de una cafetería real.

## Dominio

| Término | Significado |
|---|---|
| Estación | Punto de la cocina que prepara ciertos productos y tiene su propia cola |
| Pedido anticipado / de mostrador | El que se hace antes de llegar / el que se hace en la barra |
| Tiempo prometido | Lo que se le dijo al cliente; es una promesa, no una estimación interna |
| 86 | Producto agotado; no se debe aceptar en pedidos nuevos |
| Combo | Conjunto de productos que se vende como una unidad; no está listo hasta que lo está su última parte |
| Comprometido | Unidad que existe pero ya está apartada para un pedido pagado |
| Aviso | Mensaje al cliente de que su pedido está listo; puede constar como enviado o confirmado |
| Monedero | Saldo de la escuela con el que se paga; lo lleva otro sistema y confirma después |
| Ley de Little | Personas en el sistema = tasa de llegada × tiempo en el sistema |

Cifras de referencia (todas del problema original): descanso de 30 a 45 minutos; mostrador
de 1 a 2 clientes por minuto; 400 personas en 40 minutos (unos 10 por minuto); 10 por
minuto con 6 minutos da unas 60 personas; café 1 min, torta 4-5 min, comida caliente 6-10
min; 400 pedidos, 3 estaciones y 30 productos; el platillo más popular se agota a los 15
minutos. Son órdenes de magnitud. Marcadas como inventadas por esta extensión: la escala
reducida (unos 8 productos, 2 combos, una docena de pedidos), la composición de los combos,
los conteos de existencias con su instante, los avisos con estado, el descanso restante de
cada cliente y el saldo del monedero.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar pedidos simulados o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Si el escenario necesita azar (qué pedido llega primero, cuánto tarda de verdad una
  torta dentro de su rango), entra como hecho, no se sortea.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                                   % instante del modelo, en minutos
estacion(Estacion, Producto).                    % qué producto prepara cada estación
producto(Producto, MinimoMin, MaximoMin).        % rango de preparación, en minutos
combo(Combo, Producto).                          % un hecho por componente
existencia(Producto, Cantidad, Minuto).          % conteo físico y cuándo se hizo
pedido(Pedido, Cliente, Origen, Minuto).         % Origen: anticipado | mostrador
linea(Pedido, Item, Cantidad).                   % Item: un producto o un combo
pago(Pedido, Medio, Estado, Minuto).             % efectivo | tarjeta | saldo; pendiente | confirmado | rechazado
prometido(Pedido, Minuto).                       % instante en que se dijo que estaría listo
evento_pedido(Pedido, Evento, Minuto).           % recibido | preparando(Estacion) | listo | avisado | aviso_confirmado | entregado | cancelado
ventana(Cliente, Desde, Hasta).                  % lapso de descanso del que dispone el cliente
politica(Nombre, Valor).                         % margen, antigüedad de conteo, espera...; los fija el estudiante
```

## Contrato del gemelo

- `decide(+Caso, -Decision, -Explicacion)` — predicado central. `Caso` es un pedido, un
  par pedido-producto o un producto; los demás pedidos, existencias, pagos y avisos entran
  como hechos. `Decision` dice el veredicto (se puede surtir, se surte con cambio, no se
  puede; tiempo a prometer con su rango; turno y a quién se le rompe la promesa; conservar,
  reasignar o dar por perdido; preparar, retener o cancelar; o «no se sabe»). Al pedir más
  soluciones, da las demás decisiones que también serían defendibles con los datos, en su
  orden de conveniencia. `Explicacion` es una lista de hechos y condiciones que justifican
  la decisión, incluida la parte a la que se le falla.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (unidades
  realmente disponibles, combo incompleto, pedido pagado sin surtir, promesa en riesgo o
  imposible, pedido salvable, pedido no recogido, aviso sin constancia, pedido sin
  respaldo de pago), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe. Un dato
  ausente (conteo viejo, aviso sin confirmar, pago pendiente) nunca cuenta como «no».
- La API expone al menos: el estado de la cola por estación y de cada pedido, la decisión
  con su explicación, la lista de pedidos pagados sin surtir, las promesas en riesgo y
  «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Disponibilidad.** Con unidades físicas todas apartadas, el producto no cuenta como
   disponible y un combo que lo lleva no se puede completar. El pedido afectado sale como
   «no se puede surtir» o «se puede con cambio», nombra qué lo causó y a quién se le falla.
   Con un conteo más viejo que el margen elegido, el resultado es «no se sabe» y se pide
   recontar, no «agotado».
2. **Tiempo prometido.** El tiempo de un pedido depende de las estaciones que usa y de lo
   que hay delante en cada una; un combo tarda lo que su última parte. La respuesta da un
   rango y distingue lo seguro de lo posible. Si la cocina se retrasa, las promesas
   afectadas se señalan para re-prometer, y la que no cabe en el descanso del cliente lo
   dice.
3. **Prioridad.** Con una estación saturada y otra libre, el gemelo ordena la atención y
   nombra a quién se le rompe la promesa; ni el orden de llegada ni el pedido más corto
   deciden por sí solos. La explicación sirve igual al cliente y a la barra, y la consulta
   inversa dice qué tendría que cambiar para que nadie quede fallado.
4. **No recogido.** Un pedido sin recoger cuyo aviso no consta como confirmado no se da
   por abandonado: sale «no se sabe» o «conservar». Si el aviso consta y pasó el plazo, el
   pedido puede reasignarse a quien espera ese producto, y la respuesta dice qué se le debe
   al cliente según cómo pagó.
5. **Pago y cocina.** Con saldo para uno solo de dos pedidos, el gemelo dice cuál tiene
   respaldo, cuál no y quién asume el costo de lo ya preparado. Un pago pendiente da «no se
   sabe», distinto de «rechazado», y nunca cancela ni libera por sí solo.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar la cola de cada estación con
los pedidos y su tiempo prometido, los productos con su disponibilidad real (y los que no
se sabe), los pedidos pagados sin surtir con las salidas posibles, los pedidos sin recoger
con el estado de su aviso, el estado de pago de cada pedido y la respuesta a «qué falta».
Debe verse bien en celular.
