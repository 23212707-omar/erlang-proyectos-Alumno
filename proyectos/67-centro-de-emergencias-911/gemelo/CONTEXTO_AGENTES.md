# Contexto para agentes — gemelo digital del proyecto #67 (Centro de emergencias 911)

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
| Incidente | Hecho que requiere atención; puede tener varias llamadas |
| Llamada | Aviso de una persona; puede ser duplicada, improcedente o parte de un incidente |
| Prioridad | 1 riesgo inminente de vida, 2 urgente, 3 no urgente |
| Unidad | Recurso de despacho de un tipo: ambulancia, patrulla, bomberos, protección civil |
| Estados de la unidad | disponible, despachada, en camino, en escena, trasladando, fuera de servicio |
| Más cercana | Menor tiempo de viaje por la red, no menor distancia en línea recta |
| Retirar | Quitar una unidad ocupada de su incidente por orden de prioridad superior |
| Garita, cañón | Obstáculos que alargan el viaje aunque la distancia sea corta |

Cifras de referencia, todas del problema original: 40 unidades de 4 tipos y 200
incidentes en un turno de 8 horas; accidente múltiple con 12 llamadas; ambulancia a 1 km
frente a otra a 3 km; contestar 90 % de las llamadas en 10-15 s; primera unidad de
bomberos en ~4 min y soporte vital avanzado en ~8 min (referencias internacionales, no
reglas del 911 de México). Son órdenes de magnitud.

Los términos y números del escenario reducido (8 unidades, 4 zonas, tiempos de tramo,
identificadores) son del ejercicio, no estadísticas. Las metas de respuesta por
prioridad y los demás umbrales los define el estudiante: el original no los da.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar llamadas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Si el escenario necesita azar (por ejemplo, cuándo reaparece una unidad), entra como
  hecho o queda como supuesto del estudiante.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundo).                         % segundos desde que empieza el turno
unidad(Unidad, Tipo).                   % Tipo: ambulancia | patrulla | bomberos | proteccion_civil
estado_unidad(Unidad, Estado).          % disponible | despachada | en_camino | en_escena | trasladando | fuera_de_servicio
posicion(Unidad, Punto, Segundo).       % reporte de posición con su instante
tramo(PuntoA, PuntoB, SegundosViaje).   % arista de la red con su tiempo de viaje
zona(Punto, Zona).                      % a qué zona pertenece un punto
incidente(Incidente, Tipo, Punto, Prioridad).
requiere(TipoIncidente, TipoUnidad, Cantidad).  % lo fija el estudiante
llamada(Llamada, Punto, Segundo, Reporte).      % Reporte: tipo y lo que dice ver
asignacion(Unidad, Incidente, Segundo).
evento(Entidad, Evento, Segundo).       % bitácora: despachada, retirada, sin_contacto, llego...
```

## Contrato del gemelo

- `decide(+Incidentes, -Despacho, -Explicacion)` — predicado central. `Incidentes` es la
  lista de incidentes por atender (puede ser de uno); `Despacho` empareja cada incidente
  con sus unidades, sin repetir ninguna unidad, e indica qué incidente queda desplazado o
  sin cubrir; `Explicacion` justifica cada pareja. Al pedir más soluciones debe dar los
  demás repartos válidos. Si no existe ninguno completo (no alcanzan las unidades), lo
  dice y señala el motivo, sin fallar en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre una
  llamada, una unidad o un incidente (por ejemplo llamada del mismo incidente, unidad sin
  contacto, incidente desprotegido, unidad retirable), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de unidades e incidentes, el despacho con su
  explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Retiro.** Con todas las ambulancias ocupadas y un incidente de prioridad 1, el
   gemelo elige una que se pueda retirar según la prioridad superior y el estado,
   explica por qué no las otras, y deja el incidente desplazado como pendiente, nunca
   perdido. Con prioridades iguales o menores, no retira a nadie y lo dice.
2. **Cercanía.** La unidad elegida es la de menor tiempo de llegada por la red, con su
   ruta, aunque otra esté más cerca en línea recta; cuenta cuándo queda libre una unidad
   ocupada. Si se afecta un tramo, la respuesta puede cambiar y la explicación dice por qué.
3. **Duplicados.** Llamadas que coinciden en lugar, tiempo y relato se agrupan en un
   incidente con la evidencia. Una llamada con indicios insuficientes aparece como «no se
   sabe», ni unida ni descartada. El incidente unido toma su prioridad y sus unidades
   de la información de todas las llamadas.
4. **Unidad sin contacto.** Una unidad «en camino» sin reportes recientes no se da por
   llegada ni por perdida: el gemelo contesta «no se sabe», con la última posición y su
   antigüedad. La consulta inversa dice qué tendría que pasar para pedir refuerzo, y qué
   incidente quedaría descubierto. Si la unidad reaparece, la respuesta se corrige.
5. **Crisis.** Con más incidentes que unidades, ninguna unidad se asigna dos veces y la
   prioridad pesa. Se obtienen los demás repartos válidos. Cuando un reparto «voraz» deja
   sin cubrir un incidente que otro reparto cubre, el gemelo encuentra el segundo. Si
   ninguno cubre todo, dice cuáles quedan sin cubrir y por qué.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el mapa o la lista de
zonas y puntos con las unidades y su estado, los incidentes abiertos por prioridad, el
despacho con su explicación (ruta y tiempo estimado de cada unidad), las llamadas
agrupadas con las dudosas marcadas, las unidades sin contacto con la antigüedad de su
último reporte, y la respuesta a «qué falta». Debe verse bien en celular.
