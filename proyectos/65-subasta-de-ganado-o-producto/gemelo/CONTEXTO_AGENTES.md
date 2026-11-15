# Contexto para agentes — gemelo digital del proyecto #65 (Subasta de ganado o productos)

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
| Lote | Grupo de animales que se vende junto, con un vendedor y un orden en la subasta |
| Kilo en pie | Unidad de venta: el precio se ofrece por kilo de animal vivo |
| Escalón | Incremento con que el martillero sube el precio |
| Llamada | «A la una, a las dos, a las tres»; el reloj de adjudicación se reinicia con cada puja |
| Etapa | Estado del lote: abierto, última llamada, adjudicado, retirado o sin venta |
| Puja remota | La de un postor conectado desde su rancho; ve el precio con retraso |
| Compromiso de compra | Efecto de que una puja sea aceptada |
| Reserva | Total mínimo en pesos que el vendedor acepta; no lo conoce el público |
| Báscula | Pesa el lote en el momento; peso por precio por kilo da el total |
| Arete SINIIGA | Identificación individual del animal |
| Guía de tránsito | Documento para mover los animales; se suma al certificado sanitario |
| Bitácora | Registro numerado e inalterable de pujas, llamadas y órdenes |
| En duda | Puja o evento cuyo efecto no puede decidirse con la bitácora disponible |

Cifras de referencia, todas del problema original: 100-300 lotes por subasta, 1-3 minutos
por lote, retraso de 1-3 segundos de un postor remoto, ~200 kg por becerro, puja remota
2 segundos después de la adjudicación, escenario de 150 lotes, 80 postores (60 en sala y 20
remotos) y 1 martillero. La escala del ejercicio, los nombres, los números de lote y las
cantidades de los ejemplos son inventados: no los presentes como estadísticas reales.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar pujas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Ms).                                  % milisegundos desde que abre la subasta
lote(Id, Vendedor, Orden).
animal(Arete, Lote).
documento(Tipo, Arete, Vigencia).           % Tipo: arete | sanitario | transito;
                                            % Vigencia: una fecha o desconocida
postor(Id, Modalidad).                      % Modalidad: sala | remoto
latencia(Postor, Ms).                       % retraso medido de un remoto
puja(Id, Postor, Lote, PesosPorKilo, Emision, Llegada). % Emision: Ms o desconocida
reserva(Lote, Pesos, Desde).                % total mínimo; rige desde ese instante
evento(Seq, Lote, Suceso, Ms).              % Seq: número de bitácora; Suceso: abierto |
                                            % llamada | adjudicado | retirado | sin_venta |
                                            % conexion_perdida | conexion_recuperada | reinicio
rango(Variable, Minimo, Maximo).            % plausibilidad de un peso en báscula
lectura(Lote, Variable, Valor, Ms).         % lecturas de la báscula
```

## Contrato del gemelo

- `decide(+Lote, -Decision, -Explicacion)` — predicado central. `Decision` incluye la
  etapa siguiente o la secuencia de etapas válida del lote, y quién lo gana si se
  adjudica; `Explicacion` es una lista de hechos y condiciones que la justifican. Al pedir
  más soluciones debe dar las demás secuencias o desenlaces compatibles con lo que hay
  (por ejemplo cada historia posible tras un hueco de bitácora). Si ninguna es válida,
  lo dice y señala el motivo, sin fallar en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre un lote, una
  puja, un postor o un animal (por ejemplo puja en duda, compromiso vigente, reserva
  cumplida, lote con documentos completos), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de los lotes, la decisión con su explicación (completa
  y filtrada para el público) y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Martillazo.** Con pujas en el mismo instante o después de la última llamada, el
   gemelo da un solo ganador, nombra el desempate y a quién se le falló. Una puja remota
   por el escalón anterior se trata de forma distinta de una por el vigente, y la
   explicación lo dice. La consulta inversa dice qué cambiaría el resultado.
2. **Desconexión.** Una puja recibida antes de la caída de la conexión, una posterior y una
   que no se puede situar dan tres resultados distintos: obliga, no obliga y no se sabe. En
   el tercero el lote no se adjudica a nadie por omisión y la evidencia cita la bitácora.
3. **Reserva.** Un lote con la puja más alta pero con un total que no alcanza la reserva
   vigente no se adjudica, y la explicación para el público no revela la reserva. Una
   lectura fuera de rango o una báscula sin lectura dan «no se sabe», distinto de «no se
   cumple», y esperan peso. Un cambio de reserva solo vale desde su instante.
4. **Retiro.** Con una puja líder y un hueco en la bitácora, el gemelo muestra cada
   historia compatible con su etapa final, no admite secuencias imposibles y señala qué
   registro decidiría. Los lotes restantes conservan su orden.
5. **Documentos.** Un animal con un papel faltante o de vigencia desconocida da un lote que
   no puede salir, con el animal y el papel señalados; la vigencia desconocida es «no se
   sabe», nunca «sí». La conclusión sobre el lote sale de lo que se sabe de cada animal.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar los lotes con su etapa, las
pujas en orden con su validez y su explicación, cada remoto con su retraso y su conexión,
la reserva solo en la vista del vendedor o del auditor, la bitácora con sus huecos, los
animales de cada lote con sus documentos, y la respuesta a «qué falta». Debe verse bien
en celular.
