# Contexto para agentes — gemelo digital del proyecto #19 (Observabilidad)

Este archivo es para el agente (OpenCode u otro) que acompaña al estudiante. Léelo
completo, junto con [`PROBLEMA.md`](PROBLEMA.md) y
[`../problema/readme.md`](../problema/readme.md), antes de proponer cualquier cosa.

## Tu papel

- El proyecto es individual y se califica el razonamiento del estudiante. **Explica,
  pregunta y propone; no entregues la solución completa.**
- Antes de escribir una regla, pide al estudiante que la diga en español.
- Primero la prueba plunit, después la regla.
- Trabaja una situación a la vez, en el orden de `PROBLEMA.md`.
- No inventes cifras. Las reales vienen del problema original; «Agua en Línea», sus
  personas y su reglamento son un escenario inventado por esta extensión y el estudiante
  fija sus números como supuestos. Cualquier otra cifra se marca como supuesto y se le
  pide la fuente.

## Dominio

| Término | Significado |
|---|---|
| Métrica / serie | Un valor medido a lo largo del tiempo; cada combinación de etiquetas es una serie distinta |
| Cardinalidad | Cuántos valores distintos toma una etiqueta; con un identificador de persona explota |
| Raspado (*scrape*) | Cada vez que el monitor consulta `/metrics`; un raspado que falta es un hueco |
| Percentil (p50, p95, p99) | Latencia bajo la cual cae ese porcentaje de peticiones; el promedio esconde la cola |
| Objetivo (SLO) y presupuesto | Disponibilidad mensual prometida y los minutos de caída que permite |
| Alerta accionable | La que avisa de un síntoma del usuario y que alguien puede resolver ahora |
| Fatiga de alertas | Si todo alerta, nada se atiende |
| `recon` | Herramienta de diagnóstico en caliente de la VM (colas, memoria, procesos) |
| Cola de mensajes | Mensajes pendientes de un proceso; si crece sin parar, el proceso no da abasto |
| Acuse | Respuesta de una persona llamada que confirma que atiende (inventado) |
| Severidad máxima | Riesgo para personas o bienes; la única razón para exceder el tope de llamadas (inventado) |

Cifras reales de referencia (todas del problema original): raspado por omisión cada 15 s;
percentiles p50, p95 y p99; 99.9 % de disponibilidad permite unos 43 minutos de caída al
mes y 99.99 % unos 4.3; 5 aplicaciones con 20 a 50 métricas cada una. **Inventado y
marcado como tal:** el organismo de agua, las aplicaciones y sus dependencias, las
personas, los canales de pago, el tanque «Lomas», el descuento por pronto pago, el
reglamento (a)-(g) de `PROBLEMA.md` y sus números (6:00, 10 minutos, 2 llamadas por noche).

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas y logs simulados o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Las fallas, los huecos de raspado y los desfases de reloj entran como hechos, no se sortean.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundo).                          % instante del modelo, en segundos desde el inicio del mes
instancia(App, Instancia, Nodo).         % una aplicación puede tener varias instancias
depende(App, Dependencia).               % incluye las externas: pasarela, proveedor de SMS
objetivo(App, Porcentaje).               % disponibilidad mensual prometida
persona(Persona, Rol).
guardia(Persona, Turno, Desde, Hasta).   % Turno: primaria | secundaria
rango(Variable, Minimo, Maximo).         % rango físico o posible de cada variable
lectura(Instancia, Variable, Valor, Segundo).  % un raspado; Variable puede llevar etiquetas
cardinalidad(Metrica, Etiqueta, Valores).      % cuántos valores distintos tiene la etiqueta
tope_series(Numero).                     % máximo de series que el monitor acepta guardar
evento(Sujeto, Tipo, Detalle, Segundo).  % despliegue, reinicio, mantenimiento, alerta, llamada, acuse
registro(Instancia, Nivel, Peticion, Mensaje, Segundo).  % línea de log; Peticion puede faltar
```

## Contrato del gemelo

- `decide(+Entidad, -Decision, -Explicacion)` — predicado central. `Entidad` es una
  alerta, una aplicación o una petición, según la pregunta. `Decision` es despertar a
  alguien concreto, dejarlo pendiente de la mañana, esperar, retirar una etiqueta o un
  veredicto sobre la petición; `Explicacion` es la lista de hechos y condiciones que lo
  justifican, incluidos los hechos que se usaron como evidencia y los que faltaron.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (fuga probable,
  objetivo incumplido, presupuesto agotado, monitor topado, hueco del monitor, línea
  atribuida a una petición), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de cada aplicación (sana, no sana, no se sabe), las
  alertas con su decisión y su explicación, y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Fuga o carga.** Con la misma carga en las dos instancias, el gemelo señala la que
   crece y no la que simplemente tiene más memoria; la explicación nombra el tipo de
   memoria y la comparación con la otra instancia. Si el crecimiento se explica por la
   carga, la respuesta es dejarlo pendiente de la mañana. Pide solo diagnósticos que no
   pausan el nodo.
2. **Percentil y presupuesto.** Con promedio normal y p99 alto en un canal, el gemelo
   reporta incumplimiento de ese canal y no de los demás. Un mantenimiento no publicado
   antes gasta presupuesto y uno publicado, no. El presupuesto restante se deduce de los
   incidentes y la explicación los lista.
3. **Dilema.** Con una sola persona disponible, el gemelo elige a quién llamar, nombra la
   alerta que espera, la regla que cedió y el costo. Una lectura vieja del tanque da
   «no se sabe» sobre su nivel actual, nunca «sin riesgo», y la respuesta dice cómo
   cambiaría con una lectura nueva. La consulta inversa devuelve qué tendría que cambiar.
4. **Tablero en verde.** Una aplicación sin raspados recientes no aparece como sana: aparece
   como «no se sabe», distinto de «no sana». Un hueco compartido por todas se atribuye al
   monitor y uno aislado a la aplicación. La etiqueta culpable se deduce de las
   cardinalidades, y las alertas que no pudieron evaluarse se distinguen de las que no
   dispararon.
5. **Cobro dudoso.** Las líneas sin identificador se atribuyen a una petición con la
   evidencia que las sustenta y marcadas como atribución, no como dato. La respuesta es
   «sí», «no» o «no se sabe», con la primera entrada que rompe la historia, y nunca
   ordena hechos cuya diferencia cabe en el desfase de relojes.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar las cinco aplicaciones con
colores de estado (sana, en riesgo, no se sabe, no sana; «no se sabe» no puede ser verde),
las alertas abiertas con su decisión y su explicación, quién está de guardia y a quién se
llamó, una línea de tiempo de la noche y la respuesta a «qué falta». Debe verse bien en
celular.
