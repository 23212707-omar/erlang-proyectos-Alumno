# Contexto para agentes — gemelo digital del proyecto #49 (Estacionamiento del campus)

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
| Edificio | Destino del usuario; la cercanía se mide de edificio a estacionamiento |
| Estacionamiento (lote) | Conjunto de zonas con un acceso; puede cerrar por obra |
| Zona | Grupo de cajones para un tipo de usuario |
| Cajón | Lugar para un vehículo; unidad que se asigna |
| Tipo de usuario / permiso | Alumno, docente, personal, visitante, moto, accesible |
| Cajón accesible | Cajón para personas con discapacidad; las normas exigen un porcentaje |
| Acceso con lector | Puerta de un lote que registra placas de entrada y salida |
| Ola | Momento en que llegan muchos autos juntos (7:00, 13:00, 16:00) |
| Estancia | Tiempo que un auto permanece estacionado |
| Invasión | Vehículo sin permiso para esa zona ocupando un cajón de ella |
| Falso positivo / negativo | El sensor dice ocupado y está libre / dice libre y está ocupado |

Cifras de referencia (todas del problema original): 6 edificios, 4 estacionamientos,
1,500 cajones; 1,200 autos entre 6:45 y 7:15; olas a las 7:00, 13:00 y 16:00; ocupación
máxima entre 8:00 y 14:00 y hasta 100 % en semana de examen; estancia de 4 a 8 horas;
mil usuarios simultáneos; un estacionamiento cerrado por obra.

Datos del ejercicio, no del original: la escala reducida (3 edificios, 3 lotes, unos 24
cajones, unos 10 usuarios) y los ejemplos (Marta, Luis, «diez autos más»). El original no
da cifras de umbrales, desempates ni porcentaje de accesibles: son decisión del estudiante.

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
ahora(Minuto).                                  % minuto del día (desde las 0:00)
estacionamiento(Lote, Estado).                  % Estado: abierto | cerrado_por_obra
zona(Zona, Lote, TipoUsuario).
cajon(Cajon, Zona).
distancia(Edificio, Lote, Metros).
permiso(Usuario, TipoUsuario).
vehiculo(Placa, Usuario).
solicitud(Usuario, Edificio, Llegada, SalidaEstimada).   % minutos del día
lectura(Cajon, Estado, Minuto).                 % Estado: libre | ocupado
evento_acceso(Lote, Tipo, Placa, Minuto).       % Tipo: entrada | salida
ola(Minuto).
evento(Nombre, Edificio, Inicio, Fin).
```

## Contrato del gemelo

- `decide(+Solicitudes, -Reparto, -Explicacion)` — predicado central. `Solicitudes` es
  la LISTA de usuarios que piden cajón (puede ser de uno); `Reparto` empareja a cada uno
  con un cajón distinto; `Explicacion` justifica cada pareja. Al pedir más soluciones
  debe dar los demás repartos válidos. Si no existe ninguno (más solicitudes que cajones
  permitidos, lote cerrado), lo dice y señala el motivo y para quién; no falla en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre un cajón,
  un lote, un edificio o un usuario (por ejemplo cajón dudoso, lote lleno aunque el mapa
  muestre libres, cajón invadido, edificio sin accesible cercano, ola en riesgo),
  consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de los cajones, el reparto con su explicación y
  «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Último cajón.** Con dos solicitudes que compiten por el mismo cajón, ambas reciben
   cajón distinto si existe reparto; la explicación dice por qué una no obtuvo el que
   quería y qué criterio declarado desempató. Nunca asigna una zona que el permiso no
   admite, un lote cerrado ni un cajón dudoso. Con más solicitudes que cajones, lo dice.
2. **Obra.** Al cerrar un lote, el gemelo reubica a los afectados, indica a quién movió
   y por qué, y reporta los edificios donde ya no hay cajón accesible cercano. Si no hay
   solución, dice qué falta. Reabrir el lote restituye las conclusiones anteriores.
3. **Sensor.** Un cajón que el sensor da por libre pero que los accesos contradicen queda
   «no se sabe», con la evidencia; no se asigna ni se cuenta como libre. Un lote con
   libres en el mapa puede reportarse lleno. Donde las fuentes cuadran, lo confirma.
4. **Invasión.** Un cajón accesible ocupado por una placa sin ese permiso se reporta
   como invadido con evidencia; sin lectura de placa o con permiso por actualizar, «no
   se sabe». En ambos casos la usuaria recibe de inmediato otro cajón accesible válido.
5. **Ola.** Dos repartos que dejan igual a los que llegan ahora pueden diferir en lo que
   dejan a la próxima ola; el gemelo prefiere el que la cubre y explica el costo para
   quien quedó más lejos. La consulta inversa dice qué cambiar si no existe. Con
   llegadas supuestas, la hipótesis se contesta sin alterar los hechos reales.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el mapa del campus por
edificio y lote con el estado de cada cajón (incluido «no se sabe» e «invadido»), las
solicitudes pendientes, el reparto propuesto con su explicación y la ocupación por zona.
Debe verse bien en celular, porque la vigilancia camina el campus.
