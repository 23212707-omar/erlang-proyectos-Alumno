# Contexto para agentes — gemelo digital del proyecto #7 (Control de acceso)

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
| Zona | Área de la planta con acceso propio (calle, planta, almacén, oficinas) |
| Puerta | Paso entre dos zonas; tiene lector y, a veces, sensor de contacto y contador de paso |
| Credencial / tarjeta | Lo que presenta la persona; puede estar activa, reportada o revocada |
| Revocación | Cancelar una tarjeta; cada puerta la conoce hasta que se sincroniza |
| Sincronización | Momento en que una puerta recibe del servidor los cambios de permisos |
| Anti-passback | No entrar dos veces sin salir en medio |
| Tailgating | Cruzar dos personas con un solo acceso concedido |
| Puerta forzada | Se abre sin acceso concedido ni excepción que la explique |
| Fail-secure / fail-safe | Puerta cerrada o abierta cuando se va la energía |
| Salida de emergencia | Puerta que debe abrir siempre (NOM-002-STPS-2010) |

Cifras de referencia, todas del problema original: decisión de la puerta en ~0.5-1 s;
servidor incomunicado 30 minutos; tarjeta robada usada 3 veces en 1 minuto; 40 puertas,
2,000 personas y picos de 150 lecturas por minuto en el escenario completo.
Del escenario reducido de esta extensión (no son datos reales): 5 puertas, 8 personas y
4 zonas; los nombres de personas y las puertas concretas son ilustrativos.

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

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                              % minutos desde el inicio del escenario
persona(Persona, Rol, Turno).
turno(Turno, MinutoInicio, MinutoFin).
permiso(Rol, Zona, Turno).                  % qué rol entra a qué zona en qué turno
puerta(Puerta, ZonaOrigen, ZonaDestino, ModoFalla, Tipo).  % ModoFalla: seguro | abierto
                                                            % Tipo: normal | salida_emergencia
credencial(Tarjeta, Persona, Estado, DesdeMinuto).  % Estado: activa | reportada | revocada
sincronizada(Puerta, Minuto).               % última vez que la puerta habló con el servidor
evento(Puerta, Lector, Tarjeta, Resultado, MinutoLector, MinutoLlegada).
lectura(Puerta, Sensor, Valor, Minuto).     % Sensor: contacto | paso | energia | alarma
rango(Sensor, Minimo, Maximo).              % rango físico de cada sensor
excepcion(Persona, Puerta, Motivo, DadaPor, Desde, Hasta).  % cobertura, orden de trabajo...
traslado(Puerta1, Puerta2, Minutos).        % tiempo mínimo a pie entre dos puertas
```

Sin reglas. Las reglas del negocio las dicta el estudiante en español y las escribe él.
El azar no entra en las reglas: un retraso o un desfase entra como hecho o como supuesto.

## Contrato del gemelo

- `decide(+Intento, -Decision, -Explicacion)` — predicado central. `Intento` identifica un
  acceso solicitado (tarjeta, puerta, lector, minuto). `Decision` dice abrir, negar o
  abrir y alertar; si no se sabe, aplica la política declarada para la duda.
  `Explicacion` es una lista de hechos y condiciones, e incluye qué reglas chocaron y cuál
  se impuso (el desempate).
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre una persona,
  una tarjeta o una puerta (por ejemplo derecho vigente, persona dentro, puerta
  desactualizada, uso incompatible, forzada, tailgating, sin salida), consultables en
  cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de puertas y personas, quién está dentro, la decisión
  con su explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Derecho vigente.** La misma tarjeta activa abre en el turno de su dueño y se niega
   fuera de él, con la razón. Una excepción vigente cambia el resultado y la
   explicación la nombra; una excepción dada por quien no podía darla o ya vencida no.
   La consulta inversa dice qué cambiaría el veredicto.
2. **Orden de eventos.** Con un evento de salida que llega tarde, el gemelo ordena por
   el instante del lector y distingue a quien salió de quien reutiliza la tarjeta. Si
   el orden no se puede determinar, responde «no se sabe» y aplica la política
   declarada, nunca un sí o un no silencioso. Dice quién está dentro.
3. **Revocación y puertas sin conexión.** Distingue lo que sabe el servidor de lo que
   sabe cada puerta: lista las puertas que aún aceptarían la tarjeta y señala los usos
   incompatibles entre sí con la evidencia. Con una revocación supuesta antes del primer
   uso, la respuesta cambia y la explicación dice por qué.
4. **Emergencia.** Con incendio y sin energía, cada persona dentro obtiene una ruta de
   salida o el aviso de que no tiene ninguna. Una salida de emergencia abre aun para una
   tarjeta revocada y el hecho queda registrado y alertado; la entrada protegida sigue
   cerrada. La explicación nombra las dos reglas que chocaron y a quién se le falló.
5. **Puerta anómala.** Forzada, tailgating, abierta de más y apertura con excepción dan
   cuatro veredictos distintos con su evidencia. Una puerta sin lectura de contacto
   da «no se sabe», distinto de «cerrada», y no dispara una alerta falsa de forzada.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el plano de puertas con su
estado (incluido «no se sabe»), quién está dentro, el intento con su decisión y su
explicación, las puertas desactualizadas y las alertas. Debe verse bien en celular.
