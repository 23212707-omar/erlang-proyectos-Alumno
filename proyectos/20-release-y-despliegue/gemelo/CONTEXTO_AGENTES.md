# Contexto para agentes — gemelo digital del proyecto #20 (Release y despliegue)

Este archivo es para el agente (OpenCode u otro) que acompaña al estudiante. Léelo
completo, junto con [`PROBLEMA.md`](PROBLEMA.md) y
[`../problema/readme.md`](../problema/readme.md), antes de proponer cualquier cosa.

## Tu papel

- El proyecto es individual y se califica el razonamiento del estudiante. **Explica,
  pregunta y propone; no entregues la solución completa.**
- Antes de escribir una regla, pide al estudiante que la diga en español.
- Primero la prueba plunit, después la regla.
- Trabaja una situación a la vez, en el orden de `PROBLEMA.md`.
- No inventes cifras. Las del original vienen de `../problema/readme.md`; las del
  escenario (la caja, sus tiempos y su reglamento) son datos del ejercicio, no del mundo.
  Cualquier otra se marca como supuesto y se le pide al estudiante la fuente.

## Dominio

| Término | Significado |
|---|---|
| Release | Paquete autónomo de una aplicación Erlang (`rebar3 release`), con o sin el runtime |
| `include_erts` | Incluir el runtime de Erlang en el release; si no, el destino debe tener la misma versión de OTP |
| Plataforma | Sistema operativo y arquitectura (macOS en el desarrollo; Linux aarch64 en el CM5) |
| NIF | Código nativo que usa una dependencia; solo corre en la plataforma para la que se compiló |
| Servicio (systemd) | Unidad que arranca y detiene el release; SIGTERM para detener, SIGKILL tras `TimeoutStopSec` |
| Drenar | Dejar que una instancia termine sus conexiones activas antes de apagarla |
| Migración | Cambio de esquema de datos en pasos; cada paso se deshace o no |
| Rollback | Volver a la versión anterior; regresar el binario no regresa los datos |
| Dependencia dura / blanda | Sin la dura no arranca; sin la blanda funciona degradado |
| Ciclo | Cadena de dependencias duras que regresa al mismo servicio; no tiene orden de arranque |
| Ventana | Horas en que se permiten cambios |
| Ambiente | Producción o pruebas; cada uno con su configuración y sus secretos |

Cifras del original: destino aarch64, Debian 13, OTP 27.3.4.19; SIGTERM al detener y
espera de 90 s por omisión antes de SIGKILL; versiones 1.0 y 1.1; despliegue fallido
a las 2 a. m. que debe revertirse en minutos.
**Inventado por esta extensión** (no son hechos del mundo): la Caja Popular Cerro
Colorado, sus seis servicios (autenticación, cuentas, avisos, transferencias, nómina,
portal), las personas, el reglamento (a)-(g), la migración de tres pasos y la ventana de
2:00 a 5:00, las sucursales a las 7:00 y el límite de regreso a las 6:00, y las
duraciones de 2 min (reinicio), 40 (migración), 75 (restauración) y 10 (respaldo).

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar bitácoras simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundos).                       % segundos desde las 0:00 del día de la liberación
servicio(Servicio, Criticidad).        % Criticidad: alta | media | baja
depende(Servicio, Requisito, Tipo).    % Tipo: dura | blanda
compatible(Servicio, Version, Requisito, VersionReq).  % Servicio@Version acepta Requisito@VersionReq
evento(Servicio, Evento, Detalle, Instante).  % descarga | instalado | detenido | arranque |
                                       % version_reportada | migracion_paso_inicia | migracion_paso_fin |
                                       % sigterm | conexion_abre | conexion_cierra | apagon | luz_vuelve
migracion(Servicio, Paso, Reversible). % Reversible: si | no | no_documentado
artefacto(Servicio, Version, Plataforma, IncluyeErts, VersionOtp).  % dónde y cómo se construyó
destino(Ambiente, Plataforma, VersionOtp).
requiere(Servicio, Variable).          % variable de entorno obligatoria
config(Servicio, Variable, Origen).    % Origen: produccion | pruebas | falta | sin_respuesta
escucha(Instancia, Servicio, Puerto).
limite(Nombre, Valor).                 % ventana, regreso, apagado (segundos) y duraciones
```

No hay mediciones de sensores en este dominio, así que no se usa `rango/3`: el hecho con
instante es `evento/4`. La versión que corre, el estado del esquema y si un servicio
está «listo» no son hechos: se deducen. Las fallas y los cortes de luz entran como hechos;
las reglas no sortean nada.

## Contrato del gemelo

- `decide(+Solicitudes, -Plan, -Explicacion)` — predicado central. `Solicitudes` es una
  lista de solicitudes (puede ser de una): arrancar tras un corte, regresar una versión,
  liberar una versión nueva, aprobar un cambio de dependencias. `Plan` es el plan
  completo: orden de arranque o de regreso, y para cada servicio si sube, espera, se
  detiene o se degrada, con los puertos asignados; `Explicacion` justifica cada posición.
  Al pedir más soluciones debe dar los demás planes válidos. Si no existe ninguno (ciclo,
  regreso fuera de tiempo, puertos que chocan), lo dice y señala el motivo, sin fallar en
  silencio.
- `situacion(?Servicio, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  arriba pero no válido, bloqueado por otro, versión incierta, artefacto incompatible,
  en un ciclo), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe. En
  particular: la versión es esa, no es esa, no se sabe; la variable está, falta, no se
  pudo comprobar.
- La API expone al menos: la versión deducida de cada servicio con su certeza, el plan
  con su explicación, lo afectado por una falla con su causa y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Corte de luz.** Un servicio que arrancó pero cuyo requisito está a medias aparece
   como «arriba pero no válido», con la causa de origen y el camino. La versión que
   responde un servicio no basta para afirmar la versión instalada ni la del esquema, y
   una nota fechada durante el apagón se señala como imposible. Los servicios libres sí
   tienen órdenes de arranque válidos, y aparecen todos al pedir más soluciones.
2. **Punto de no retorno.** Con un paso irreversible, regresar solo el binario se
   rechaza, y la ruta posible (restaurar el respaldo) se evalúa contra el tiempo que
   queda y contra los movimientos que se perderían. Si no cabe, el gemelo lo dice y
   ofrece mantener lo nuevo con lo que eso apaga o degrada. La consulta inversa devuelve
   hasta qué momento regresar era seguro, y la respuesta cambia con el «ahora».
3. **Conflicto.** Las instancias que chocan por un puerto se detectan solo en los
   instantes en que ambas viven, incluido el choque con otro servicio. El plan asigna
   puertos sin choque. Cuando (e) y (f) no se pueden cumplir juntas, el gemelo nombra la
   regla que cedió, a quién se le falla y qué le cuesta; no se resuelve en silencio.
4. **Listo para arrancar.** Un artefacto construido en otra plataforma se rechaza aunque
   la versión de OTP coincida; una variable presente pero de otro ambiente cuenta como
   no lista; una variable que falta y una que no se pudo comprobar dan respuestas
   distintas, y la primera bloquea a los servicios que dependen de ese.
5. **Ciclo y cascada.** Un cambio que crea un ciclo de dependencias duras se rechaza
   nombrando los servicios que lo forman; cambiar una dependencia a blanda lo deshace y
   aparecen los órdenes de arranque. La caída de un servicio detiene a sus dependientes
   duros, directos e indirectos, y solo degrada a los blandos; uno sin relación no
   aparece como afectado.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar la red de dependencias con
el tipo de cada una, la versión deducida de cada servicio con su certeza (incluido «no se
sabe»), el plan de arranque o de regreso con su explicación, lo afectado por una falla
con su causa y la respuesta a «qué falta». Debe verse bien en celular.
