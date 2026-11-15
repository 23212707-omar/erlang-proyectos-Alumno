# Contexto para agentes — gemelo digital del proyecto #16 (Broker MQTT simple)

Este archivo es para el agente (OpenCode u otro) que acompaña al estudiante. Léelo
completo, junto con [`PROBLEMA.md`](PROBLEMA.md) y
[`../problema/readme.md`](../problema/readme.md), antes de proponer cualquier cosa.

## Tu papel

- El proyecto es individual y se califica el razonamiento del estudiante. **Explica,
  pregunta y propone; no entregues la solución completa.**
- Antes de escribir una regla, pide al estudiante que la diga en español.
- Primero la prueba plunit, después la regla.
- Trabaja una situación a la vez, en el orden de `PROBLEMA.md`.
- No inventes cifras. Las de dominio vienen del problema original; cualquier otra se
  marca como supuesto y se le pide al estudiante la fuente.
- El escenario («Marina Punta Neblina», sus personas, su reglamento, sus plazos y topes)
  es inventado por la extensión. No lo presentes como un caso real ni le atribuyas
  estadísticas.

## Dominio

| Término | Significado |
|---|---|
| Tema | Nombre jerárquico de un dato, por niveles, p. ej. `marina/muelleA/A2/achique` |
| Filtro | Lo que pide un suscriptor; puede llevar comodines: uno de un nivel, otro de todos los niveles restantes |
| QoS | Garantía de entrega: 0 a lo más una vez; 1 al menos una vez, con confirmación (puede haber duplicados) |
| Sesión persistente | El broker conserva suscripciones y mensajes QoS 1/2 de un cliente desconectado |
| Retained | Último valor de un tema, guardado para quien se suscriba después |
| Last Will | Mensaje que el broker publica si un cliente muere sin despedirse |
| Keep-alive | Intervalo en que el cliente debe dar señal; el broker lo desconecta a 1.5 veces |
| Pasarela | Cliente que publica los sensores de un muelle (inventado) |
| Asignación | Derecho de una persona sobre un amarre entre dos instantes (inventado) |
| Alarma | Suceso de achique con etapa: nueva, avisada, confirmada, escalada o resuelta (inventado) |

Cifras de referencia, todas del problema original: keep-alive con tolerancia de 1.5
veces; QoS 0, 1 y 2 (se usan 0 y 1); 3,000 clientes y 10,000 mensajes por segundo
como escala del original. Inventados por la extensión, no reales: keep-alive de 30 s
de las pasarelas, plazo de 10 minutos para confirmar una alarma y tope de 5 mensajes
pendientes por cliente; el reglamento (a)-(g) está en `PROBLEMA.md`.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar eventos y lecturas simulados o graficar. Prolog nunca es una librería de
  Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  El gemelo no sortea reintentos ni pérdidas: razona sobre los que entran como hechos.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundo).                         % segundos desde el inicio del escenario
amarre(Amarre, Muelle).
vecina(Amarre1, Amarre2).               % amarres contiguos
cliente(Cliente, Rol).                  % capitan | propietario | huesped | contratista
                                        % | facturacion | pasarela
asignacion(Cliente, Amarre, Desde, Hasta).  % derecho sobre un amarre entre dos instantes
suscripcion(Cliente, Filtro, Qos).      % cómo se escribe el comodín lo decide el estudiante
mensaje(Id, Tema, Contenido, Qos, Retenido, Segundo).  % lo que circuló; Retenido: si | no
keepalive(Cliente, Segundos).
ultimo_paquete(Cliente, Segundo).       % la última señal que el broker recibió de él
evento(Cliente, Evento, Segundo).       % se_conecta | se_despide | cae | se_reconecta | ...
rango(Variable, Minimo, Maximo).        % valores físicamente posibles
lectura(Amarre, Variable, Valor, Segundo).  % lo que midió el sensor
```

La cola de cada cliente, si la pasarela está viva, qué alarmas hay abiertas y en qué
etapa, y quién recibe un mensaje **no son hechos**: se deducen. El tope de la cola, los
plazos y las prioridades son predicados que añade el estudiante con sus supuestos.

## Contrato del gemelo

- `decide(+Entidad, -Decision, -Explicacion)` — predicado central. `Entidad` es un
  mensaje, un filtro propuesto, una alarma o un cliente; `Decision` es lo que procede en
  el «ahora»: entregar o no a cada destinatario, aceptar o rechazar un filtro, a quién
  avisar o escalar, qué conservar en la cola. `Explicacion` es una lista de hechos,
  condiciones y reglas del reglamento que justifican la decisión, incluida la regla que
  perdió cuando hubo conflicto. Con la cola, `Decision` incluye el orden de entrega; al
  pedir más soluciones da las demás alternativas válidas; y si no existe ninguna, lo dice
  y señala el motivo, sin fallar en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  filtro que podría captar temas ajenos, retenido anterior a la estancia, pasarela caída,
  alarma sin confirmar, mensaje reemplazado), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado deducido de clientes y alarmas, la decisión con su
  explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Destinatarios.** Un mensaje llega solo a quien tiene un filtro que coincide con su
   tema y derecho vigente sobre el amarre; el contratista con la orden vencida y el
   huésped que pide todo el árbol no lo reciben, y la explicación dice en qué falló
   cada uno. Un filtro con comodín que cubre propios y ajenos no se trata como uno
   que cubre solo propios, y la consulta inversa lista los temas que podría captar.
2. **Retenidos.** Un mensaje retenido anterior a la llegada del huésped no se entrega
   aunque coincida con el filtro y hoy haya permiso. El que no tiene instante da «no se
   sabe», distinto de «no se entrega» y de «se entrega». La explicación nombra la fecha
   del derecho como causa.
3. **Silencio.** Una pasarela sin señal más allá de su tolerancia y sin despedida se
   deduce caída; la que se despidió, callada por aviso. En ambos casos, «no hay alarma»
   se contesta «no se sabe», nunca «no». Una lectura fuera de rango no cuenta como dato
   ni produce alarma. La respuesta indica qué evidencia falta.
4. **Dilema.** Con una alarma sin confirmar, la persona propietaria desconectada y
   contiguas en riesgo, la decisión nombra las dos reglas en choque, cuál prevalece, a
   quién se le falla y qué le cuesta; las tres repeticiones de una lectura cuentan como
   una alarma. Si la persona propietaria confirma, el mismo caso ya no escala. La
   consulta inversa dice qué tendría que cambiar para que el aviso a las contiguas no
   fuera necesario.
5. **Cola.** Con más mensajes que lugares, una alarma abierta nunca se descarta antes que
   una lectura reemplazada por otra más nueva, aunque sea más vieja. Los duplicados de
   un reintento cuentan una vez. Lo que se descarta queda informado al capitán, y las
   alarmas que compiten por el último lugar se desempatan con un criterio declarado.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar los amarres con sus
lecturas y su estado deducido (en calma, alarma, «no se sabe»), los clientes con su
sesión y lo que se les entrega, la decisión con su explicación, la cola de un cliente con
lo conservado y lo descartado, la línea de tiempo de eventos con las entradas en duda y
la respuesta a «qué falta». Debe verse bien en celular.
