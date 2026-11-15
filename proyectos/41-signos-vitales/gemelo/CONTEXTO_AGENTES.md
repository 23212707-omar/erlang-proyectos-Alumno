# Contexto para agentes — gemelo digital del proyecto #41 (Signos vitales)

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
  (puntos del puntaje, límites de EPOC o de niño, plazos) se marca como supuesto y se le
  pide al estudiante la fuente.
- Es un ejercicio con datos simulados, no un dispositivo médico.

## Dominio

| Término | Significado |
|---|---|
| Signos | Frecuencia cardiaca (FC), frecuencia respiratoria (FR), SpO₂, temperatura, presión sistólica |
| NEWS2 | Puntaje del Royal College of Physicians (2017); suma puntos por cada signo fuera de rango |
| Alarma clínica | Deterioro del paciente |
| Alarma técnica | Falla del equipo: sensor desconectado, valor 0 o vacío |
| Acuse | Alguien reconoce la alarma; no equivale a que el paciente esté atendido |
| Escalar | Avisar al siguiente nivel cuando nadie acusa recibo |
| Fatiga de alarmas | El personal ignora alarmas porque la mayoría es falsa o no accionable |
| Límite individual | Rango fijado para un paciente concreto (EPOC, niño) que sustituye al general |

Cifras de referencia (todas del problema original): FC 60-100 lpm, FR 12-20 rpm,
SpO₂ ≥ 95 %, temperatura 36.1-37.2 °C, presión sistólica 90-120 mmHg en adultos en
reposo; puntaje alto (≥5-7) exige respuesta urgente; SpO₂ y frecuencia cada segundo,
presión y temperatura cada pocos minutos; entre 72 % y 99 % de alarmas falsas o no
accionables; sensor desconectado da 0 o vacío; escenario original de 30 pacientes con 4
señales, deterioro de 20 minutos, 3 sensores desconectados y 1 paciente con ruido.
Los puntos por signo del puntaje NO están en el original: el estudiante los verifica.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Si el escenario necesita ruido en las lecturas, entra como hecho, no se sortea.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundo).                              % instante del modelo, en segundos
paciente(Paciente, Unidad, Perfil).          % Perfil: adulto | epoc | nino
persona(Persona, Rol).                       % Rol: enfermera | supervisor | medico
asignacion(Paciente, Enfermera).
rango(Signo, Minimo, Maximo).                % rango físico posible (fuera = imposible)
limite_general(Signo, Minimo, Maximo).       % rango normal de adulto en reposo
limite_paciente(Paciente, Signo, Min, Max, FijadoPor, Segundo).
lectura(Paciente, Signo, Valor, Segundo).    % Valor puede ser el átomo vacio
evento_alarma(Paciente, Alarma, Evento, Segundo).  % activada | limpiada | acusada | escalada
escalera(Nivel, Rol).                        % orden de avisos
```

## Contrato del gemelo

- `decide(+Paciente, -Decision, -Explicacion)` — predicado central. `Decision` incluye el
  nivel de gravedad, el tipo de alarma (clínica, técnica o indeterminada) y a quién
  avisar. `Explicacion` es una lista de hechos y condiciones que la justifican, con el
  desglose por signo.
- `situacion(?Paciente, ?Situacion, -Evidencia)` — situaciones deducidas (deterioro
  combinado, falla técnica, rebote, acuse vacío), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe. Una
  señal ausente o imposible nunca cuenta como «normal».
- La API expone al menos: el estado de los pacientes, la decisión con su explicación, el
  orden de atención y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Gravedad combinada.** Un paciente con varios signos levemente fuera de rango queda
   por encima de otro con un solo signo muy alterado, y la evidencia desglosa cada signo.
2. **Técnica o clínica.** Un cero en SpO₂ con las demás señales estables da alarma
   técnica; con las demás señales empeorando, no se descarta lo clínico. Una señal
   ausente produce «no se sabe» y puntaje incompleto, nunca silencio.
3. **Límites propios.** La misma lectura da veredicto distinto en un paciente con EPOC y
   en uno sin límites propios. Un perfil sin límites fijados da «no se sabe».
4. **Rebote.** Una oscilación repetida en el límite se agrupa en una alarma sostenida;
   si otras señales confirman deterioro, esa alarma no se silencia y la evidencia lo dice.
5. **Sin acuse.** Una alarma sin acuse escala al siguiente nivel de la escalera; con dos
   alarmas simultáneas para una sola enfermera la decisión nombra a cuál se le falla y
   quién la cubre; un acuse previo no cierra una alarma de un paciente que empeoró.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el tablero de pacientes
con su nivel de gravedad, las alarmas activas distinguiendo técnicas de clínicas, la
decisión con su explicación (desglose por signo), el orden de atención por enfermera y la
respuesta a «qué falta». Debe verse bien en celular.
