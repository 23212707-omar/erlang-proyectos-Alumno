# Contexto para agentes — gemelo digital del proyecto #4 (Apiario o ganado)

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
| Apiario | Sitio con varias colmenas; en esta extensión comparte un enlace de radio (supuesto de la extensión) |
| Colmena | Unidad sobre la que se decide; trae báscula, sensor de temperatura interna, acelerómetro y reporte de posición |
| Cría | Zona de la colmena que una colonia sana mantiene a ~34-35 °C |
| Sin cobertura | El dispositivo vive pero no puede reportar; al volver, manda una ráfaga |
| Perdida | La colmena o su colonia ya no están; no la mide ningún sensor, se deduce |
| Cerco | Límite virtual del apiario; salir de él de madrugada es sospechoso |
| Orden de traslado | Registro del dueño que autoriza mover colmenas en una ventana de horas (extensión) |
| Enjambrazón, saqueo | Causas posibles de que el peso caiga sin motivo, junto con el robo |
| Hora de dispositivo / de llegada | Cuándo se tomó una lectura / cuándo llegó al servidor; pueden diferir horas |

Cifras de referencia, todas del problema original: cría a ~34-35 °C; en flujo de néctar
una colmena puede ganar 1-5 kg/día; cobertura LoRa o celular intermitente, con horas sin
reportar; escenario de 60 colmenas en 6 apiarios. Términos y números de la extensión
(3 apiarios, 9 colmenas, enlace por apiario, órdenes de traslado, técnico único) son
del ejercicio, no del original.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                          % minutos desde la medianoche del primer día
apiario(Apiario).
colmena(Colmena, Apiario).
rango(Variable, Minimo, Maximo).        % rango físico creíble de peso, temp_cria, bateria
lectura(Colmena, Variable, Valor, Minuto).   % Minuto = hora del dispositivo
                                        % Variable: peso | temp_cria | movimiento | bateria
recibida(Colmena, MinutoDispositivo, MinutoLlegada).   % cuándo llegó al servidor
cerco(Colmena, DentroOFuera, Minuto).   % dentro | fuera, con hora del dispositivo
evento(Colmena, Tipo, Detalle, Minuto). % visita | cosecha | traslado_autorizado (Detalle:
                                        % ventana) | aviso_enviado | aviso_retirado
tecnico(Nombre, Apiario).               % dónde está hoy
```

## Contrato del gemelo

- `decide(+Colmena, -Decision, -Explicacion)` — predicado central. `Decision` incluye
  el estado deducido y qué hacer (avisar ya, resumir, esperar, atender primero o
  diferir). `Explicacion` es una lista de hechos y condiciones que la justifican; si la
  colmena se difiere, nombra el aviso que la superó. Puedes añadir una variante que
  responda con lo sabido hasta un minuto dado.
- `situacion(?Colmena, ?Situacion, -Evidencia)` — situaciones deducidas (sin cobertura,
  posiblemente perdida, salida autorizada, peso sin explicación...), consultables en
  cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de las colmenas, la decisión con su explicación,
  «qué falta para que cambie» y el orden de atención de los avisos vigentes.

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Callada.** Colmenas calladas junto con todas las de su apiario no se declaran
   perdidas; una callada mientras sus vecinas reportan sí queda como sospechosa. Una
   batería baja en su última lectura se señala como causa posible. Cuando faltan datos,
   la respuesta es «no se sabe», no «perdida».
2. **Ráfaga.** El estado se calcula por hora de dispositivo, no por orden de llegada.
   Una lectura con hora futura se descarta con motivo. El aviso se evalúa con lo sabido
   entonces y con lo sabido ahora, y puede quedar justificado entonces y retirado ahora.
3. **Movimiento de madrugada.** Una salida cubierta por una orden vigente no genera aviso
   de robo; una sin orden sí; una cuya orden no coincide con la hora queda como «no se
   sabe» o discrepancia, y la explicación lo dice. La consulta inversa dice qué
   cambiaría el veredicto.
4. **Peso.** Con una cosecha registrada o una lectura de báscula no creíble, la caída
   no produce alerta de robo ni de enjambre; con lectura creíble y sin explicación
   inocente, queda la causa que sobrevive y las descartadas aparecen con su motivo.
5. **Técnico.** Dos avisos graves y un técnico producen un orden de atención con el
   aviso diferido y la razón; los avisos menores se resumen; la consulta inversa dice
   qué tendría que cambiar para invertir el orden.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar por apiario el estado de
cada colmena (con su razón), las alertas vigentes con su orden de atención, la
explicación de cada decisión y la respuesta a «qué falta», distinguiendo lo medido de lo
deducido. Debe verse bien en celular.
