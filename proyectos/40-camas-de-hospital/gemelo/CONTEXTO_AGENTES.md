# Contexto para agentes — gemelo digital del proyecto #40 (Camas de hospital)

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
| Servicio | Área del hospital que agrupa camas (medicina interna, cirugía, pediatría...) |
| Cama | Unidad que se asigna; tiene servicio y tipo |
| Tipo de cama | General, terapia intensiva, aislamiento, pediátrica... con reglas distintas |
| Alta indicada | El médico ordena que el paciente salga; la cama sigue ocupada hasta que salga |
| Motivo de espera | Lo que retrasa un alta: receta, transporte o familiares |
| Limpieza | Desinfección de la cama tras la salida; sin ella no vuelve a estar disponible |
| Tablero | Lo que el sistema muestra del estado de las camas; puede no coincidir con la realidad |
| Traslado interno | Paciente que pasa de una cama a otra; origen y destino quedan comprometidos |
| Ocupación | Fracción de camas ocupadas; la política de qué cuenta la fija el estudiante |
| Saturación | Ocupación tan alta que urgencias se llena y se cancelan cirugías |

Cifras de referencia, todas del problema original: ocupaciones superiores a ~85 % suelen
provocar saturación; limpieza típica de 30-60 minutos y, en el escenario, una de 2 horas;
el escenario completo tiene 120 camas en 6 servicios, 40 ingresos y 40 altas al día; las
altas se concentran por la tarde y los ingresos de urgencias llegan por la noche; México
tiene del orden de 1 cama por cada 1,000 habitantes frente a ~4 de promedio de la OCDE.
Las 15 camas y 5 servicios, los pacientes y los números de los ejemplos son del ejercicio,
no cifras del dominio.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar ingresos simulados o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).
cama(Cama, Servicio, Tipo).                  % Tipo: general | terapia | aislamiento | pediatrica
evento_cama(Cama, Evento, Minuto).           % Evento: ingreso | alta_indicada | salida | inicio_limpieza | fin_limpieza | bloqueo | desbloqueo
tablero(Cama, Estado, Minuto).               % lo que mostraba el tablero y desde cuándo
ocupa(Paciente, Cama).
perfil(Paciente, TipoRequerido).             % tipo de cama que pide la indicación médica
solicitud(Paciente, Origen, Minuto).         % Origen: urgencias | cirugia_programada | traslado
prueba_infeccion(Paciente, Estado, Minuto).  % Estado: pendiente | positiva | negativa
alta_pendiente(Paciente, Motivo, Minuto).    % Motivo: receta | transporte | familiares
traslado(Paciente, CamaOrigen, CamaDestino, Minuto).
```

## Contrato del gemelo

- `decide(+Solicitudes, -Reparto, -Explicacion)` — predicado central. `Solicitudes` es
  una lista de pacientes (puede ser de uno); `Reparto` empareja cada paciente con una cama
  distinta; `Explicacion` justifica cada pareja. Al pedir más soluciones debe dar los demás
  repartos válidos. Si no existe ninguno (más solicitudes que camas compatibles), lo dice
  y señala qué solicitud queda sin cama y por qué, sin fallar en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre una cama,
  un paciente o un servicio (por ejemplo cama no disponible aunque el tablero la marque
  libre, historia imposible, alta incierta, ocupación real, requiere aislamiento),
  consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de las camas, el reparto con su explicación, las
  camas seguras, posibles e imposibles a una hora dada, y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Reparto.** Con dos solicitudes que compiten por la misma cama, el gemelo da cama a
   ambos si existe un reparto que lo permite, aunque no siga el orden de llegada. Si no
   existe, dice quién queda sin cama, la razón de esa elección y qué lo cambiaría. Nunca
   asigna una cama de tipo incompatible, bloqueada, no disponible o en duda.
2. **Ciclo de la cama.** Una cama con alta indicada o en limpieza no es asignable aunque
   el tablero la marque libre, y la explicación nombra el paso que falta. Una historia de
   eventos imposible se reporta con el primer paso que la rompe, y para cualquier cama el
   gemelo dice qué pasos pueden seguir.
3. **Altas inciertas.** Las camas de una hora dada se clasifican en seguras, posibles e
   imposibles, y las posibles dicen de qué dependen. Un alta con motivo de espera
   no es lo mismo que una sin alta, y la hipótesis «el motivo no se resuelve» cambia la
   respuesta.
4. **Ocupación.** Un paciente en traslado cuenta una vez. La ocupación real y la aparente
   se reportan con las camas que cuentan en cada una, y la alerta de saturación se basa en
   la que corresponde según la política declarada. La cadena de espera señala el eslabón
   que falta.
5. **Aislamiento y duda.** Un paciente con prueba pendiente no es tratado como positivo
   ni como negativo: el gemelo dice «no se sabe», la decisión que toma mientras tanto y qué
   resultado la cambiaría. Si no hay cama del tipo requerido, lista las opciones y a qué
   se renuncia en cada una.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el mapa de camas por
servicio con su estado deducido (incluido «no se sabe» y la discrepancia con el tablero),
las solicitudes pendientes, el reparto propuesto con su explicación, la ocupación real por
servicio y la respuesta a «qué falta». Debe verse bien en celular.
