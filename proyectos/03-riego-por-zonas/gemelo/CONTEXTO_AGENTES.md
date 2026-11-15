# Contexto para agentes — gemelo digital del proyecto #3 (Riego por zonas)

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
| Zona | Área de cultivo con su propia válvula; unidad sobre la que se programa |
| Ramal | Tubería compartida por dos zonas; (escenario reducido) no riegan al mismo tiempo |
| Bomba | Fuente de agua con caudal finito: soporta un máximo de zonas abiertas a la vez |
| Ventana | Periodo nocturno en que se permite regar |
| Dosis | Minutos de riego que una zona necesita esa noche |
| Prioridad | Importancia de una zona que fija su dueño (escenario reducido) |
| ETc / ETo / Kc | ETc = ETo × Kc: demanda del cultivo a partir de la evapotranspiración de referencia |
| Válvula atorada | Válvula solenoide que no cierra por sedimento |
| Fuga | Caudal en la línea sin ninguna zona activa |
| Caudalímetro | Mide el caudal de la línea (pulsos); uno por predio |
| Pluviómetro | Mide la lluvia; uno por predio (escenario reducido) |
| Golpe de ariete | Daño por cerrar una válvula de golpe (solo contexto, no es situación) |

Cifras de referencia, todas del problema original: bomba que soporta 3 zonas a la vez;
ventana nocturna de 8 horas; ETo de ~2 mm/día en invierno a ~7-8 mm/día en verano; el
escenario original tiene 12 zonas (aquí se reduce a 6). Son del escenario reducido y no
del mundo real: los 3 ramales, las prioridades, los dueños, la zona bajo cubierta y el
único pluviómetro.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Si el dominio tiene azar (por ejemplo, el instante de un corte de luz), el valor entra
  como hecho o queda como supuesto del estudiante.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                       % minutos desde el inicio de la ventana nocturna
ventana(Inicio, Fin).                % minutos, mismo origen que ahora/1
bomba(MaxZonasSimultaneas).
zona(Zona, Ramal).
requiere(Zona, Minutos).             % dosis pendiente esta noche
prioridad(Zona, Nivel).              % alta | media | baja, la fija el dueño
rango(Variable, Minimo, Maximo).     % rango físico de caudal, humedad, lluvia
lectura(Sensor, Variable, Valor, Minuto).   % caudalimetro, pluviometro, humedad de zona
orden(Zona, Accion, Minuto).         % Accion: abrir | cerrar, lo que se mandó
evento(Fuente, Zona, Tipo, Minuto).  % Fuente: controlador | servidor; Tipo: abrio | cerro
```

## Contrato del gemelo

- `decide(+Solicitudes, -Plan, -Explicacion)` — predicado central. `Solicitudes` es la
  lista de zonas que piden riego (puede ser de una); `Plan` es el calendario completo,
  con el turno de cada zona; `Explicacion` justifica cada turno. Al pedir más soluciones
  debe dar los demás calendarios válidos. Si no existe ninguno (el programa no cabe), lo
  dice, señala el motivo y presenta a quién se le falla y bajo qué criterio, sin fallar
  en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre una zona,
  la bomba o la línea (por ejemplo válvula atorada, fuga, zona mojada por la lluvia,
  dosis dudosa), consultables en cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de las zonas y la bomba, el calendario con su
  explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Calendario.** En una noche que cabe, cada zona recibe su dosis dentro de la
   ventana, nunca hay más zonas abiertas de las que soporta la bomba y nunca coinciden
   dos del mismo ramal. Al pedir más soluciones aparecen los demás calendarios válidos;
   la explicación dice por qué cada zona quedó en su turno.
2. **No cabe.** Cuando la demanda excede la ventana, el gemelo lo dice en vez de fallar
   en silencio, nombra a quién se le falla y el criterio, y trata igual a dos zonas
   empatadas en prioridad según una regla de desempate declarada. La consulta inversa
   dice cuánto tendría que crecer la ventana o la bomba para no fallarle a nadie, y la
   hipótesis de mayor ETo cambia el resultado sin duplicar reglas.
3. **Válvula atorada y fuga.** Con orden y reporte de «cerrada» pero caudal que
   contradice, la humedad creciente de una zona produce «atorada» y la evidencia lista
   los datos que se contradicen; sin humedad creciente en ninguna zona, el resultado es
   «fuga»; con datos insuficientes o corruptos, «no se sabe». Tras el diagnóstico, la
   capacidad usada para recalcular es la que de verdad queda.
4. **Lluvia.** Llover no suspende por sí solo todo el programa: cada zona pendiente
   queda mojada, no mojada o no se sabe, y el gemelo lo justifica con la evidencia de esa
   zona. Una lectura imposible nunca mueve una decisión. Si la lluvia libera espacio,
   el gemelo revisa si una zona a la que se le falló ya cabe.
5. **Reinicio.** Para cada zona se distingue regó completo, regó parcial y no se sabe, con
   las fuentes y las horas. Una válvula abierta sin cierre registrado no se asume
   cerrada: ocupa capacidad de la bomba hasta que otra evidencia diga lo contrario. Dos
   relojes que discrepan no producen una certeza falsa.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el calendario de la noche
por zona y por ramal, la ocupación de la bomba en cada momento, el estado de cada válvula
(incluido «no se sabe»), la decisión con su explicación y la respuesta a «qué falta».
Debe verse bien en celular.
