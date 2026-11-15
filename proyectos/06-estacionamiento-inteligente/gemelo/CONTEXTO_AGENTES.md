# Contexto para agentes — gemelo digital del proyecto #6 (Estacionamiento inteligente)

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
| Cajón | Lugar para un auto; unidad que se asigna |
| Zona | Grupo de cajones dentro de un nivel |
| Rampa | Paso entre niveles, con barrera; ahí se cuentan entradas y salidas |
| Acceso | Puerta peatonal hacia la que va el conductor |
| Deriva | Error que acumula el conteo de rampas con el tiempo |
| Reserva | Apartado temporal de un cajón; expira |
| Tarifa dinámica | Precio que sube con la ocupación |
| Falso positivo / negativo | El sensor dice ocupado y está libre / dice libre y está ocupado |

Cifras de referencia: deriva de 1 evento fallido cada 200; un estacionamiento puede
llenarse en 30-40 min; tarifa dinámica al pasar de ~85 % de ocupación (1 de cada 7
cajones libre); llegada de 300 autos en 20 minutos; 5 % de sensores con falla; reserva
con expiración a 10 minutos; sensor «ocupado» por 3 días seguidos.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar llegadas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).
zona(Zona, Nivel).
cajon(Cajon, Zona).
distancia(Cajon, Acceso, Metros).
sensor(Cajon, Estado, DesdeMinuto).        % Estado: libre | ocupado
reserva(Cajon, Conductor, MinutoInicio).
fuera_de_servicio(Cajon).
solicitud(Conductor, Acceso, Minuto).
evento_rampa(Rampa, Nivel, Tipo, Minuto).  % Tipo: entrada | salida
tarifa_base(Zona, Monto).
```

## Contrato del gemelo

- `decide(+Solicitudes, -Asignacion, -Explicacion)` — predicado central. `Solicitudes`
  es una lista de conductores (puede ser de uno); `Asignacion` empareja cada conductor
  con un cajón distinto; `Explicacion` justifica cada pareja. Al pedir más soluciones
  debe dar los demás repartos válidos.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre un cajón,
  una zona o un nivel (por ejemplo sensor sospechoso, conteos que no cuadran, reserva
  invadida, zona saturada), consultables en cualquier dirección.
- El estado de un cajón distingue tres resultados: libre, ocupado, no se sabe.
- La API expone al menos: el estado de los cajones, la asignación con su explicación y
  «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Asignación.** Con dos solicitudes que prefieren el mismo cajón, ambas reciben
   cajón y son distintos; la explicación dice por qué una no obtuvo su preferido. Con
   más solicitudes que cajones disponibles, el gemelo lo dice en vez de fallar en
   silencio. Nunca asigna un cajón reservado vigente, en duda o fuera de servicio.
2. **Sensor sospechoso.** Un cajón «ocupado» por demasiado tiempo queda como «no se
   sabe», distinto de «ocupado» y de «libre», con la evidencia.
3. **Conteos.** En un nivel donde rampas y cajones no cuadran, el gemelo reporta la
   diferencia, la fuente que eligió y la razón; donde cuadran, lo confirma.
4. **Reserva.** Una reserva vigente bloquea el cajón; una expirada lo libera. Un cajón
   reservado y ocupado produce una situación propia, no se trata como ocupación normal.
5. **Saturación.** La ocupación de una zona se calcula con una política declarada sobre
   reservados, dudosos y fuera de servicio; la consulta inversa dice cuántos cajones
   faltan para cruzar el límite, y funciona con llegadas supuestas.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el mapa de cajones con su
estado (incluido «no se sabe»), las solicitudes pendientes, la asignación propuesta con
su explicación y la ocupación por zona. Debe verse bien en celular.
