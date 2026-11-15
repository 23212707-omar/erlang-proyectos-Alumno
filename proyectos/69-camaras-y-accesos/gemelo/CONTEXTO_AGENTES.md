# Contexto para agentes — gemelo digital del proyecto #69 (Cámaras y accesos)

Este archivo es para el agente (OpenCode u otro) que acompaña al estudiante. Léelo
completo, junto con [`PROBLEMA.md`](PROBLEMA.md) y
[`../problema/readme.md`](../problema/readme.md), antes de proponer cualquier cosa.

## Tu papel

- El proyecto es individual y se califica el razonamiento del estudiante. **Explica,
  pregunta y propone; no entregues la solución completa.**
- Antes de escribir una regla, pide al estudiante que la diga en español.
- Primero la prueba plunit, después la regla.
- Trabaja una situación a la vez, en el orden de `PROBLEMA.md`.
- No inventes cifras. Las reales vienen del problema original; las del escenario son
  datos del ejercicio y están marcadas como tales; cualquier otra se marca como supuesto
  y se le pide al estudiante que decida o cite la fuente.

## Dominio

El escenario («Manufacturas Mesa de Otay») lo plantea esta extensión; no existe. El
reglamento (a)-(h) de `PROBLEMA.md` son reglas del ejercicio, no leyes.

| Término | Significado |
|---|---|
| Bitácora | Registro de eventos con marca de tiempo; es la evidencia, no el video |
| Evento | Algo que un dispositivo reporta: tarjeta leída, puerta abierta, movimiento, alarma |
| Instante del dispositivo | La hora que el reloj del dispositivo escribió en el evento |
| Instante de llegada | Cuándo lo recibió la bitácora; puede ser mucho después (evento tardío) |
| Desfase | Diferencia entre el reloj de un dispositivo y la hora real; se mide y envejece |
| Bóveda | Cuarto de componentes de alto valor en el edificio B; acceso restringido |
| Escolta | Persona de planta que acompaña a un contratista |
| Consta dentro | Conclusión a partir de entradas y salidas; ningún sensor la mide |
| Incidente | Investigación abierta con ventana de tiempo y edificios; retiene eventos |
| Retención | Plazo que un evento debe conservarse; después es candidato a borrarse |
| Cadena de hashes | Cada registro enlazado al anterior; borrar uno rompe la verificación |

Cifras del original: 100 puertas, 200 cámaras, 150 eventos/s con picos de 2,000/s; reloj
con 4 minutos de atraso; búsqueda en el rango 2:10 a 2:25 en el edificio B; video de 30
a 90 días y bitácora de 1 a varios años. **Del escenario inventado** (datos del
ejercicio): nivel B-3, 2 contratistas por escolta, plazos de 1 año y 90 días, ventanas de
consulta de 1 y 30 días, dos aprobaciones, y las horas de los ejemplos.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar eventos simulados o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados (turnos, capacitaciones,
delegaciones, estado en línea), no renombrar estos.

```prolog
ahora(Minuto).                         % minutos desde una fecha de referencia; los plazos en días se convierten
puerta(Puerta, Edificio, Sentido).     % Sentido: entrada | salida
dispositivo(Dispositivo, Tipo, Edificio).  % Tipo: lector | sensor_puerta | camara | panel_alarma
persona(Persona, Rol, JefeDirecto).    % Rol: planta | contratista | guardia | jefatura | auditoria | privacidad
credencial(Persona, Nivel, VigenteHasta).
evento(Id, Dispositivo, Tipo, Detalle, InstanteDispositivo, InstanteLlegada).
desfase(Dispositivo, Minutos, InstanteMedicion).
rango(Variable, Minimo, Maximo).       % valores físicos posibles; fuera de él, el dato no se cree
lectura(Dispositivo, Variable, Valor, Instante).  % estado de sensor de puerta, movimiento de cámara
incidente(Id, Edificio, Desde, Hasta, Estado).    % Estado: abierto | cerrado
solicitud(Id, Solicitante, Objetivo, Desde, Hasta, Motivo).  % acceso, consulta o retiro de identidad
aprobacion(Solicitud, Aprobador, Sentido).        % Sentido: a_favor | en_contra
```

## Contrato del gemelo

- `decide(+Solicitud, -Decision, -Explicacion)` — predicado central. La entidad es una
  sola solicitud (de acceso, de consulta o de borrado). `Decision` es permitir, negar,
  condicionar o aplazar, con lo que falta o hasta cuándo; si hay varias salidas válidas,
  al pedir más soluciones aparecen las demás. `Explicacion` es una lista de hechos y
  condiciones, incluida la regla que perdió cuando dos chocan.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (quién consta
  dentro, hora probable, evento retenido, puerta forzada, aprobación válida), consultables
  en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de personas y dispositivos, la decisión con su
  explicación, «qué falta para que cambie» y el registro de quién consultó qué.

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Escolta.** Un técnico con escolta presente, válida y con cupo es elegible; si el
   único rastro de la escolta es una entrada sin salida y la puerta de salida no reportó,
   la respuesta no es un «sí» ni un «no» rotundo: dice que no se sabe, por qué y qué
   dato lo resolvería. Con lector en línea que confirma la salida, se niega.
2. **Reloj.** La lista de un rango cambia al corregir el desfase: un evento entra y otro
   sale. Un trabajador con marca anterior a la alarma puede resultar posterior a ella. Con
   un reloj sin medir, el orden de dos eventos cercanos es «indeterminable», no un
   empate arbitrario. El reporte «de ayer» y el «de hoy» difieren por los eventos tardíos.
3. **Borrado.** Un evento vencido dentro de la ventana de un incidente abierto no se
   borra y la explicación nombra el incidente; al cerrarlo, queda libre. La solicitud del
   exempleado recibe una respuesta que dice a quién se le falla y qué se ofrece.
4. **Puerta.** La misma apertura sin tarjeta se explica de distinto modo según haya o no
   alarma de incendio y según el sentido de la puerta. Un sensor que no marcó apertura
   tras un acceso concedido no se declara «intrusión» ni «normal»: se marca como falla o
   como «no se sabe» según la evidencia.
5. **Consulta por persona.** Una aprobación del propio solicitante, del consultado o de su
   jefe directo no cuenta. Una delegación sin vigencia conocida produce «falta», no
   «aprobada». La respuesta dice qué parte de la solicitud sí es elegible y quién podría
   completar el resto.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar las personas y los
dispositivos con su estado (en línea, desfase), la línea de tiempo corregida de un rango,
la decisión de cada solicitud con su explicación, «qué falta» y el registro de consultas.
Debe verse bien en celular.
