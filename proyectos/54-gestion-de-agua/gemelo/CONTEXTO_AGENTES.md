# Contexto para agentes — gemelo digital del proyecto #54 (Gestión de agua)

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
  se marca como supuesto y se le pide al estudiante la fuente. Las colonias, la clínica,
  la línea compartida y la cuadrilla única de los ejemplos son del ejercicio, no del mundo.

## Dominio

| Término | Significado |
|---|---|
| Colonia | Zona de la red con un macromedidor de entrada, sensores de presión y tomas |
| Macromedidor | Mide el agua que entra a una colonia |
| Toma | Conexión domiciliaria; con medidor inteligente (cada hora) o tradicional (mensual) |
| m.c.a. | Metros de columna de agua; la red opera típicamente entre 10 y 50 |
| Flujo mínimo nocturno | Entre las 2 y las 4 a. m. casi nadie consume; caudal alto ahí sugiere fuga |
| Balance hídrico | Entrada menos la suma de lo medido en las tomas; el resto son pérdidas |
| Agua no contabilizada | Pérdidas por fugas y tomas clandestinas; ronda el 40 % en México |
| Tandeo | Suministro por turnos; al volver el agua se llenan tinacos |
| Golpe de ariete | Variación brusca de presión que puede indicar una ruptura mayor |
| Descalibrado | Sensor cuyo valor se desvía de manera sistemática de la realidad |
| Pérdida real / aparente | Agua que se escapa por la tubería / agua que se consume y no se mide |
| Línea compartida | Dos colonias alimentadas por la misma tubería; ejemplo de este ejercicio |

Cifras de referencia (del original): presiones de 10 a 50 m.c.a. (≈ 1 a 5 kg/cm²);
método del flujo mínimo nocturno entre las 2 y las 4 a. m.; fuga que incrementa 15 % el
caudal nocturno; lecturas de los sensores cada 5 minutos; medidor inteligente cada hora
contra lectura mensual; 12 colonias con 5 sensores de presión cada una; consumo medio
de 150 a 250 litros por persona al día; el tiempo de reacción ante una ruptura se mide
en minutos. Marcados como del ejercicio, sin cifras: 4 colonias, 3 sensores por colonia,
tomas, clínica, línea compartida, tandeo en una colonia concreta, avisos de vecinos,
cuadrilla única y tiempos de traslado.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Si la simulación necesita azar (un retraso de medidor, una lectura fuera de orden), el
  valor entra como hecho; las reglas no sortean nada.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                            % instante del gemelo, en minutos desde la medianoche
colonia(Colonia, Posicion).               % Posicion: alta | baja
linea(Linea, Colonia).                    % colonias alimentadas por la misma línea
sensor(Sensor, Colonia).                  % sensor de presión de un tramo de la colonia
toma(Toma, Colonia, Medidor).             % Medidor: inteligente | tradicional
instalacion(Instalacion, Colonia, Tipo).  % Tipo: clinica | escuela | otro
rango(Variable, Minimo, Maximo).          % rango físico: presion, caudal
lectura(Fuente, Variable, Valor, Minuto). % Minuto = instante de la medición; Fuente: sensor, macromedidor o toma
llegada(Fuente, MinutoMedido, MinutoRecibido). % cuándo llegó realmente una lectura
evento(Colonia, Evento, Detalle, Minuto). % regreso del tandeo, evento público, calor, aviso, cuadrilla
```

## Contrato del gemelo

- `decide(+Entidad, -Decision, -Explicacion)` — predicado central. La entidad es una
  colonia, un sensor o una fuga sospechada; el estudiante elige cómo representarla. Para
  una colonia, `Decision` es qué se concluye de su noche (fuga probable, consumo legítimo,
  pérdida aparente o por qué no se sabe); para un sensor, si se le cree y para qué.
  `Explicacion` es una lista de hechos, lecturas, reglas y evidencias que la justifican.
  Para ordenar la cuadrilla (situación 4) el primer argumento puede ser la LISTA de fugas
  sospechadas y `Decision` el orden de atención completo; al pedir más soluciones debe
  dar los demás órdenes válidos, y si no existe ninguno lo dice y señala el motivo, sin
  fallar en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (fuga probable,
  consumo legítimo, pérdida aparente, sensor descalibrado, ruptura mayor probable),
  consultables en cualquier dirección: dada una colonia, sus situaciones; dada una
  situación, quiénes la cumplen.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- Toda inferencia (por ejemplo, el tramo probable de una fuga) se marca como inferencia y
  cita las lecturas que la sustentan; nunca se presenta como una lectura.
- La API expone al menos: el estado de colonias y sensores, la decisión con su
  explicación, el balance con lo seguro y lo dudoso, el orden de la cuadrilla y «qué
  falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Fuga o tinacos.** Una colonia con caudal nocturno alto y un evento que lo explica
   (regreso del tandeo) sale como consumo legítimo; otra con el mismo exceso y sin
   explicación sale como fuga probable. Si casi ninguna toma reporta, la respuesta es
   «no se sabe». La evidencia dice qué observación cambiaría el veredicto.
2. **Balance.** Con tomas tradicionales, lecturas ausentes o llegadas fuera de orden, el
   balance entrega lo que es seguro y lo que es dudoso, no una sola cifra. Un faltante
   nunca cuenta como consumo cero. Una lectura que llega tarde no se compara con la
   hora que no le corresponde.
3. **Ruptura o sensor.** Un sensor desconfiable no produce alerta por sí solo, pero su
   caída coincidente con otros sensores, con el caudal y con avisos sí cuenta; la
   respuesta dice para qué se le cree y para qué no. La evidencia nombra de qué lado de
   la línea es la ruptura probable.
4. **Cuadrilla.** El orden cita certeza, pérdida, instalaciones críticas y traslado, y
   nombra la prioridad que decidió. Dice a quién se le falla con ese orden y qué tendría
   que cambiar para que otra fuga pasara primero. Una fuga dudosa recibe visita de
   verificación y no se trata igual que una confirmada.
5. **Fuga que nadie ve.** Con pérdida nocturna y presión dentro de rango, el gemelo no
   concluye «sin fuga»; distingue pérdida real de pérdida aparente según cuándo ocurre y
   qué dicen las tomas y los sensores del tramo. Un sensor sin dato se declara y la
   inferencia lo refleja.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el estado de cada colonia
(caudal nocturno, presión por sensor, balance con lo seguro y lo dudoso), la decisión con
su explicación y sus tres respuestas, qué sensores se creen y para qué, el orden de la
cuadrilla con a quién se le falla, lo inferido marcado como tal y la respuesta a «qué
falta». Debe verse bien en celular.
