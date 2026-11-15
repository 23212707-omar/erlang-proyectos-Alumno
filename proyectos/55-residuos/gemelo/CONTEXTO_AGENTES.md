# Contexto para agentes — gemelo digital del proyecto #55 (Residuos)

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
| Contenedor | Depósito con sensor ultrasónico que reporta su nivel de llenado (0-100 %) |
| Sitio | Lo que hay junto al contenedor (mercado, restaurante, residencial, escuela); decide su ritmo de llenado |
| Camión compactador | Recolecta hasta su capacidad y debe descargar en el relleno |
| Relleno sanitario | Sitio de disposición; el trayecto toma 30-60 minutos |
| Viaje | Ida al relleno y regreso para volver a recolectar; 1 a 3 por turno |
| Desborde | Contenedor lleno que ya no recibe: quejas, plagas, tiraderos clandestinos |
| Ruta de revisión | Visita a un contenedor cuyo dato no es confiable, para verificarlo |
| Huérfana | Parada pendiente de un camión que ya no puede atenderla |

Cifras de referencia del original: camión de 8 a 12 t (10 t en el escenario); 1 a 3
viajes por turno; 30-60 minutos al relleno; jornada de 8 h; un contenedor de mercado o
restaurante se llena en un día y uno residencial en una semana; más basura los lunes y
después de festivos; 300 contenedores y 5 camiones en el escenario original, 20
contenedores saturados por el evento masivo. Todo lo demás (sitios, red, aportes,
tiempos de parada, umbrales de sospecha) es supuesto del ejercicio o decisión del
estudiante.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  El azar de la simulación (lecturas falsas, avería) entra como hecho o evento, no se
  sortea en las reglas.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                         % minutos desde el inicio de la jornada
contenedor(Contenedor, Zona, Sitio).   % Sitio: mercado | restaurante | residencial | escuela
calle(Origen, Destino, Minutos).       % nodos: contenedores, deposito, relleno
camion(Camion, CapacidadT, Estado).    % Estado: servicio | descompuesto
carga(Camion, Toneladas, Minuto).      % carga con el instante en que se midió
aporte(Contenedor, Toneladas).         % lo que deja al vaciarse lleno
rango(Variable, Minimo, Maximo).       % rango físico, por ejemplo del nivel
lectura(Contenedor, Variable, Valor, Minuto).
evento(Sujeto, Evento, Minuto).        % vaciado | lluvia | descarga | averia | evento_masivo
dia_especial(Dia, Tipo).               % lunes | festivo
jornada(Inicio, Fin).
```

Si el estudiante necesita el ritmo de llenado por sitio, lo declara él como hecho propio
y anota su fuente. El nivel probable de un contenedor y el estado de una parada no son
hechos: se deducen.

## Contrato del gemelo

- `decide(+Solicitudes, -Plan, -Explicacion)` — predicado central. `Solicitudes` es una
  lista de contenedores o de camiones por atender (puede ser de uno); `Plan` es el
  reparto completo: qué camión toma qué paradas, en qué orden, dónde descarga, qué
  queda sin atender y qué contenedores van a revisión; `Explicacion` justifica cada
  posición. Al pedir más soluciones debe dar los demás planes válidos. Si no existe
  ninguno (capacidad o jornada insuficientes, sin camiones), lo dice y señala el motivo,
  sin fallar en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  lectura dudosa, nivel inferido, contenedor en riesgo antes de la próxima visita,
  parada huérfana, contenedor desplazado), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe. En
  particular: lleno, no lleno, no se sabe si está lleno.
- La API expone al menos: el estado deducido de los contenedores, el plan con su
  explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Lectura.** Una lectura imposible o repentina tras lluvia no se toma como nivel
   real; un contenedor sin reportar da «no se sabe», distinto de «no lleno». El nivel
   que no viene de una lectura creíble aparece marcado como inferido, con lo que lo
   sustenta, y la duda puede mandarlo a revisión. Una lectura de 100 % dudosa no
   garantiza que sea la parada más urgente.
2. **Riesgo antes de la visita.** Un contenedor de sitio rápido con nivel bajo puede
   aparecer en riesgo si el calendario lo acelera, y uno residencial con nivel alto
   puede no estarlo; la evidencia muestra la cadena (sitio, ritmo, día especial, hora
   estimada, visita). La consulta inversa dice qué visita lo salva.
3. **De paso.** Recoger un contenedor intermedio que deja sin capacidad a uno crítico
   posterior no se acepta sin que la explicación nombre al desplazado. Si no desplaza a
   nadie, se acepta. La consulta inversa devuelve qué tendría que cambiar para que
   alcance a ambos.
4. **Camión lleno.** Ningún plan supera la capacidad ni la jornada. Pedir más soluciones
   da otros planes válidos. Si no cabe todo, el plan dice qué queda fuera y por qué
   eso; si no cabe nada, lo dice y señala el motivo.
5. **Avería.** Las paradas del camión descompuesto aparecen como huérfanas y se
   reasignan sin romper capacidad ni jornada; los contenedores que quedan sin atender
   salen con su causa y a quién perjudican. La pregunta «¿y si falla otro camión?» se
   contesta sin reescribir reglas.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el estado de cada
contenedor (con su nivel marcado como lectura o inferido), los camiones con su carga, el
plan con su explicación, los contenedores sin atender con su causa y la respuesta a
«qué falta». Debe verse bien en celular.
