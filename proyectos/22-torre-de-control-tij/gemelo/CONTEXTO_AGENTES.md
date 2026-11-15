# Contexto para agentes — gemelo digital del proyecto #22 (Torre de control TIJ)

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
- Las rotaciones, la aeronave de reserva, las rutas y los nombres de las fuentes son
  complementos de la extensión, no datos reales. No los presentes como un caso del
  aeropuerto ni les atribuyas estadísticas.

## Dominio

| Término | Significado |
|---|---|
| Vuelo | Un movimiento de una aeronave: sale de TIJ o llega a TIJ |
| Ciclo de vida | Los once estados del original, de «programado» a «aterrizado», más «demorado» y «cancelado» |
| STD / STA | Hora programada de salida / de llegada |
| ETD / ETA | Hora estimada de salida / de llegada |
| ATD / ATA | Hora real de salida / de llegada |
| Demora | Diferencia entre la hora estimada o real y la programada |
| Rotación | Secuencia de vuelos que opera una misma aeronave en la jornada |
| Efecto cascada | Demora heredada de la aeronave que llegó tarde en el vuelo anterior |
| Fuente | Quien reporta: aerolínea, torre, posición de la aeronave, página del aeropuerto |
| Mensaje fuera de orden | Recibido después de otro que se emitió más tarde |
| FIDS | Tablero de información de vuelos que ven pasajeros y personal |
| Pista única | Recurso crítico: cada despegue o aterrizaje pide separación de tiempo |
| Aeronave de reserva | Complemento de la extensión: sin rotación asignada |

Cifras de referencia, todas del problema original: once estados; 120 vuelos al día;
picos de 10 movimientos por hora; 300 clientes viendo el tablero; niebla que retrasa 20
minutos todas las salidas de la mañana; cerca de la mitad de las demoras iniciales
vienen de aeronaves que llegaron tarde; una sola pista. Todo lo demás (3 puertas, 4
aeronaves, 10 vuelos, rotaciones, reserva) es escala reducida o inventado.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar mensajes y lecturas simulados o graficar. Prolog nunca es una librería de
  Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  El gemelo no manda mensajes ni cambia estados: razona sobre los que entran como hechos.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                          % minutos desde las 0:00 de la jornada
vuelo(Vuelo, Aeronave, Origen, Destino).% sale de TIJ si Origen es TIJ; llega si Destino lo es
rotacion(Aeronave, Orden, Vuelo).       % plan publicado, no lo que realmente ocurre
reserva(Aeronave).                      % complemento: aeronave sin rotación asignada
horario(Vuelo, Tipo, Minuto).           % Tipo: std | sta | etd | eta | atd | ata
evento(Fuente, Vuelo, Estado, Emitido, Recibido).  % mensaje de estado, con sus dos instantes
causa_declarada(Vuelo, Causa, Fuente).  % clima | aeronave_previa | pista | trafico | seguridad
puerta_asignada(Vuelo, Puerta, Desde, Hasta).
rango(Variable, Minimo, Maximo).        % valores físicos posibles de cada medición
lectura(Aeronave, Variable, Valor, Minuto).  % posición y velocidad, de la fuente de posición
```

El estado de un vuelo, dónde está una aeronave, si una demora es propia o heredada y el
orden de uso de la pista **no son hechos**: se deducen de mensajes, lecturas y
horarios. La niebla entra como evento con su ventana. Qué fuente manda, la separación
en pista y el tiempo mínimo en tierra son predicados que añade el estudiante con sus
supuestos. Si hay jitter o retardo de red, entra como hecho (`Emitido` y `Recibido`),
no se sortea en las reglas.

## Contrato del gemelo

- `decide(+Vuelo, -Decision, -Explicacion)` — predicado central. `Decision` es lo que
  procede con ese vuelo en el «ahora»: el estado que debe mostrarse, el siguiente paso
  legal y la consecuencia sobre su aeronave (hora estimada, si opera, si se cancela, su
  turno de pista). Al pedir más soluciones da los demás pasos o secuencias válidas (y,
  en la pista, los demás turnos posibles para ese vuelo). Si la historia del vuelo no
  admite ninguna secuencia válida, lo dice y señala el mensaje que la rompe, sin fallar
  en silencio. `Explicacion` es una lista de hechos, condiciones y reglas que
  justifican la decisión, incluida la regla o la fuente que perdió cuando hubo conflicto.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  historia inconsistente, demora heredada, aeronave varada, puerta en conflicto, orden
  de pista), consultables en cualquier dirección. `Entidad` puede ser un vuelo, una
  aeronave o una puerta.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado deducido de vuelos y aeronaves, la decisión con su
  explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Orden.** Un mensaje recibido después de otro, pero emitido antes, no cambia el
   estado vigente, y la explicación dice por qué se descartó. Un «abordando» posterior
   a «despegó» se rechaza señalando la primera entrada que rompe la historia. Una
   «puerta cerrada» sin «abordando» da un paso intermedio que se sabe necesario pero
   cuyo instante «no se sabe». La misma lista de mensajes reconstruye el estado tras un
   reinicio. Un vuelo sin mensajes no se declara cancelado ni demorado por eso.
2. **Fuentes.** Con la aerolínea en «abordando» y la torre y la posición en «rodando»,
   el tablero no muestra «abordando» por venir de la fuente oficial: la explicación
   nombra la evidencia que perdió y a quién se le falla. Si la lectura de posición es
   vieja, está fuera de rango o no se puede atribuir a la aeronave, el resultado es
   «no se sabe» y no se muestra «rodando» como hecho. La consulta inversa dice qué
   mensaje tendría que llegar para cambiar la decisión.
3. **Cascada.** La salida de la tarde de la aeronave con niebla en la mañana aparece
   demorada con causa deducida «heredada», aunque ya no haya niebla y aunque la
   aerolínea declare «clima»; la evidencia lista la cadena de vuelos completa. Un vuelo
   de la misma cadena con margen suficiente aparece como no afectado, con la razón. La
   hipótesis «sin niebla» quita la demora de la cadena.
4. **Cancelación.** Cancelar la salida no cancela por sí solo el regreso ni el vuelo
   siguiente de esa aeronave: el gemelo deduce dónde quedó la aeronave y concluye vuelo
   por vuelo, con la razón. Con dos vuelos que reclaman la aeronave de reserva, la
   explicación nombra las dos razones en choque, cuál prevalece, a quién se le falla y
   qué tendría que cambiar. Una cancelación reportada por una sola fuente da «no se
   sabe» y no propaga nada. Al pedir más soluciones aparecen los demás repartos válidos.
5. **Pista.** Para las salidas listas se obtienen todos los órdenes que respetan la
   separación; un orden inválido se rechaza señalando el primer par que la rompe. Un
   cambio de puerta y de hora a medias no se muestra como completo; la puerta ocupada se
   reporta como conflicto con el vuelo que la ocupa. Cada vuelo desplazado dice qué lo
   desplazó y cuánta demora arrastra a su rotación.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el tablero de vuelos con el
estado deducido de cada uno, la línea de mensajes con los descartados marcados, las
rotaciones de las aeronaves con la cascada de demoras, la decisión con su explicación,
los órdenes válidos de la pista y la respuesta a «qué falta». Debe distinguir «sí»,
«no» y «no lo sé», y verse bien en celular.
