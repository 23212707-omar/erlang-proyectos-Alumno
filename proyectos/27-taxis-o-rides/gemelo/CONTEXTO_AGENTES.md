# Contexto para agentes — gemelo digital del proyecto #27 (Taxis o rides)

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
| Celda | Hexágono del índice espacial (tipo H3); la zona se busca por celda y sus vecinas |
| Vecina | Celda contigua; el tiempo de viaje hacia ella puede no ser el mismo de ida que de vuelta |
| Conductor libre / asignado / en viaje | Estados de un conductor; solo el libre puede recibir una oferta |
| Solicitud | Petición de un pasajero con origen, asientos y accesibilidad requeridos |
| Oferta | Propuesta de una solicitud a un conductor; este tiene un plazo para aceptar |
| Candidato | Conductor que cumple estado, vigencia de posición, compatibilidad y llegada razonable |
| Posición vigente | Reporte lo bastante reciente para fiarse de él |
| Déficit de zona | Más demanda pendiente que oferta alcanzable; no lo mide ningún sensor |
| Nivel de tarifa | Normal o elevada en una celda; sube cuando la demanda supera a la oferta |
| Doble asignación | Un conductor comprometido con dos pasajeros; lo que el sistema nunca debe permitir |

Cifras de referencia, todas del problema original: posición cada 4-5 s; plazo de
asignación del pasajero ~10-30 s; plazo de aceptación del conductor ~10-15 s;
cancelaciones de 5-15 %; 2,000 conductores y 100 solicitudes por minuto; hexágonos de
resolución 8 de unos 0.74 km². La vecindad, los tiempos entre celdas, el canal con pocos
puentes, los asientos y la accesibilidad son inventados por esta extensión.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar solicitudes simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Las respuestas de los conductores (aceptar, rechazar, callar) entran como hechos, no se
  sortean.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundo).                         % segundos desde el inicio de la jornada de prueba
celda(Celda).
vecina(Celda1, Celda2, Segundos).       % tiempo de viaje base; puede ser distinto en cada sentido
conductor(Conductor, Asientos, Accesible). % Accesible: si | no
solicitud(Solicitud, Celda, Asientos, Accesible, Segundo). % Segundo: cuándo se pidió
rango(Variable, Minimo, Maximo).        % por ejemplo, plazos de oferta y de espera
lectura(Conductor, Variable, Valor, Segundo). % celda y estado, con el instante del reporte
evento(Segundo, Tipo, Entidad, Detalle). % oferta | acepta | rechaza | sin_respuesta | cancela | aborda | silencio
tarifa(Celda, Nivel).                   % Nivel: normal | elevada
```

## Contrato del gemelo

- `decide(+Solicitudes, -Reparto, -Explicacion)` — predicado central. `Solicitudes` es la
  lista de solicitudes pendientes (puede ser de una); `Reparto` empareja cada una con un
  conductor, con la siguiente oferta o con «sin conductor»; `Explicacion` justifica cada
  pareja y nombra a quién se le falla. Al pedir más soluciones debe dar los demás
  repartos válidos. Si no existe ninguno, lo dice y señala el motivo (qué solicitud, qué
  restricción), sin fallar en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre un conductor,
  una solicitud o una celda (por ejemplo candidato descartado, conductor dudoso, zona en
  déficit), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de conductores, solicitudes y celdas, el reparto con
  su explicación, y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Dos solicitudes.** Con un solo conductor cercano a ambas, el reparto nunca lo asigna
   a las dos; la explicación nombra el criterio y a quién se le falla, y se obtienen todos
   los repartos válidos. Si no hay ninguno, lo dice y señala el motivo.
2. **Candidato que no sirve.** El conductor más cerca en línea recta no aparece como
   candidato si el tiempo por la red lo deja fuera, y la explicación lo dice. Solo se
   miran la celda de la solicitud y sus vecinas hasta donde el estudiante fijó; los
   conductores no mirados se pueden listar. Un vehículo no accesible no entra para una
   solicitud accesible.
3. **Conductor callado.** El veredicto es «reasignar», «esperar» o «no se sabe» según la
   evidencia, y «no se sabe» es distinto de los otros dos. Nunca se reasigna a un pasajero
   que pudo estar a bordo sin decirlo. La consulta inversa dice qué dato cambiaría el
   veredicto.
4. **Plazos.** Con ofertas sin respuesta y rechazadas, el gemelo reconstruye quién sigue
   siendo válido y cuánto tiempo queda; si no cabe otra oferta, lo dice. Si se proponen
   ofertas simultáneas, ninguna combinación produce doble asignación.
5. **Concierto.** La oferta alcanzable de una zona descuenta ofertas pendientes y posiciones
   vencidas, y el déficit sale de contrastarla con la demanda, no de un solo número. La
   cancelación libera al conductor y el gemelo dice a quién pasa. La hipótesis «diez
   conductores más» cambia el veredicto con las mismas reglas, y la auditoría de una
   espera usa los hechos de ese momento.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el mapa de celdas con sus
conductores (libres, asignados, en viaje, dudosos) y las solicitudes pendientes, la
lista de candidatos con su tiempo y las razones de los descartados, el reparto propuesto
con su explicación y su cronología de ofertas, la tarifa y el déficit por zona, y la
respuesta a «qué falta». Debe verse bien en celular.
