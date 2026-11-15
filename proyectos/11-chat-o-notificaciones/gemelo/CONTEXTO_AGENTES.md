# Contexto para agentes — gemelo digital del proyecto #11 (Chat o notificaciones)

Este archivo es para el agente (OpenCode u otro) que acompaña al estudiante. Léelo
completo, junto con [`PROBLEMA.md`](PROBLEMA.md) y
[`../problema/readme.md`](../problema/readme.md), antes de proponer cualquier cosa.

## Tu papel

- El proyecto es individual y se califica el razonamiento del estudiante. **Explica,
  pregunta y propone; no entregues la solución completa.**
- Antes de escribir una regla, pide al estudiante que la diga en español.
- Primero la prueba plunit, después la regla.
- Trabaja una situación a la vez, en el orden de `PROBLEMA.md`.
- No inventes cifras. Las del dominio vienen del problema original; cualquier otra se
  marca como supuesto y se le pide al estudiante la fuente.

## Dominio

| Término | Significado |
|---|---|
| Centro de mando | Protección Civil de un incendio forestal en Tecate; **inventado** por esta extensión, no existe |
| Mando | Rol que emite órdenes y ve todo el historial; hay coordinadora y subcoordinador |
| Sala | Canal del chat: mando, brigada (Norte o Sur), albergue o informativa |
| Turno | Periodo de 12 horas durante el cual alguien pertenece a una unidad (dato del escenario) |
| Orden | Mensaje del mando dirigido a una brigada: evacuar, retirarse o mantener posición |
| Sustituida | Orden que otra posterior dejó sin vigencia |
| Recibo de entrega | Lo genera el dispositivo al recibir el mensaje |
| Recibo de lectura | Lo genera quien abre la sala en un dispositivo, que puede ser compartido |
| Acuse | La persona toca «enterado» con su propio usuario |
| Nota del operador | Confirmación por voz que captura el operador de radio |
| Latido | Señal periódica del dispositivo; sirve para saber si sigue conectado |
| Push | Notificación a un dispositivo desconectado; no confirma que llegó |
| Reservado | Mensaje cuyo contenido (la ruta de retirada) no debe salir de la brigada |
| Acceso de emergencia | Excepción de 30 minutos para el enlace sanitario, sin escritura |

Cifras de referencia, todas del problema original: latido de unos 30 a 60 segundos;
grupos de hasta 200 miembros (aquí se reducen a 11 personas); un usuario que vuelve tras
6 horas con 300 mensajes pendientes; el push no es confiable ni inmediato. Todo lo demás
(personas, salas, turnos de 12 horas, el acceso de 30 minutos, los 20 y los 4 minutos,
el reglamento (a)-(h)) es **inventado por esta extensión**: son datos del ejercicio, no
estadísticas. Lo que el estudiante fije (desfase de relojes tolerado, cuánto silencio de
latido es dudoso, qué es «casi simultáneo», rango dentro del mando, qué regla gana en
cada choque) es supuesto suyo.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar mensajes simulados o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundo).                         % segundos desde las 00:00 del día del incidente
persona(Persona, Rol).                  % mando | jefe | brigadista | voluntario | enlace_sanitario
                                        % | prensa | operador
turno(Persona, Inicio, Fin).
asignacion(Persona, Unidad, Desde).     % Unidad: mando | norte | sur | albergue | ninguna
zona(Brigada, Zona, Desde).             % una brigada trabaja en una zona a la vez
sala(Sala, Tipo, Unidad).               % Tipo: mando | brigada | albergue | informativa
pertenencia(Persona, Sala, Ingreso, Salida).   % Salida puede faltar
usa(Persona, Dispositivo).              % un dispositivo puede tener varios usuarios
mensaje(Id, Sala, Autor, Tipo, Clave, SelloDispositivo, SelloServidor).
                                        % Tipo: aviso | orden | publico | reservado
                                        % SelloServidor puede faltar
orden(Id, Accion, Brigada).             % Accion: evacuar | retirarse | mantener
evento(Suceso, Sujeto, Detalle, Segundo).   % entregado | leido | acuse | latido | voz |
                                        % solicitud | concesion | ingreso | salida
```

Sin reglas. Las reglas del negocio las dicta el estudiante en español y las escribe él.
El azar no entra en las reglas: un apagón, un retraso o un desfase entre relojes entra
como hecho o como supuesto.

## Contrato del gemelo

- `decide(+Consulta, -Decision, -Explicacion)` — predicado central. `Consulta` es una
  solicitud concreta (ver o escribir en una sala, qué orden rige para una brigada, si una
  persona está enterada de una orden, qué muestra a quien regresa, un acceso de
  emergencia); el estudiante fija su forma. `Decision` es conceder, negar, conceder en
  parte, o «no se sabe» con la política declarada. `Explicacion` es una lista de hechos y
  condiciones e incluye qué reglas chocaron y cuál se impuso (el desempate), nombrando a
  quién se le falló.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre una persona,
  un mensaje, una orden o una sala (por ejemplo miembro vigente, puede escribir,
  sustituida, enterada, respaldada), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: quién ve y escribe en cada sala, la decisión con su
  explicación, «qué falta para que cambie», la bitácora de accesos y la respuesta a
  hipótesis («si Marisol hubiera salido de Sur en el cambio de turno»).

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Permisos.** Alguien con turno vencido, alguien reasignado de zona y alguien externo
   reciben un «no» con la condición que falla; ver y escribir se concluyen por separado.
   Quitando una condición a la vez, la consulta inversa dice qué cambio habilita a cada
   uno.
2. **Dos órdenes.** El reintento de una misma clave no cuenta como una orden nueva. Entre
   dos órdenes contradictorias de mando, la decisión nombra la regla que se impuso, a
   quién se le falló y qué se le avisa. Si el orden de llegada no se puede determinar por
   los relojes, responde «no se sabe» y aplica la política declarada, no un resultado
   silencioso.
3. **Entregado no es enterado.** Un recibo de lectura en un dispositivo compartido no da a
   nadie por enterado, y una nota del operador sí puede darlo aunque falten recibos. Un
   push sin recibo da «no se sabe», distinto de «no enterado». Cada veredicto lista su
   evidencia y la fuente que cerraría la duda.
4. **Regreso.** Los mensajes de antes del ingreso a una sala no se muestran; los de
   después de su salida tampoco, pero lo ya visto se conserva. Una orden sustituida se
   muestra marcada y no como vigente. Un mensaje sin sello del servidor cuya pertenencia
   no se puede establecer queda «en duda», no se muestra ni se oculta en silencio.
5. **Acceso de emergencia.** Un motivo sin respaldo al pedir da «no se sabe» y la política
   declarada decide. Cualquier decisión nombra a quién falla y por qué. Lo concedido no
   incluye escribir y vence. La bitácora responde quién vio lo reservado y con qué
   fundamento; la hipótesis de otra duración cambia la respuesta.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar las salas con sus miembros
(quién ve y quién escribe), las órdenes vigentes y sustituidas por brigada, la lista de
enterados con su evidencia, el historial que ve cada persona al regresar, las solicitudes
de acceso con su decisión y la bitácora, y la respuesta a «qué falta». Debe verse bien en
celular.
