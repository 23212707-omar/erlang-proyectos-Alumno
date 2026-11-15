# Contexto para agentes — gemelo digital del proyecto #34 (Almacén / inventario)

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
| Número de parte | Artículo que se almacena; tiene una política de salida |
| Lote | Grupo de piezas de una parte que comparten recepción y, si aplica, caducidad |
| Ubicación | Lugar físico del almacén donde está un lote |
| FIFO | Primero en entrar, primero en salir |
| FEFO | Primero en caducar, primero en salir; para perecederos, químicos y medicamentos |
| Punto de reorden | Demanda diaria × tiempo de entrega + inventario de seguridad |
| Inventario de seguridad | Colchón por encima de la demanda durante la entrega |
| Cuarentena | Estado de un lote retenido: existe, pero no se puede prometer |
| Trazabilidad | Saber de qué lotes viene un lote y a qué clientes llegó |
| Conteo cíclico | Conteo físico de ubicaciones; la clase ABC decide la frecuencia |
| Reintento del escáner | El mismo movimiento capturado dos veces |
| Ajuste | Movimiento que corrige el saldo sin borrar la historia |

Cifras de referencia (del original): FIFO y FEFO; punto de reorden con el ejemplo
50 piezas/día × 6 días + 100 = 400; ~20 % de los artículos ≈ 80 % del valor; 5,000
números de parte, 8 operadores, 2,000 movimientos por turno; las últimas 30 piezas; el
conteo de 12 donde el sistema dice 40; exactitud de inventario de 60-70 % sin control
estricto. Marcado como de esta extensión: la escala de 6 partes, 4 ubicaciones y
3 operadores, los dos clientes (médico y automotriz) y los números de los ejemplos.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar movimientos simulados o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Los reintentos del escáner y las fallas de captura entran como hechos, no se sortean.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                            % minutos desde el inicio de la ventana del escenario
parte(Parte, Politica).                   % Politica: fifo | fefo
parametro_reorden(Parte, DemandaDiaria, DiasEntrega, Seguridad).
lote(Lote, Parte, Recibido, Caducidad).   % Recibido: minuto; Caducidad: minuto o sin_dato
estado_lote(Lote, Estado, Minuto).        % disponible | cuarentena | defectuoso, desde cuándo
movimiento(Id, Tipo, Lote, Cantidad, Ubicacion, Operador, Minuto). % entrada|salida|traspaso|ajuste
pedido(Pedido, Cliente, Parte, Cantidad, Minuto).
orden_en_camino(Orden, Parte, Cantidad, Llegada). % Llegada: minuto o sin_confirmar
conteo(Ubicacion, Lote, Cantidad, Minuto).
compone(LoteResultante, LoteOrigen).      % de qué lotes proviene otro lote
cliente(Cliente, Sector).                 % medico | automotriz
```

## Contrato del gemelo

- `decide(+Entidad, -Decision, -Explicacion)` — predicado central. `Entidad` es una
  parte, un pedido o un lote según la situación. `Decision` dice qué hacer (pedir o no
  pedir, qué reservar y de qué lote, qué retener o avisar, qué ajuste procede o que no se
  puede concluir); `Explicacion` es una lista de hechos y condiciones que lo justifican,
  y nombra al competidor cuando hay un pedido que pierde. Lo que ocurre con varios
  pedidos a la vez sale de consultar todos, sin un predicado aparte.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  parte bajo su punto de reorden, lote afectado por un defecto, movimiento sospechoso de
  duplicado, saldo sin explicar), consultables en cualquier dirección, incluida la
  trazabilidad hacia adelante y hacia atrás.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: las existencias por parte y ubicación con lo utilizable
  distinguido de lo retenido, la decisión con su explicación, la cadena de trazabilidad
  de un lote, el saldo reconstruido a un minuto dado y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Reabasto.** Una parte con mucho material en estante pero retenido o ya apartado
   aparece como «pedir», con la cadena que lo justifica; una parte bajo el punto con una
   orden segura en camino no. Una orden sin fecha confirmada da «no se sabe» y la
   explicación señala de qué depende. La consulta inversa dice qué tendría que cambiar.
2. **Últimas piezas.** Nunca se reserva más de lo utilizable ni la misma pieza a dos
   pedidos. Con el mismo estado inicial y el pedido médico por más piezas, el reparto
   cambia, y la explicación nombra la regla de prioridad o desempate y a quién se le
   falla. Un empate total también produce una respuesta explicada.
3. **Lote de salida.** En una parte FEFO sale primero lo que caduca antes, salvo que el
   cliente exija una vida restante que ese lote no cumple; en una parte FIFO sale lo
   recibido antes aunque otro caduque antes. Un lote sin fecha de caducidad da «no se
   sabe» y la respuesta dice qué dato lo resolvería.
4. **Trazabilidad.** El defecto alcanza a los lotes derivados aunque cambien de número,
   y la respuesta dice dónde está hoy cada uno y cuáles salieron después de la
   declaración. La consulta hacia atrás, desde un lote terminado, devuelve sus orígenes.
   Una porción traspasada sin escaneo de llegada da «no se sabe», no «en origen» ni
   «usada».
5. **Saldo.** El saldo se deduce de los movimientos; un ajuste corrige sin borrar nada.
   Dos movimientos iguales muy próximos aparecen como sospechosos de duplicado, y dos
   iguales muy separados no. La diferencia contra un conteo se divide en lo explicado y
   lo no explicado (este último, «no se sabe»). El saldo a un minuto pasado cambia si se
   quita el movimiento duplicado, con las mismas reglas.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar, por parte, lo físico
distinguido de lo utilizable, retenido y apartado; la decisión de reabasto con su
explicación; los pedidos en disputa con el reparto y a quién se le falló; los lotes
por orden de salida con los inelegibles y los «no se sabe» marcados; el árbol de
trazabilidad de un lote con su ubicación o cliente actual; el saldo con sus diferencias
contra el conteo y un selector de minuto pasado; y la respuesta a «qué falta». Debe
verse bien en celular.
