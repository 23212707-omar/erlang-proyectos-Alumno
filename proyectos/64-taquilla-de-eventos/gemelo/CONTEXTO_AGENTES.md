# Contexto para agentes — gemelo digital del proyecto #64 (Taquilla de eventos)

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
| Fila virtual | Espera ordenada de usuarios que pasan a comprar por tandas controladas |
| Tanda | Grupo de usuarios admitidos a la vez; tiene un número de orden |
| Asiento | Unidad única: solo puede venderse una vez |
| Retención | Asiento apartado mientras el usuario elige y paga; si no paga, vuelve al inventario |
| En duda | Asiento cuya retención venció sin que se sepa si el pago llegó |
| Límite por comprador | Máximo de boletos por persona para frenar la reventa |
| Comprador | Persona real detrás de una o varias cuentas; no es un dato, se deduce |
| Tramo | Asientos libres contiguos (misma fila, números consecutivos) |
| Boleto | Asiento vendido, con titular y código QR que se valida en la puerta |
| Comprometido | Boleto con escaneos incompatibles entre sí o con titular dudoso |
| Sobreventa cero | Invariante: nunca hay más boletos válidos que asientos |

Cifras de referencia, todas del problema original: límite de 4-6 boletos por persona;
retención de 3-10 min; 30 % de las retenciones nunca se paga; estadio de ~25-30 mil
personas y foro de 1-5 mil; escenario de 20,000 asientos y 100,000 usuarios en el primer
minuto; un QR copiado presentado en dos puertas. La escala del ejercicio (24 asientos,
3 zonas, 3 puertas), los nombres, los ids y los números de los ejemplos son inventados:
no los presentes como estadísticas reales.

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
ahora(Segundo).                             % segundos desde que abre la venta
asiento(Id, Zona, Fila, Numero).
cuenta(Cuenta, Tarjeta, Dispositivo).       % indicios; la persona no es un dato
turno(Cuenta, Tanda, Posicion).             % lugar en la fila virtual
solicitud(Id, Cuenta, Zona, Cantidad, Juntos, Segundo). % Juntos: si | no
retencion(Id, Asiento, Cuenta, Desde).      % inicio de la retención
boleto(Id, Asiento, Titular).               % solo asientos vendidos
evento(Id, Suceso, Segundo).                % retenida | pagada | vencida | pago_sin_respuesta |
                                            % caida | transferido | admitida_tanda
escaneo(Boleto, Puerta, Segundo).
puerta_conectada(Puerta, Desde, Hasta).     % periodos en que la puerta reportó
```

## Contrato del gemelo

- `decide(+Solicitudes, -Reparto, -Explicacion)` — predicado central. `Solicitudes` es
  la lista de ids de solicitud (puede ser de una); `Reparto` dice qué asientos se
  asignan a quién y qué se rechaza o se deja en espera; `Explicacion` justifica cada
  pareja. Al pedir más soluciones debe dar los demás repartos válidos. Si no existe
  ninguno (no hay asientos, todos están en duda o se rebasa el límite), lo dice y señala
  el motivo, sin fallar en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre un asiento,
  un comprador, una cuenta o un boleto (por ejemplo asiento en duda, comprador con
  margen, cuentas del mismo comprador, boleto comprometido, tramo libre), consultables
  en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de los asientos, la decisión con su explicación y
  «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Mismo asiento.** Con dos solicitudes al mismo asiento en el mismo instante, el
   gemelo da un reparto sin asignar un asiento dos veces, nombra a quién se le falló y
   el criterio de desempate usado, y con «más soluciones» da los demás repartos. Un
   asiento retenido y vigente no se ofrece a nadie más.
2. **Límite.** La solicitud se evalúa contra el comprador deducido, no contra la cuenta.
   Cuentas con indicios fuertes se unen; cuentas con un solo indicio dan «no se sabe»,
   distinto de «no». Una retención vencida deja de contar y una vigente cuenta. La
   explicación lista cuentas y boletos, y la consulta inversa dice qué cambiaría.
3. **Retención.** Una retención vencida sin respuesta de la pasarela deja el asiento
   «en duda», que no se ofrece, y es distinto de «libre». Tras una caída, el gemelo
   cuenta los asientos en duda. Nunca resulta un asiento con dos boletos válidos.
4. **Puertas.** Dos escaneos del mismo boleto incompatibles producen un boleto
   comprometido y no declaran impostor al segundo. Una puerta sin conexión da «no se
   sabe». Una transferencia cambia al titular vigente. La evidencia cita los escaneos.
5. **Lote.** Con tramos contiguos escasos, el gemelo reparte un lote sin romper
   exclusividad ni límites, ofrece alternativas, y si el grupo no cabe junto dice por
   qué y qué retención tendría que vencer. La solicitud rechazada por límite no ocupa
   tramo.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el mapa de asientos con su
estado (libre, retenido, vendido, en duda), las solicitudes con su reparto y su
explicación, cada comprador con las cuentas que se le atribuyen y su margen contra el
límite, los boletos con sus escaneos por puerta y su veredicto, y la respuesta a «qué
falta». Debe verse bien en celular.
