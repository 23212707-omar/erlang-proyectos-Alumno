# Contexto para agentes — gemelo digital del proyecto #78 (Cultivo de fresa o tomate, San Quintín)

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
| Lote | Terreno de cultivo con sus surcos; unidad que se retira si hay contaminación |
| Surco | Hilera de plantas dentro de un lote; de ahí se corta |
| Cuadrilla | Grupo de jornaleros con un mayordomo, asignado a lotes y surcos |
| Destajo | Pago por caja o por kilo cosechado, en vez de por jornada |
| Caja | Unidad mínima de trazabilidad, con etiqueta QR |
| Tarima | Agrupación de cajas que se mueve como una sola pieza |
| Preenfriamiento | Enfriar la fruta rápido después del corte, en una cámara |
| Trazabilidad | Saber de cada caja lote, surco, fecha, cuadrilla y condiciones de cosecha |
| Captura tardía | Registro que llega después del corte por falta de señal |
| Retiro | Sacar del mercado el lote exacto bajo sospecha, no todo el producto |

Cifras de referencia, todas del problema original: preenfriamiento a ~1-4 °C en pocas
horas después de la cosecha, y cada hora de demora reduce la vida de anaquel; cuadrilla de
15-40 jornaleros con un mayordomo; pago a destajo o por jornada; escenario de 10 lotes,
12 cuadrillas de 30 personas y 5,000 cajas por jornada; una cuadrilla cuyos registros
llegan tres horas después; trazabilidad exigida por caja (lote, surco, fecha, cuadrilla y
condiciones de cosecha).

Marcado como del ejercicio, no del original: la escala de 4 lotes, 3 cuadrillas de 5
jornaleros, 2 cámaras y 2 camiones, y los identificadores de los ejemplos. El original no
da el tiempo máximo entre corte y frío ni el retraso aceptable de un registro: son
supuestos del estudiante.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar capturas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Si hay jitter en las lecturas, entra como hecho o como supuesto, no se sortea.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                         % minutos desde el inicio de la jornada
rango(Variable, Minimo, Maximo).       % rango físico posible: temperatura de la cámara
lectura(Camara, Variable, Valor, Minuto).      % temperatura de la cámara con su instante
surco(Surco, Lote).
asignacion(Cuadrilla, Surco, MinutoDesde).     % qué cuadrilla cosecha qué surco
jornalero(Jornalero, Cuadrilla).
captura(Id, Caja, Jornalero, Surco, MinutoCorte, MinutoRegistro).  % un hecho por captura
en_tarima(Caja, Tarima, Minuto).
ingreso_frio(Tarima, Camara, Minuto).
carga(Tarima, Camion, Minuto).
evento(Entidad, Tipo, Detalle, Minuto).        % sospecha de lote, retiro, aviso, reclamo
```

## Contrato del gemelo

- `decide(+Caja, -Decision, -Explicacion)` — predicado central. `Decision` dice qué se
  hace con esa caja (si cuenta y a quién se le acredita, si se retiene, si se retira, si se
  paga) y a quién avisar cuando corresponde. `Explicacion` es una lista de hechos y
  condiciones que justifican la decisión. Si la caja no se puede decidir, lo dice y señala
  el dato que falta, sin fallar en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  duplicada, procedencia de una tarima, alcanzada por un lote, fuera de límite de frío),
  consultables en cualquier dirección. La entidad puede ser una caja, una tarima, un
  camión, un lote o un jornalero.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de las cajas, la decisión con su explicación, lo que
  alcanza un lote sospechoso (hacia adelante) y el origen de una caja o tarima (hacia
  atrás), el pago por jornalero y cuadrilla, y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Doble captura.** Dos capturas de la misma caja producen una sola que cuenta, con el
   motivo de por qué esa y no la otra; un QR repetido en surcos distintos no se trata
   como duplicado simple; la captura que llegó primero al sistema no gana por eso cuando
   la otra tiene mejor sustento, y si no alcanza la información el veredicto es «no se
   sabe», no «cuenta» ni «no cuenta».
2. **Tarima mezclada.** Una tarima con cajas de dos lotes devuelve ambos lotes con las
   cajas que los sustentan; una caja conocida solo por su tarima no recibe un lote
   inventado; la consulta inversa lista las tarimas y camiones de un lote.
3. **Lote sospechoso.** Declarar un lote sospechoso devuelve lo alcanzado (surcos, cajas,
   tarimas, camiones, compradores a avisar) con la cadena que lo justifica, separa lo
   «posiblemente alcanzado» cuando falta un eslabón y dice qué dato lo resolvería. Todo
   lo que entra a la lista trae su razón en la explicación.
4. **Enfriamiento.** La misma tarima da «a tiempo», «fuera de límite» o «no se sabe» según
   las horas de corte y de ingreso y el estado de la cámara. Un registro atrasado no
   cambia la hora de corte; estar dentro de la cámara no equivale a estar frío; y la
   explicación dice en qué eslabón se perdió el tiempo.
5. **Pago.** Un registro tardío válido se paga igual que uno puntual; una caja duplicada,
   retenida o fuera de límite no se paga igual que una sana, y la explicación nombra la
   causa y quién la absorbe. Lo retenido por falta de dato se distingue de lo negado. La
   consulta inversa dice qué tendría que cambiar para que se pague.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar las cajas con su captura,
tarima y estado de enfriamiento, la decisión con su explicación, el rastreo de un lote
hacia adelante y de una caja hacia atrás, el pago por cuadrilla con lo retenido y por
qué, y la respuesta a «qué falta». Debe verse bien en celular: el mayordomo la consulta
en el campo.
