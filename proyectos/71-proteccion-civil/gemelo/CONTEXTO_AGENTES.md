# Contexto para agentes — gemelo digital del proyecto #71 (Protección civil)

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
| Albergue | Lugar improvisado (escuela, gimnasio) que aloja damnificados durante el evento |
| Familia | Grupo de personas que quiere seguir junto; es la unidad que se asigna |
| Registro | Anotación de una persona en un albergue, a veces en papel y capturada tarde |
| Cupo | Cuántas personas más puede sostener un albergue; no es un dato guardado |
| Insumo | Agua, alimento, colchonetas, cobijas, medicinas, higiene, kits para bebés... |
| Esencial / complementario | Lo que sostiene la vida frente a lo donado que no se necesita (ropa) |
| Días restantes | Cuánto dura un insumo con la gente y el consumo de ahora |
| Transferencia | Mover un insumo de un albergue a otro; tarda y deja al donante con menos |
| Sin conexión | El albergue opera pero la central no lo ve; su dato se envejece |
| Sincronización | Al volver la señal, las dos versiones del albergue se comparan |
| Necesidad especial | Adulto mayor, embarazada, medicación continua, bebé |

Cifras de referencia, todas del problema original: por persona, unos 3.5 m² techados y
15 litros de agua al día como mínimo, y un sanitario por cada 20 personas (Manual
Esfera); albergues
improvisados que abren con 50-300 personas; grupo de 200 personas que llega de golpe;
albergue sin conexión durante 6 horas; escenario de 5 albergues, 1,200 personas en 72 h
y 40 tipos de insumo.

Términos y números del escenario reducido (4 albergues, unas 12 familias, unos 8 insumos,
metros, sanitarios, existencias, tiempos de traslado, instante del reabasto, nombres y
ejemplos): son del ejercicio, no hechos del mundo. No los presentes como datos reales.

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
ahora(Hora).                                  % horas desde que abre el evento
albergue(Albergue, MetrosTechados, Sanitarios, Atencion).  % Atencion: medica | ninguna
persona(Persona, Familia, Condicion).         % Condicion: adulto_mayor | embarazada |
                                              % medicacion_continua | bebe | ninguna
registro(Registro, Albergue, Nombre, Edad, Hora).  % lo anotado; puede faltar la edad
evento(Entidad, Suceso, Hora).                % entra, sale, sin_conexion, sincronizado,
                                              % transferido...
insumo(Insumo, Unidad, Clase).                % Clase: esencial | complementario
existencia(Albergue, Insumo, Cantidad, HoraConteo).
consumo(Albergue, Insumo, PorPersonaPorDia, DesdeHora).  % cambia con el tiempo
necesidad(Persona, Insumo).                   % medicina, kit para bebé...
ruta(Albergue1, Albergue2, Horas).            % tiempo de traslado
```

Sin reglas aquí. Si el dominio pide algo aleatorio (cuándo llega el reabasto, cuántos
llegan), no se sortea: el valor entra como hecho o queda como supuesto del estudiante.
Si falta un dato (la condición de una persona, la edad en un registro), el estudiante
decide cómo se representa la ausencia, sin renombrar los hechos de arriba.

## Contrato del gemelo

- `decide(+Solicitudes, -Reparto, -Explicacion)` — predicado central. `Solicitudes` es
  una lista de familias, personas o peticiones de insumo (puede ser de una); `Reparto` es
  el plan completo: a qué albergue va cada familia y qué transferencias de insumo lo
  sostienen; `Explicacion` justifica cada pieza. Al pedir más soluciones debe dar los
  demás repartos válidos. Si no existe ninguno (no hay lugar, agua que no alcanza), lo
  dice y señala el motivo, sin fallar en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre un albergue,
  una persona, una familia o un insumo (por ejemplo cupo agotado por sanitarios, misma
  persona, agua que no alcanza, dato envejecido), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de los albergues y su cupo, el reparto con su
  explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Grupo de golpe.** El gemelo reparte las familias sin rebasar lo que cada albergue
   sostiene, da todos los repartos válidos y, para cada albergue que no recibe a una
   familia, nombra el recurso que se acabaría primero. El albergue con más espacio libre
   puede no ser el que más personas admite, y la explicación lo muestra.
2. **Misma persona.** Dos registros con nombres parecidos dan «misma persona», «personas
   distintas» o «no se sabe», nunca un sí por default. La ubicación actual se deduce de lo
   que ocurrió, no de la hora de captura, y un conteo sin duplicados cambia con la
   respuesta. Cuando no se sabe, la respuesta dice a quién llamar o qué confirmar.
3. **Días restantes y transferencias.** Los días de un insumo salen de la existencia, la
   gente presente y el consumo vigente; un albergue con más litros puede tener menos
   días. Una transferencia que deja a alguien por debajo de lo que alcanza se rechaza o se
   marca, con la explicación de a quién se le falla. Lo complementario no cuenta como
   esencial. La consulta inversa dice qué faltaría para que alcance.
4. **Sin conexión.** Con el albergue desconectado, mandar gente a él da «no se sabe» con el
   motivo, no «cabe» por el último número. Al reconectar, el estado reconciliado conserva
   los hechos que cada versión vio, señala los que chocan y dice cuál prevalece y por qué;
   las asignaciones que ya no son válidas aparecen.
5. **Necesidades especiales.** La misma persona recibe veredicto distinto según su
   condición, el insumo que lo sostiene y el albergue; cuando dos tienen razón por el
   mismo lugar, la explicación dice por qué gana uno y a quién se le falla. Una condición
   no capturada da «no se sabe, hay que preguntar», nunca sí ni no por omisión. Quien se
   queda sin medicina antes del reabasto se identifica aunque nada lo registre como
   urgencia.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar cada albergue con su cupo y
lo que lo limita, las familias con su asignación, los insumos con sus días restantes, la
decisión con su explicación y la respuesta a «qué falta». Los datos viejos y los «no se
sabe» deben verse distintos de los «no», con la hora de su último dato. Debe verse bien
en celular: la usan voluntarios cansados y a veces con mala conexión.
