# Contexto para agentes — gemelo digital del proyecto #44 (Banco de sangre)

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
  (tabla completa de compatibilidad, nivel crítico, tiempo tolerable fuera de rango,
  margen para liberar una reserva, cuánto se revisa hacia atrás a un donante) se marca
  como supuesto y se le pide al estudiante la fuente.
- Es un ejercicio con datos simulados, no un sistema real de un banco de sangre.

## Dominio

| Término | Significado |
|---|---|
| Unidad | Bolsa de un componente obtenida de una donación (~450 ml la de sangre total) |
| Componente | Glóbulos rojos, plaquetas o plasma; cada uno con su vida útil y su temperatura |
| Compatibilidad ABO/Rh | Qué tipo de donante puede dar a qué tipo de receptor |
| O negativo | Donante universal de glóbulos rojos; su inventario es crítico y se agota rápido |
| AB positivo | Puede recibir de todos |
| FEFO | Se entrega primero la unidad que caduca antes |
| Reserva | Unidad apartada para una cirugía programada |
| Cuarentena | Unidad apartada por duda, sin descartarla ni entregarla |
| Trazabilidad | Rastro donante, unidad, receptor, exigido por la NOM-253-SSA1-2012 |
| Prueba tardía | Resultado de una prueba que llega después de liberar la unidad |

Cifras de referencia (todas del problema original): glóbulos rojos hasta 35-42 días a
1-6 °C; plaquetas 5-7 días a ~22 °C con agitación; plasma congelado hasta 1 año; unidad de
~450 ml; 8 tipos, 3 componentes y 300 unidades en el escenario; accidente que consume 20
unidades de O negativo en 1 hora. Son órdenes de magnitud. Marcadas como inventadas por
esta extensión: la escala reducida (~30 unidades, 3 equipos, 6 pacientes), que una donación
dé varias unidades y que un paciente tenga el tipo registrado por dos fuentes.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar donaciones simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Si el escenario necesita azar (qué unidad se pide primero en el accidente), entra como
  hecho, no se sortea.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Hora).                                  % instante del modelo, en horas
donacion(Donacion, Donante, TipoDonante, Hora).
unidad(Unidad, Donacion, Componente, Caducidad).  % Componente: globulos | plaquetas | plasma
ubicacion(Unidad, Equipo, Desde).             % en qué equipo está y desde qué hora
rango(Variable, Minimo, Maximo).              % rango de temperatura que exige cada componente
lectura(Equipo, Variable, Valor, Hora).
evento_unidad(Unidad, Evento, Hora).          % reservada(Cirugia) | liberada | transfundida(Paciente) | retirada | cuarentena
prueba(Donacion, Resultado, Hora).            % Resultado: negativa | positiva
tipo_registrado(Paciente, Fuente, Tipo).      % varias fuentes pueden no coincidir
solicitud(Solicitud, Paciente, Componente, Cantidad, Urgencia).  % Urgencia: emergencia | programada
cirugia(Cirugia, Paciente, Hora, Componente, Cantidad).
compatible(TipoDonante, TipoReceptor).        % la tabla la define y verifica el estudiante
```

## Contrato del gemelo

- `decide(+Solicitud, -Decision, -Explicacion)` — predicado central. `Decision` dice qué
  unidad o unidades se asignan, o que la solicitud espera, se reacomoda o no puede
  cubrirse. Las demás solicitudes abiertas, las reservas y el inventario entran como
  hechos, no como argumentos. Al pedir más soluciones, da las demás unidades que también
  serían válidas, en su orden de conveniencia. `Explicacion` es una lista de hechos y
  condiciones que justifican la decisión, incluida la parte a la que se le falla.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (unidad
  utilizable, unidad comprometida, unidad por retirar, receptor por avisar, reserva
  aprovechable, nivel crítico de un tipo, paciente tipificado), consultables en cualquier
  dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe. Un dato
  ausente (lectura que falta, receptor sin registro, tipo con fuentes en conflicto) nunca
  cuenta como «no».
- La API expone al menos: el inventario por tipo y componente con su estado, la decisión
  con su explicación, las unidades a retirar y los receptores por avisar de un donante, y
  «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Sustitución.** Con el tipo exacto agotado, la solicitud recibe una unidad compatible y
   la explicación lista las alternativas descartadas. Hay al menos un caso donde se
   prefiere una unidad que no es la O negativo aunque esta también sirva, y la
   explicación dice a quién se protege con eso.
2. **Reserva.** Una reserva que caduca antes de su cirugía no cuenta como utilizable para
   ella. Ante una urgencia, el gemelo puede entregar la unidad reservada y reacomodar la
   reserva con otra, o, si no alcanza, decir a quién se le falla y por qué. Una reserva de
   una cirugía ya realizada sin consumir se libera según el margen que fija el estudiante.
3. **Donante positivo.** La consulta devuelve las unidades por retirar (incluidas las
   de bolsa aparentemente sana), los receptores por avisar y, aparte, las unidades sin
   registro de destino como «no se sabe», cada una con su cadena donante, donación,
   unidad, estado. Una unidad reservada que se retira nombra la cirugía afectada.
4. **Refrigerador.** Una unidad que estuvo en un equipo con lecturas fuera de rango sale
   comprometida; una con huecos de lectura queda en cuarentena por duda y no se entrega;
   una movida antes de la falla no se ve afectada. El mismo rango de temperatura se
   evalúa según el componente. Una lectura que volvió a rango no exculpa.
5. **Accidente.** Con varias solicitudes y pocas unidades de O negativo, el reparto
   justifica el desempate. Un paciente cuyas fuentes de tipo no coinciden se trata como
   no tipificado, nunca como «tipificado». El nivel crítico de un tipo se calcula con
   unidades utilizables, no con el total del inventario.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el inventario por tipo y
componente con caducidad y estado (utilizable, reservada, cuarentena, retirada), los
niveles críticos, la solicitud con la unidad asignada y su explicación, el rastro de un
donante hacia sus receptores (con las unidades sin destino aparte) y la respuesta a «qué
falta». Debe verse bien en celular.
