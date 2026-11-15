# Prompt universal — Extensión en Prolog para los proyectos Erlang/OTP

> **Sustituido** el 2026-11-13 por [PROMPT_MAESTRO_GEMELO_DIGITAL.md](PROMPT_MAESTRO_GEMELO_DIGITAL.md). Se conserva como referencia del enfoque anterior (ejercicio con esqueleto y solución).

Uso: pegar el bloque de abajo en Claude con el número de proyecto (`N`). Para lotes,
cambiar «el proyecto N» por «los proyectos A al B»; el prompt ya obliga a procesarlos
de uno en uno y a no avanzar si uno falla.

Archivos de apoyo:
- `proyectos/EJES_PROLOG.csv` — eje, nivel y foco asignados a cada uno de los 81
  proyectos (columna `fuente_nivel`: `catalogo` = viene de PROYECTOS.md,
  `propuesto` = sugerido, el docente puede cambiarlo editando el CSV).

---

```text
Actúa como docente de Programación Lógica y de Erlang/OTP. Vas a crear la EXTENSIÓN EN
PROLOG del proyecto N del repositorio (carpeta proyectos/NN-nombre/).

## Idea central
Los 81 proyectos son SIMULACIONES de problemas reales hechas en Erlang/OTP (procesos,
supervisión, estado, concurrencia). La extensión en Prolog es un complemento FUERA de
Erlang: un ejercicio independiente donde se razona de forma declarativa sobre el MISMO
dominio. Erlang simula lo que pasa; Prolog decide, valida, explica o planifica.
Erlang NO llama a Prolog ni al revés. `datos.pl` se escribe a mano a partir del
«Escenario a simular» del problema; exportarlo desde la simulación Erlang es un extra
opcional que NO debes implementar.

## Entrada y lectura (no inventes)
1. Lee la fila N de proyectos/EJES_PROLOG.csv: eje_principal, eje_secundario, nivel y
   foco. Esos valores MANDAN: no elijas otro eje. Si crees que no encajan con el
   dominio, dilo en la entrega con una propuesta, pero implementa el asignado.
2. Lee proyectos/NN-*/problema/readme.md (contexto, datos reales, casos difíciles,
   escenario) y proyectos/NN-*/README.md (diseño OTP sugerido).
Extrae: entidades, estados y transiciones, restricciones, reglas de negocio, umbrales y
los «casos difíciles». El ejercicio debe nacer de ESOS casos, no ser genérico.

## Ejes
- transiciones: máquina de estados como hechos + reglas (¿es válida esta secuencia?).
- experto: reglas con evidencias, datos dudosos y explicación del porqué.
- restricciones: asignación/calendarización con library(clpfd).
- grafos: búsqueda, rutas, dependencias, cascadas.
- politicas: permisos, límites, precios, puntos, elegibilidad y desempates.
Usa el principal como núcleo y el secundario como complemento (si es «-», solo el principal).

## Nivel (de la columna `nivel`; manda sobre tu criterio)
| Nivel | Técnicas permitidas | Predicados a programar | Hechos del escenario | Tiempo |
|---|---|---|---|---|
| Inicial | hechos, reglas, unificación, findall | 3 a 4 | hasta ~15 | 1.5 a 2 h |
| Intermedio | + recursión, listas, aggregate_all, negación | 5 a 6 | ~20 a 40 | 2 a 3 h |
| Avanzado | + clpfd, búsqueda, explicación (árbol de prueba) | 6 a 8 | ~30 a 60 | 3 a 4 h |

## Contrato común (igual en los 81 proyectos, para poder calificar de forma uniforme)
- `datos.pl` es un módulo (`:- module(datos, [...])`) con el escenario; `reglas.pl` es
  el módulo `reglas` que lo importa. Solo se edita `reglas.pl`.
- El predicado central se llama SIEMPRE `decide(+Entidad, -Decision, -Explicacion)`:
  `Explicacion` es una lista de hechos que justifican la decisión. En proyectos de
  asignación, `Decision` es la asignación o el plan.
- Los demás predicados llevan un nombre propio del dominio, en español, sin acentos ni ñ.
- Las pruebas se agrupan en `begin_tests(basicas)`, `begin_tests(casos_dificiles)` y
  `begin_tests(explicacion)`; cada caso difícil se llama `dificil_<tema>`.
- Predicados deterministas salvo que se declare lo contrario: documenta el modo
  (`%! pred(+A, -B) is det`) y que las pruebas no dejen choicepoints ni avisos.
- Reproducible: prohibido get_time, random o fecha del sistema. El «ahora» es un hecho
  (`ahora/1`) y el escenario es determinista.
- Escala reducida: el problema habla de cientos de dispositivos o miles de eventos. El
  escenario aquí es pequeño y legible; declara la reducción como SUPUESTO en
  ENUNCIADO.md (p. ej. «lecturas cada 30 min en vez de cada 60 s»). Las cifras son de
  referencia.

## Qué generar (dentro de proyectos/NN-*/prolog/)
- ENUNCIADO.md  Ejercicio para el estudiante, estilo problema/readme.md: contexto, modelo
                de hechos dado, predicados a programar con su contrato, 5 a 8 consultas con
                la respuesta esperada (tabla), 2 casos difíciles tomados del problema
                Erlang, preguntas guía, supuestos y qué entregar (incluye un párrafo:
                «qué harías en Erlang y qué en Prolog, y por qué»). SIN la solución.
- datos.pl      Escenario de hechos (módulo `datos`).
- reglas.pl     ESQUELETO: cabeceras con contrato y cuerpos `:- fail. % TODO estudiante`.
                Debe cargar sin errores ni avisos.
- tests/reglas_tests.pl  plunit. Con el esqueleto fallan; con la solución pasan.
- README.md     Cómo cargar y probar: swipl -g run_tests -t halt tests/reglas_tests.pl
- RUBRICA.md    Calificación en 100 pts: pruebas básicas 40, casos difíciles 25,
                explicación 15, supuestos y consultas propias 10, párrafo Erlang vs
                Prolog 10. Ajusta solo los textos al dominio.
- solucion/     Solución de referencia (reglas.pl) y pruebas pasando. SOLO docente:
                ya está ignorada por .gitignore (proyectos/*/prolog/solucion/); no la
                subas ni la enlaces desde ningún archivo público.

## Reglas de calidad
- SWI-Prolog 10.x. Relaciones puras, sin assert/retract salvo que el ejercicio lo exija;
  sin cortes innecesarios; clpfd en vez de aritmética generativa cuando haya restricciones;
  format/2 solo para salida.
- Comentarios que explican el «por qué», como en el código Erlang.
- Cifras tomadas del problema; todo supuesto propio, marcado como supuesto.
- Solo SWI-Prolog estándar (clpfd, plunit, lists, aggregate, apply).

## Verificación obligatoria (ejecuta los comandos; no afirmes lo que no corriste)
Desde proyectos/NN-*/prolog/:
1. Esqueleto carga limpio:
   swipl -g "use_module(reglas)" -t halt   → código de salida 0 y nada en stderr.
2. Esqueleto falla las pruebas:
   swipl -g run_tests -t halt tests/reglas_tests.pl   → código de salida distinto de 0.
   (si pasan, el ejercicio no enseña nada: rehazlo).
3. La solución pasa. Las pruebas importan ../reglas, así que prueba la solución en una
   copia temporal:
   T=$(mktemp -d); cp -r datos.pl tests "$T"/; cp solucion/reglas.pl "$T"/;
   (cd "$T" && swipl -g run_tests -t halt tests/reglas_tests.pl)   → salida 0, sin avisos
   de choicepoints.
Si un paso falla, corrige antes de continuar; en lotes, no pases al siguiente proyecto.

## Respaldo de la solución
solucion/ está fuera de git. Si el usuario definió un directorio de respaldo, copia ahí
solucion/ de este proyecto. Si no lo definió, dilo en la entrega: «solución sin respaldo».
No inventes una ruta.

## Registro e idempotencia
- Anota en bitacora/LOG.md (arriba, con fecha) proyecto, eje y resultado real de las tres
  verificaciones; en bitacora/TODO.md marca solo lo verificado. No dupliques entradas si
  el proyecto ya estaba registrado: actualiza la existente.
- No modifiques el código Erlang ni los README existentes, salvo añadir al README.md del
  proyecto la línea «- Extensión Prolog: [prolog/README.md](prolog/README.md)» SOLO si no
  existe ya (comprueba con grep antes). Si prolog/ ya existe, no lo sobrescribas sin
  avisar: dilo y detente.

## Entrega
Lista de archivos creados; una línea con eje y nivel; y una línea por cada verificación
(1, 2, 3) con su resultado real; más el aviso de respaldo. Nada más.
```
