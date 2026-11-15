# Contexto para agentes — gemelo digital del proyecto #24 (Cruce CBX / puente peatonal)

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
| Módulo | Etapa del cruce por la que pasa toda persona, en serie: venta/validación, revisión migratoria e inspección aduanera |
| Ventanilla | Puesto de atención dentro de un módulo; atiende una persona a la vez |
| Tiempo de servicio | Minutos que una ventanilla tarda con una persona; varía de 1 a 5 |
| Tope por hora | Límite de personas por hora que un módulo puede atender |
| Tramo | Espacio entre un módulo y el siguiente donde espera quien ya terminó el primero |
| Bloqueo (propagación hacia atrás) | Un módulo lento llena su tramo y deja sin salida al módulo anterior |
| Capacidad efectiva | Lo que un módulo atiende de verdad, que puede ser menos que lo que el plan dice abierto |
| Espera estimada | Minutos que se calcula que esperará quien llega ahora; no se mide, se deduce |
| Prioridad | Trato preferente a tripulaciones, personas con discapacidad y adultos mayores |
| Pase vigente | Pase de abordar o itinerario aéreo que da derecho a usar el puente |
| Bloque de vuelos | Vuelos cercanos en el itinerario que concentran la demanda |

Cifras de referencia, todas del problema original: 3 módulos en serie; 2 a 6 ventanillas
por módulo; 600 personas por hora en pico; un vuelo que llega con 180 pasajeros al mismo
tiempo; 1 a 5 minutos por persona; puente de unos 390 metros. El personal del turno, el
tope por hora, la capacidad de cada tramo, que la prioridad conste o no y la hora del
vuelo de cada persona son complementos de esta extensión, no datos reales.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar llegadas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Las llegadas y los tiempos de servicio entran como hechos, no se sortean.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                          % minutos desde las 0:00 de la jornada
modulo(Modulo, Posicion).               % Posicion: 1, 2, 3 en la serie
ventanilla(Ventanilla, Modulo).
personal(Persona, Modulo).              % puede cubrir ese módulo; puede aparecer en varios
limite_hora(Modulo, Personas).          % tope de personas por hora
tramo(Modulo, Capacidad).               % personas que caben entre ese módulo y el siguiente
vuelo(Vuelo, Tipo, Minuto, Pasajeros).  % Tipo: llegada | salida
orden(Ventanilla, Estado, Minuto).      % abierta | cerrada, según el plan; no es lo observado
persona(Persona, Vuelo, Prioridad, Consta). % Prioridad: ninguna | tripulacion | discapacidad | adulto_mayor; Consta: si | no
rango(Variable, Minimo, Maximo).        % por ejemplo, tiempo de servicio
lectura(Entidad, Variable, Valor, Minuto). % fila, atenciones terminadas, tiempo de servicio
evento(Minuto, Tipo, Entidad, Detalle). % llega_persona | atencion_terminada | cierre_ventanilla
```

## Contrato del gemelo

- `decide(+Solicitudes, -Reparto, -Explicacion)` — predicado central. `Solicitudes` es la
  lista de lo que pide capacidad (módulos por tramo de la hora, o personas en una fila;
  puede ser de uno); `Reparto` empareja cada solicitud con las ventanillas y el personal
  que se le asignan, o con su turno en el orden de atención; `Explicacion` justifica cada
  pareja. Al pedir más soluciones debe dar los demás repartos válidos. Si no existe
  ninguno, lo dice y señala el motivo (qué módulos y qué límites), sin fallar en
  silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre un módulo,
  una ventanilla o una persona (por ejemplo carga que no alcanza, ventanilla dudosa,
  módulo bloqueado, espera sin base), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de los módulos y las ventanillas, el reparto con su
  explicación, la espera estimada con su base, y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Vuelo grande.** Con el itinerario dado, el gemelo deduce la carga esperada por
   módulo con su desfase, marca los módulos que no alcanzan con lo abierto y da los
   repartos válidos de ventanillas y personal, nunca más de lo que el personal permite.
   Si no hay reparto, lo dice, señala qué módulos y qué límites lo causan y ofrece
   opciones imperfectas nombrando qué se sacrifica en cada una.
2. **Ventanilla apagada.** Una abierta en el plan que no registra atenciones no se
   declara cerrada sin más: el veredicto es «atiende», «cerrada» o «no se sabe» según la
   evidencia, y «no se sabe» es distinto de «cerrada». La capacidad efectiva del módulo
   se calcula bajo cada posibilidad.
3. **Bloqueo.** Un módulo lento que llena su tramo hace aparecer como bloqueados a los
   anteriores, en cadena hasta la entrada, y la evidencia nombra el origen. Abrir
   ventanillas en un módulo bloqueado no se propone como solución; abrirlas en el origen,
   sí. La consulta inversa dice qué tendría que cambiar para que el bloqueo desaparezca.
4. **Prioridad contra vuelo.** Con una persona prioritaria y otra cuyo vuelo sale pronto
   se obtiene un orden completo; la explicación nombra el criterio que decidió y a quién
   se le falla. Una prioridad que no consta queda en «no se sabe», ni cierta ni falsa, y
   la consulta inversa dice qué tendría que cambiar para que el orden fuera el contrario.
5. **Espera.** La espera de quien llega ahora se deduce con su cálculo explicado y cuenta
   bloqueos, adelantamientos y llegadas próximas. Con pocas observaciones recientes el
   gemelo contesta «no lo sé» y dice qué faltaría, en lugar de dar un número. La
   hipótesis «si abro una ventanilla» cambia la espera con las mismas reglas.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar los tres módulos en serie
con sus ventanillas (abiertas, atendiendo, dudosas o caídas), las filas y los tramos con
los bloqueos marcados, el reparto propuesto con su explicación, el orden de atención, la
espera publicada con su base (o «no lo sé») y la respuesta a «qué falta». Debe verse bien
en celular.
