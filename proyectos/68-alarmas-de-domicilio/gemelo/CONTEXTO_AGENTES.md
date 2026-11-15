# Contexto para agentes — gemelo digital del proyecto #68 (Alarmas de domicilio)

Este archivo es para el agente (OpenCode u otro) que acompaña al estudiante. Léelo
completo, junto con [`PROBLEMA.md`](PROBLEMA.md) y
[`../problema/readme.md`](../problema/readme.md), antes de proponer cualquier cosa.

## Tu papel

- El proyecto es individual y se califica el razonamiento del estudiante. **Explica,
  pregunta y propone; no entregues la solución completa.**
- Antes de escribir una regla, pide al estudiante que la diga en español.
- Primero la prueba plunit, después la regla.
- Trabaja una situación a la vez, en el orden de `PROBLEMA.md`.
- No inventes cifras. Las cifras reales de `PROBLEMA.md` vienen del problema original;
  cualquier otra se marca como supuesto y se le pide al estudiante la fuente.

## Dominio

| Término | Significado |
|---|---|
| Panel | Equipo del domicilio que reporta a la central; tiene zonas, modo y canal |
| Zona | Sensor o grupo de sensores del panel; tiene un tipo (entrada, perímetro, movimiento, interior) |
| Modo | Desarmado, armado en casa o armado en ausencia |
| Contact ID (SIA) | Protocolo estándar con el que los paneles mandan código de evento y zona |
| Canal | Línea telefónica, internet o celular, por donde reporta el panel |
| Retardo de entrada | Tiempo para desarmar antes de que suene; de 30 a 60 s |
| Verificación cruzada | Dos zonas distintas activadas en pocos minutos |
| Palabra clave y de coacción | La primera confirma al cliente; la segunda avisa que está bajo amenaza |
| Latido | Señal periódica de que el panel está vivo; al menos cada 24 h |
| Señal técnica | Batería baja, corte de energía, corte de comunicación, falta de latido |
| Escalamiento | Pasos del protocolo del cliente: llamar, esperar, reintentar, despachar |
| Circuito | Término del ejercicio: red eléctrica a la que cuelgan varios paneles |

Cifras de referencia, todas del problema original: entre 90 % y 98 % de las activaciones
reportadas a la policía resultan falsas; retardo de entrada de 30 a 60 s; latido cada
24 h o menos; panel sin latido durante 26 h; 5,000 paneles, 800 eventos por hora y
3 operadores; 400 cortes de energía en 20 min. Son órdenes de magnitud.

Los términos y números del escenario reducido (12 paneles, 3 circuitos, tipos de zona,
identificadores) son del ejercicio, no estadísticas. Cuántos minutos son «pocos», las
esperas del protocolo y los demás umbrales los define el estudiante: el original no los da.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar eventos simulados o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Si el escenario necesita azar (por ejemplo, cuándo llega un desarme retrasado), entra
  como hecho o queda como supuesto del estudiante.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundo).                          % segundos desde el inicio del escenario
panel(Panel, Cliente, Canal, Circuito).  % Canal: telefono | internet | celular
zona(Panel, Zona, Tipo).                 % Tipo: entrada | perimetro | movimiento | interior
cubre(Panel, ZonaA, ZonaB).              % las dos zonas ven el mismo espacio
modo(Panel, Modo, Segundo).              % desarmado | armado_en_casa | armado_en_ausencia
retardo_entrada(Panel, Segundos).
evento(Panel, Evento, SegundoPanel, SegundoCentral).  % cuándo ocurrió y cuándo llegó
protocolo(Cliente, Paso, Contacto, EsperaSegundos).   % lo fija el estudiante
verificacion(Panel, Resultado, Segundo). % sin_respuesta | palabra_clave | coaccion | incorrecta
accion(Panel, Accion, Segundo).          % bitácora de la central: llamada, despacho, cancelacion...
operador(Operador, Estado).              % libre | ocupado
asignacion(Panel, Operador, Segundo).    % alarma tomada por un operador
```

## Contrato del gemelo

- `decide(+Panel, -Decision, -Explicacion)` — predicado central. La entidad es un panel
  con su alarma en curso. `Decision` incluye la clasificación (robo probable, sospecha,
  falsa alarma probable, señal técnica, no se sabe) y el siguiente paso válido del
  protocolo en el estado en que está (esperar, llamar, reintentar, despachar, desviar,
  cancelar, escalar). Al pedir más soluciones debe dar los demás pasos válidos.
  `Explicacion` es una lista de hechos y condiciones que justifican la decisión.
- `situacion(?Panel, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  verificación cruzada válida, corte aislado, silencio sospechoso, cancelación bajo
  coacción), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de los paneles, la decisión con su explicación, la
  cola de alarmas por operador y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Dos zonas.** Dos zonas distintas que ven espacios independientes en pocos minutos
   dan verificación cruzada y la evidencia las lista. Dos zonas que comparten causa
   posible no la dan: la alarma queda en sospecha, la explicación dice por qué y la
   consulta inversa dice qué evidencia la subiría a despacho.
2. **Retardo de entrada.** La misma zona de entrada produce resultados distintos según
   el modo del panel y el instante del evento en el panel, no el de llegada. Un desarme
   que no ha llegado da «no se sabe», distinto de «no hubo desarme», y la respuesta se
   corrige si el evento llega después.
3. **Cancelación.** Una cancelación con palabra clave válida tras el despacho es
   atendida; con palabra de coacción, incorrecta o de quien no es contacto, no cancela
   y la explicación dice cuál fue el caso. La respuesta incluye los estados recorridos y
   no permite pasar a un estado que la secuencia no admite.
4. **Tormenta.** Los cortes con causa común se agrupan como una avería; el corte cuyo
   circuito no sufrió otros cortes aparece aparte, con prioridad para un operador. Un
   vecino sin reportar da «no se sabe». Con más alarmas que operadores nadie queda con
   dos a la vez, y la alarma crítica sin atender se escala con la razón.
5. **Silencio.** Un panel sin latido con un corte y una batería baja previos tiene una
   explicación distinta del que calla sin antecedente; el gemelo no acusa de sabotaje
   si otra causa lo explica, y dice «no se sabe» cuando la evidencia no alcanza. La
   consulta inversa dice qué dato cambiaría la conclusión.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar la lista de paneles con su
modo y su último latido, las alarmas abiertas con su clasificación, la decisión con su
explicación, la cola de cada operador con la antigüedad de cada alarma, los cortes
agrupados por circuito con los dudosos marcados, y la respuesta a «qué falta». Debe verse
bien en celular.
