# Contexto para agentes — gemelo digital del proyecto #60 (Restaurante)

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
  se marca como supuesto y se le pide al estudiante la fuente. Las secciones de los
  meseros, las mesas juntables, la alergia y los sustitutos son del ejercicio, no de un
  restaurante real.

## Dominio

| Término | Significado |
|---|---|
| Comanda | Pedido de una mesa; se compone de partidas y recorre las etapas tomada, en cocina, lista y servida |
| Partida | Un platillo de la comanda, con sus modificadores; va a una o más estaciones |
| Estación | Parrilla, freidora, fría, postres o barra; en esta escala reducida, cuatro |
| Sincronía | Que los platillos de una misma mesa salgan juntos, aunque vengan de estaciones distintas |
| Ticket fuera de objetivo | Comanda que lleva más de 20-25 minutos |
| 86 | Producto agotado, que debe desaparecer del menú al instante |
| Modificador | «Sin cebolla» y similares; la alergia es un modificador de seguridad |
| Rotación | Cuántas veces se ocupa una mesa en un servicio; define los ingresos |
| Sección | Conjunto de mesas que atiende un mesero (complemento del ejercicio) |
| KDS | Pantalla de cocina que muestra prioridad, tiempo transcurrido y alertas |

Cifras de referencia (del original): mesa ocupada de 45 a 90 min; 15-30 comandas
simultáneas en pico; bebida 2 min, entrada fría 5, plato fuerte 12-20; ticket de más de
20-25 min fuera de objetivo; propinas de 10-15 %; escenario de 20 mesas, 5 estaciones,
6 meseros y 3 horas; un platillo que se agota con 6 comandas pendientes. Marcados como
del ejercicio, sin cifras: la escala reducida, las secciones, las mesas juntables, qué
estación cubre a otra, los sustitutos, la alergia, las porciones restantes y los
umbrales de silencio y de cercanía entre dos toques.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar comandas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Si la simulación necesita azar (cuánto tarda de verdad un plato, un doble toque), el
  valor entra como hecho; las reglas no sortean nada.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                          % instante del gemelo, en minutos desde un origen fijo
mesa(Mesa, Capacidad, Seccion).
juntable(Mesa1, Mesa2).                 % dos mesas que pueden juntarse
seccion(Seccion, Mesero).               % qué mesero atiende cada sección
grupo(Grupo, Personas, Llegada).        % grupo en espera; Llegada: un minuto
comanda(Comanda, Mesa, Mesero).
partida(Comanda, Partida, Platillo).
requiere(Platillo, Estacion, Minutos).  % estación y tiempo de preparación (el valor del rango lo fijas tú)
estacion(Estacion, Estado).             % Estado: disponible | fuera
existencia(Platillo, Fuente, Porciones). % Fuente: bodega | cocina; puede faltar el conteo
modificador(Partida, Tipo, Detalle).    % Tipo: sin | alergia | cambio
evento(Comanda, Suceso, Minuto).        % Suceso: tomada | enviada | en_cocina | lista | servida | cambio | cancelada | cuenta
```

## Contrato del gemelo

- `decide(+Solicitudes, -Decision, -Explicacion)` — predicado central. `Solicitudes` es la
  LISTA de lo que se pide resolver (una o varias comandas, grupos, partidas; puede ser de
  una). `Decision` es el reparto, plan o ruta completo: qué estación hace qué partida y
  cuándo, el orden de la cocina, la mesa de cada grupo, y el siguiente paso válido de una
  comanda. Al pedir más soluciones debe dar las demás alternativas válidas. Si no existe
  ninguna (estaciones insuficientes, ninguna mesa que alcance, un ciclo de dependencias),
  lo dice y señala el motivo; nunca falla en silencio. `Explicacion` es una lista de
  hechos, eventos y reglas que la justifican, y distingue lo sabido, lo inferido y lo
  ignorado.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (comanda fuera de
  objetivo, platillo agotado, comanda protegida, mesa por liberarse, posible duplicado,
  historia imposible), consultables en cualquier dirección: dada una entidad, sus
  situaciones; dada una situación, qué entidades la cumplen.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- Toda inferencia (por ejemplo, la hora de liberación de una mesa) se marca como
  inferencia y cita los hechos que la sustentan; nunca se presenta como un dato.
- La API expone al menos: el estado de mesas, estaciones y comandas, la decisión con su
  explicación, el historial de eventos de una comanda y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Sincronía.** Una comanda con partidas de varias estaciones obtiene un plan donde las
   partidas calientes salen juntas y la estación que marca el ritmo está señalada. Con
   la cola de una estación más larga, el plan cambia y dice por qué. Si ningún plan
   cabe en el objetivo del ticket, la respuesta lo dice y nombra el motivo, y las
   alternativas aparecen al pedir más soluciones.
2. **Saturación.** Con una estación fuera de servicio, el orden de la cocina distingue las
   comandas aún salvables de las ya perdidas, y no es simplemente la más vieja primero.
   La explicación nombra a quién se le falla y por qué. La consulta inversa dice qué
   tendría que pasar para que una mesa específica sí salga a tiempo.
3. **Agotado.** Un platillo agotado desaparece de lo ofrecible, pero las comandas con el
   platillo ya en marcha quedan protegidas y las demás se reparten lo que realmente
   queda. Un conteo que falta o que dos fuentes contradicen da «no se sabe» y dice qué
   conteo lo resolvería. Un sustituto que choca con una alergia nunca se propone.
4. **Mesas.** El reparto de grupos respeta capacidad, mesas juntables y carga por mesero.
   La hora de liberación de una mesa ocupada se marca como inferencia y cita los eventos
   que la sustentan. Una mesa sin eventos recientes da «no se sabe», no una hora.
5. **Comanda.** Dos comandas casi idénticas dan «duplicada», «legítima» o «no se sabe»
   según los hechos, no por parecerse. El cambio de pedido procede o no según la etapa
   de la partida, y la explicación dice qué se desperdicia y quién lo absorbe. Una
   historia imposible (servida sin haber estado lista) se señala, no se acepta. Con
   alergia de por medio, el veredicto lo dice en la explicación.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el salón con sus mesas y
grupos en espera, el tablero de estaciones con sus colas, la decisión con su
explicación, el historial de eventos de una comanda y la respuesta a «qué falta».
Debe distinguir a la vista lo sabido de lo inferido y de lo que no se sabe, y verse bien
en celular.
