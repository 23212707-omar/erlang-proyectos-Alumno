# Contexto para agentes — gemelo digital del proyecto #63 (Reservas de hotel)

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
| Tipo | Categoría de habitación que se vende (sencilla, doble, suite) |
| Habitación física | Cuarto concreto; se asigna normalmente al check-in |
| Noche | Unidad de inventario: una reserva ocupa un tipo noche por noche |
| Rango | Llegada y salida; el día de salida es el de check-out (12:00) |
| Retención | Reserva «en proceso» mientras el cliente paga; ocupa cupo mientras dure |
| Sobreventa | Vender por encima de la capacidad contando con cancelaciones y no-shows |
| Capacidad efectiva | Lo que de verdad se puede vender: cuartos menos los fuera de servicio |
| Reubicación | Lo que el hotel ofrece cuando llegan más huéspedes que cuartos |
| Agencia en línea | Canal que consulta disponibilidad muchas veces por reserva real |
| Ventana gratuita | Tiempo en que cancelar no cuesta (hasta 48 h antes) |

Cifras de referencia, todas del problema original: check-in 15:00 y check-out 12:00;
retención de 10-15 min; cancelación gratuita hasta 48 h antes; sobreventa de 3-10 % por
encima de capacidad; 55-75 % de ocupación anual y 95-100 % en picos; 80-200 habitaciones
en 3-5 tipos; escenario de 120 habitaciones, 4 tipos y 90 días, con 90 % de las noches
vendidas en la convención; 2,000 consultas por reserva; rango «del 10 al 14» (4 noches)
y reserva de 5 noches donde falla la tercera. La escala del ejercicio y los números de
los ejemplos son inventados: no los presentes como estadísticas del hotel real.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar solicitudes simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                              % minutos desde la medianoche del día 1
categoria(Tipo, Nivel).                     % ordena los tipos: sencilla < doble < suite
habitacion(Cuarto, Tipo).
fuera_de_servicio(Cuarto, Desde, Hasta).    % noches
reserva(Id, Tipo, Llegada, Salida, Tarifa). % Tarifa: precio pactado por noche
asignacion(Id, Cuarto).                     % solo si ya se asignó cuarto físico
solicitud(Id, Tipo, Llegada, Salida, Canal, Minuto). % Canal: directo | agencia
cambio(Id, NuevaLlegada, NuevaSalida, Minuto).
tarifa(Tipo, Noche, Precio).                % lista de precios vigente
autorizacion_sobreventa(Tipo, Noche, Margen, Quien, Minuto).
evento(Id, Suceso, Minuto).                 % retenida | pagada | pago_sin_respuesta |
                                            % consulta_agencia | cancelada | llego | salio
```

## Contrato del gemelo

- `decide(+Solicitudes, -Reparto, -Explicacion)` — predicado central. `Solicitudes` es
  una lista de ids (puede ser de una); cada id es una solicitud nueva, un cambio de
  fechas de una reserva existente, o la reasignación de un huésped cuyo cuarto se
  dañó. `Reparto` dice qué se acepta, con qué tipo, noches, precio y cuarto, y qué se
  rechaza; `Explicacion` justifica cada pareja. Al pedir más soluciones debe dar los
  demás repartos válidos. Si no existe ninguno (noche llena, falta de cuartos
  continuos), lo dice y señala la noche o el cuarto que lo impide, sin fallar en
  silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre una noche
  de un tipo, una reserva o un cuarto (por ejemplo noche llena, cupo en duda,
  sobreventa intencional, sobreventa por error, huésped afectado por un cuarto dañado,
  cambio dentro de la ventana gratuita), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: la disponibilidad por tipo y noche, la decisión con su
  explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Rango.** Un rango donde basta una noche llena se rechaza y la explicación nombra
   esa noche. Una retención vigente ocupa cupo y una expirada lo libera; una retención
   vencida cuyo pago no se sabe deja la noche en «no se sabe», distinto de «no hay
   cupo». Una reserva que sale un día no choca con otra que llega ese mismo día.
2. **Último cuarto.** Con dos solicitudes que se disputan el último cuarto, el gemelo
   da un reparto válido, nombra a quién se le falló y el criterio de desempate usado, y
   con la consulta de «más soluciones» da los demás repartos. Con más solicitudes que
   cupo lo dice en vez de fallar en silencio. Nunca asigna un mismo cuarto dos veces
   la misma noche.
3. **Cuarto dañado.** Un cuarto fuera de servicio baja la capacidad de su tipo en esas
   noches y el gemelo lista a los afectados directos e indirectos con la cadena que
   los alcanza. El plan de reasignación solo usa cuartos libres todas las noches del
   afectado, y no baja de categoría a un huésped. Si no hay plan, lo dice y señala la
   noche.
4. **Sobreventa.** Con la misma venta total, una noche con el margen autorizado y otra
   sin autorización dan «intencional» y «error»; una sin registro de quién autorizó da
   «no se sabe». La capacidad usada es la efectiva: una noche con menos ventas que
   cuartos en papel puede resultar sobrevendida. La consulta inversa dice cuántos
   quedarían sin cuarto si todos llegan.
5. **Cambio de fechas.** Un cambio cuyas noches llenas lo están por la propia reserva
   no se rechaza por eso. El gemelo dice si el cambio cae en la ventana gratuita, el
   importe noche por noche según la interpretación declarada de «mantener el precio»,
   y la hipótesis con otra interpretación da otro importe.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el calendario por tipo y
noche (con «no se sabe» visible), las reservas y retenciones vigentes, las solicitudes
con su reparto y su explicación, los cuartos fuera de servicio con los huéspedes
afectados, la sobreventa por noche con su veredicto y la respuesta a «qué falta». Debe
verse bien en celular.
