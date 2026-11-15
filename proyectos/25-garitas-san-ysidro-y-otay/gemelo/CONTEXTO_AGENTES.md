# Contexto para agentes — gemelo digital del proyecto #25 (Garitas San Ysidro y Otay)

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
| Garita | Cruce hacia el norte: San Ysidro u Otay Mesa |
| Carril | General, Ready Lane (documentos con RFID), SENTRI (viajero confiable) y, en Otay, FAST (comercial) |
| Carriles hermanos | Carriles de la misma garita; comparten cabinas, incidentes y revisiones |
| Espera | Minutos que tarda un vehículo en la fila de un carril; se mide o se estima, nunca es un hecho puro |
| Lectura propia | Medición del sistema de un carril, una cada 15 minutos |
| Feed oficial | Dato publicado por la agencia CBP; se actualiza cada 1 o 2 horas y va atrasado |
| Incidente | Suceso que dispara la espera (cabinas cerradas, revisión, falla); no lo mide ningún sensor |
| Traslado | Tiempo de la zona de origen a la garita; arista del mapa |
| Ruta | Zona → garita → carril, con hora de salida y de llegada |
| Credencial | Documento que habilita un carril; vigente, vencida o que no consta |
| Inferencia | Valor deducido de otros, nunca presentado como lectura |

Cifras de referencia, todas del problema original: 2 garitas y 3 tipos de carril (más FAST
en Otay); una lectura por carril cada 15 minutos; feed oficial cada 1 o 2 horas; esperas
de más de 3 horas en pico; incidente que lleva la espera de 40 a 150 minutos en 30; carril
sin reportar por 2 horas; historia del mismo día y hora de hace 4 semanas. Inventados
por esta extensión, no datos reales: los 7 carriles y 3 zonas de la escala reducida, los
traslados, las credenciales de cada ocupante, qué credencial habilita qué carril y que
todos los ocupantes deban cumplirlo.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Las lecturas y los incidentes entran como hechos, no se sortean.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                          % minutos desde las 0:00 de la jornada
carril(Carril, Garita, Tipo).           % Tipo: general | ready | sentri | fast
traslado(Zona, Garita, Minutos).        % arista del mapa; puede faltar entre algunas zonas
rango(Variable, Minimo, Maximo).        % por ejemplo, espera creíble
lectura(Carril, Fuente, Espera, Minuto). % Fuente: propia | oficial; Espera en minutos
historia(Carril, Semana, Minuto, Espera). % mismo día y hora de semanas anteriores
cabinas(Garita, Abiertas, Minuto).      % cuántas cabinas abren y desde cuándo
viaje(Viaje, Zona, Tipo, Minuto).       % Tipo: auto | carga; Minuto: cuándo pide la ruta
ocupante(Viaje, Persona).
credencial(Persona, Tipo, Estado).      % Tipo: ready | sentri | fast; Estado: vigente | vencida | no_consta
evento(Minuto, Tipo, Entidad, Detalle). % sin_reporte | incidente_confirmado | recomendacion | cruce
```

## Contrato del gemelo

- `decide(+Solicitudes, -Ruta, -Explicacion)` — predicado central. `Solicitudes` es la
  lista de viajes que piden ruta (puede ser de uno); `Ruta` es el plan completo de cada
  uno (zona, garita, carril, hora de salida y hora estimada de cruce); `Explicacion`
  justifica cada paso con los hechos que lo sustentan y la base de la espera. Al pedir
  más soluciones debe dar las demás rutas válidas. Si no existe ninguna (carril
  comercial sin lectura, traslado inexistente, credencial que no alcanza), lo dice y
  señala el motivo, sin fallar en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre un carril,
  una garita o un viaje (por ejemplo espera sabida, inferida o dudosa; incidente;
  carril permitido; recomendación auditada), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: la espera por carril con su base, la ruta con su explicación,
  los avisos con su justificación, y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Fuentes y silencio.** Con una lectura propia reciente y un dato oficial viejo que
   discrepan, la espera de ese carril se justifica con su base y su edad. Un carril sin
   reportar queda como «inferido» desde sus hermanos y la historia, marcado como
   inferencia, o «no lo sé» si no hay base; nunca como una fila corta ni como lectura.
2. **Salto y aviso.** Un salto de un solo carril, con hermanos tranquilos, no alcanza para
   declarar incidente; un salto de toda la garita con menos cabinas, sí. La decisión de
   avisar nombra a quién se le falla y qué observación resolvería la duda.
3. **Carril permitido.** La credencial que no consta deja al carril SENTRI «condicionado»,
   ni permitido ni prohibido; una vencida lo prohíbe. Un camión de carga solo recibe
   rutas por un carril comercial. La consulta inversa dice qué tendría que constar.
4. **Ruta.** La espera que se usa es la proyectada a la hora de llegada, no la de ahora.
   Con un incidente reciente en una garita, la ruta con menor espera actual puede quedar
   detrás de otra, y la explicación recorre la cadena que lo causó. Las rutas
   equivalentes se declaran indistinguibles.
5. **Auditoría.** Con el «ahora» de la recomendación, el gemelo usa solo lo sabido
   entonces y emite uno de tres veredictos: justificada, mal razonada o debió abstenerse,
   con las lecturas que lo sustentan. Un resultado malo no implica por sí solo un error.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar las dos garitas con sus
carriles y la espera de cada uno con su base (sabida, inferida o «no lo sé») y su edad,
los avisos con su justificación, la ruta propuesta y sus alternativas, y la respuesta a
«qué falta». Debe verse bien en celular y distinguir con color y texto entre lectura e
inferencia.
