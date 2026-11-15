# Contexto para agentes — gemelo digital del proyecto #23 (Puertas de abordar)

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
| Puerta (*gate*) | Posición de la terminal donde una aeronave recibe a sus pasajeros; unidad que se asigna |
| Posición remota | Lugar fuera de la terminal; los pasajeros llegan en autobús |
| Rotación (*turnaround*) | Tiempo entre que la aeronave llega a la puerta y se va |
| Abordaje | Tramo de la rotación en que suben los pasajeros |
| Colchón | Margen de seguridad que la puerta debe estar libre además de la rotación |
| Ocupación | Intervalo en que un vuelo retiene una puerta; cambia con las demoras |
| Traslape | Dos vuelos que, según su ocupación, necesitan la misma puerta a la vez |
| Alcance | Nacional o internacional; el segundo requiere puerta con aduana |
| Reasignación en cadena | Mover un vuelo obliga a mover otros |
| Operador | Persona que asigna o reasigna puertas; dos pueden actuar a la vez |
| Anuncio | Aviso de la puerta a los pasajeros por pantallas, altavoces y apps |

Cifras de referencia, todas del problema original: 8 puertas, 60 vuelos y 3 tipos de
aeronave en el escenario; rotación de 40-60 min y abordaje de 25-35 min en un vuelo
angosto de ~150-190 pasajeros; una puerta fuera de servicio a medio día; dos vuelos
demorados que compiten por la misma puerta. Los tipos de aeronave por nombre, el aviso de
rampa y los operadores con su turno son complementos de esta extensión, no datos reales.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar demoras simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                          % minutos desde las 0:00 de la jornada
puerta(Puerta, Posicion, Zona, Tamano). % Posicion: contacto | remota; Zona: nacional | internacional
fuera_de_servicio(Puerta, Desde, Hasta).% Hasta puede no conocerse
vuelo(Vuelo, Aerolinea, Aeronave, Alcance, Pasajeros).
rotacion(Aeronave, MinMinutos, MaxMinutos).
horario(Vuelo, Tipo, Minuto).           % Tipo: llegada_prog | llegada_est | llegada_real | salida_prog | salida_est | salida_real
asignacion(Vuelo, Puerta, Operador, Minuto).  % orden registrada, no necesariamente vigente
anunciada(Vuelo, Puerta, Minuto).       % puerta ya informada a los pasajeros
preferencia(Aerolinea, Puerta).
evento(Fuente, Vuelo, Suceso, Minuto).  % Suceso: aeronave_en_puerta | aeronave_salio | abordaje_inicio
```

## Contrato del gemelo

- `decide(+Solicitudes, -Reparto, -Explicacion)` — predicado central. `Solicitudes` es la
  lista de vuelos por acomodar (puede ser de uno); `Reparto` empareja cada vuelo con una
  puerta o con la posición remota; `Explicacion` justifica cada pareja y cada vuelo
  movido. Al pedir más soluciones debe dar los demás repartos válidos. Si no existe
  ninguno, lo dice y señala el motivo (qué vuelos y qué restricciones), sin fallar en
  silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre una puerta,
  un vuelo o un par de vuelos (por ejemplo traslape, vuelo arrastrado, orden en
  conflicto, aviso pendiente), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de las puertas y los vuelos, el reparto con su
  explicación, «qué falta para que cambie» y a quién hay que avisar.

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Traslape.** Dos vuelos cuya ocupación se cruza por la demora del primero aparecen en
   conflicto, con el tramo de cada uno como evidencia. Si la hora de salida del primero
   no está confirmada, el resultado es «no se sabe», distinto de «sin conflicto». Sin
   la demora, el conflicto desaparece.
2. **Cadena.** Al salir de servicio una puerta, el gemelo lista también los vuelos que
   ninguna regla toca directamente pero que quedan arrastrados, separa los movimientos
   forzados de los opcionales, y nunca propone una puerta incompatible. Si hay varios
   planes, los da todos y dice cuál conviene según la política declarada por el
   estudiante, que queda escrita.
3. **Dilema.** Con dos vuelos que no caben en la misma puerta, ambos reciben respuesta;
   uno no obtiene la puerta; la explicación nombra el criterio que decidió y lo que se le
   ofrece al otro. La consulta inversa dice qué tendría que cambiar para que ganara el
   otro.
4. **Sin solución perfecta.** Con más puertas que vuelos pero sin reparto válido, el
   gemelo dice que no existe, señala el grupo de vuelos y las restricciones que lo
   causan, y ofrece alternativas imperfectas nombrando qué se sacrifica en cada una. Una
   puerta con fin de mantenimiento desconocido no se usa como libre ni se descarta en
   silencio: queda «no se sabe».
5. **Operadores.** Dos órdenes sobre la misma puerta al mismo tiempo se detectan como
   incompatibles. El gemelo da un veredicto por orden (vigente, desplazada o no se sabe),
   nunca deja a dos vuelos en la misma puerta, trata el aviso de rampa contra el
   registro de salida como un choque de fuentes, y lista a quién avisar distinguiendo a
   quien ya había recibido el anuncio.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar las puertas en el tiempo
(quién las ocupa y cuándo, con los traslapes y los datos dudosos marcados), el reparto
propuesto con su explicación, los avisos pendientes y la respuesta a «qué falta».
Debe verse bien en celular.
