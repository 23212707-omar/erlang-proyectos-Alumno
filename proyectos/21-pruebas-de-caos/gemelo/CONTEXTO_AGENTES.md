# Contexto para agentes — gemelo digital del proyecto #21 (Pruebas de caos)

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
- El escenario («Botica Frontera», su reglamento, su calendario) es inventado por la
  extensión. No lo presentes como un caso real ni le atribuyas estadísticas.

## Dominio

| Término | Significado |
|---|---|
| Simulacro | Experimento de falla controlada: una hipótesis y uno o más pasos |
| Paso | Una falla inyectada contra un blanco (una instancia o una conexión) |
| Estado estable | Comportamiento normal medible: peticiones/s, latencia p99, errores |
| Hipótesis | Lo que se espera que siga cumpliéndose con la falla aplicada |
| Radio de explosión | Hasta qué servicios alcanza el daño de un paso |
| Instancia | Copia en ejecución de un servicio (principal o respaldo) |
| Estado en memoria | Datos que un servicio pierde al reiniciar |
| Recuperado | El servicio volvió a ser útil, no solo a estar vivo |
| Congelamiento | Días en que dirección prohíbe cualquier cambio o simulacro |
| Bitácora / monitor | Las dos fuentes de eventos: captura manual y medición automática |

Cifras de referencia, todas del problema original: 500 ms de latencia y 20 % de pérdida
hacia la base de datos; un proceso que muere cada 2 segundos; la falla de Amazon S3 del
28 de febrero de 2017, de unas 4 horas, como ejemplo de falla pequeña con efecto
dominó; Chaos Monkey (2011). El reglamento (a)-(f) y las etapas del simulacro están en
`PROBLEMA.md` y son inventados: no traen cifras, y las que hagan falta las fija el
estudiante.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar eventos y lecturas simulados o graficar. Prolog nunca es una librería de
  Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  El gemelo no inyecta fallas ni sortea cuál ocurre: razona sobre fallas que entran
  como hechos.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                              % minutos desde el inicio del escenario
servicio(Servicio, Criticidad, Memoria).    % critico | importante | prescindible;
                                            % Memoria: volatil | persistente
instancia(Instancia, Servicio).             % un servicio puede tener varias
depende(Servicio, Requisito).
paso(Simulacro, Paso, Falla, Blanco).       % matar | latencia_y_perdida | muerte_en_bucle
ventana(Tipo, Desde, Hasta).                % Tipo: quincena | congelamiento | guardia
evento(Fuente, Sujeto, Evento, Minuto).     % Fuente: bitacora | monitor | direccion
rango(Indicador, Minimo, Maximo).           % valores posibles, no la banda estable
lectura(Servicio, Indicador, Valor, Minuto).
pedido(Pedido, Cliente, Marca).             % Marca: real | prueba | sin_marca
```

`Sujeto` en `evento/4` puede ser un simulacro, un paso, una instancia, un pedido o una
ventana. La etapa de un simulacro, el estado de un pedido y si una instancia está en
pie **no son hechos**: se deducen de los eventos. La banda de estado estable, el radio
autorizado y los plazos son predicados que añade el estudiante con sus supuestos.

## Contrato del gemelo

- `decide(+Simulacro, -Decision, -Explicacion)` — predicado central. `Decision` es lo
  que procede con ese simulacro en el «ahora»: iniciar, posponer, pedir nueva
  autorización, continuar, terminar el paso y abortar, abortar, cerrar o no cerrar.
  Cuando el simulacro aún no inicia, incluye el orden de sus pasos; al pedir más
  soluciones da los demás órdenes válidos, y si no existe ninguno lo dice y señala el
  paso que lo impide, sin fallar en silencio. `Explicacion` es una lista de hechos,
  condiciones y reglas del reglamento que justifican la decisión, incluida la regla
  que perdió cuando hubo conflicto.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  etapa de un simulacro, servicio vivo pero no útil, pedido huérfano, historia
  imposible, hipótesis sin evidencia), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado deducido de servicios y simulacros, la decisión
  con su explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Lanzar.** Un simulacro autorizado no inicia si falta guardia, si hay otro abierto
   o si su radio de explosión, deducido por dependencias, alcanza a un servicio vedado
   por la ventana vigente; la explicación lista todas las condiciones que fallan, no
   solo la primera. Una autorización anterior a un cambio de calendario se trata
   distinto que una posterior. La consulta inversa da el primer momento posible.
2. **Recuperado.** Un servicio que reinició y perdió estado en memoria aparece como
   vivo pero no útil mientras existan pedidos cobrados sin surtido posible; la
   evidencia muestra la cadena completa y nombra los pedidos. El simulacro no se puede
   cerrar y el siguiente no puede iniciar por esa causa.
3. **Orden.** Para un simulacro de varios pasos se obtienen todos los órdenes que
   nunca rompen el reglamento. Un orden inválido se rechaza señalando el primer paso
   que lo rompe. Empezar por el servicio sin respaldo del que dependen otros no
   aparece como válido solo por ser «el chico».
4. **Dilema.** Con un pedido real urgente y una sincronización a medias, abortar de
   inmediato no es la decisión; la explicación nombra las dos reglas en choque, cuál
   prevalece, a quién se le falla y qué tendría que cambiar para que abortar fuera
   seguro. Sin sincronización en curso, el mismo pedido sí produce el aborto inmediato.
5. **Auditoría.** Una historia con un evento imposible se rechaza señalando la primera
   entrada que la rompe. Un hueco del monitor y una lectura fuera de rango dan «no se
   sabe», distinto de «no hubo errores». Un pedido sin marca no se cuenta ni como real
   ni como prueba. La hipótesis puede quedar confirmada, refutada o sin evidencia.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar los servicios con sus
dependencias y su estado deducido (vivo, útil, «no se sabe»), cada simulacro con su
etapa, la decisión con su explicación, los órdenes válidos de los pasos, la línea de
tiempo de eventos con las entradas en duda y la respuesta a «qué falta». Debe verse
bien en celular.
