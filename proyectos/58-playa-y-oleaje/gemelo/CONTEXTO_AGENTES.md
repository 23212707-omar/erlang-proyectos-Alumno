# Contexto para agentes — gemelo digital del proyecto #58 (Playa y oleaje)

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
  se marca como supuesto y se le pide al estudiante la fuente. Las playas, boyas,
  vecindades y bancos de arena de los ejemplos son del ejercicio, no del mundo.

## Dominio

| Término | Significado |
|---|---|
| Hs | Altura significativa del oleaje, la que publican las boyas (NDBC/CDIP) |
| Tp | Periodo del oleaje; un periodo largo trae más energía a la costa |
| Resaca (rip current) | Corriente que aleja del borde a los bañistas; causa de ~80 % de los rescates (USLA) |
| Banco de arena | Elevación del fondo que la marea baja deja expuesta y puede formar resacas |
| Marea | Sube y baja del nivel del mar; aquí viene de una tabla |
| Bandera | Verde (bajo), amarilla (moderado), roja (alto), doble roja (cerrado al agua), morada (fauna marina peligrosa) |
| Enterococos fecales | Indicador del programa Playas Limpias; límite ~200 NMP/100 ml |
| Resultado vencido | Complemento de esta extensión: un resultado cuya muestra es anterior a un hecho que cambia el agua (lluvia fuerte) |
| Orden del salvavidas | Complemento: bandera pedida por quien ve la playa, que puede contradecir los datos |

Cifras de referencia (del original): ~80 % de los rescates por resaca; 2 m de oleaje con
periodo > 14 s puede ser peligroso con cielo despejado; ~200 NMP/100 ml; resultados de
laboratorio en 24-48 h; 6 playas; boya cada 30 min; viento cada 10 min; Hs de 1 m a 3 m
en 4 horas; agua de 18-21 °C en verano y bajo 15 °C en invierno. Marcados como del
ejercicio, sin cifras: el número de boyas, qué boya cubre a qué playa, bancos de arena,
vecindades y el tiempo de vigencia de una orden o de un resultado.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Si la simulación necesita azar (una boya que se calla, un oleaje con ruido), el valor
  entra como hecho; las reglas no sortean nada.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                          % instante del gemelo, en minutos desde un origen fijo
playa(Playa, Municipio).                % Municipio: tijuana | rosarito | ensenada
boya_de(Playa, Boya).                   % boya que cubre a la playa
banco_de_arena(Playa).                  % la playa tiene bancos que la marea baja expone
vecina(Playa1, Playa2).                 % playas contiguas
tabla_marea(Minuto, Estado).            % Estado: baja | media | alta
rango(Variable, Minimo, Maximo).        % rango físico: hs, tp, viento, enterococos
lectura(Origen, Variable, Valor, Minuto). % Origen: una boya o una playa (el viento)
laboratorio(Playa, NMP, Muestra, Llegada). % enterococos, con minuto de muestra y de llegada
evento(Playa, Suceso, Minuto).          % Suceso: lluvia_fuerte | fauna | observacion(Color) | boya_callada
bandera(Playa, Color, Minuto, Quien).   % bandera izada; Quien: sistema | salvavidas
```

## Contrato del gemelo

- `decide(+Playa, -Decision, -Explicacion)` — predicado central. La entidad es una
  sola playa (eje experto). `Decision` es la bandera que corresponde, con si se mantiene,
  sube, baja o se anticipa respecto de la vigente, o el motivo por el que no se puede
  decidir. `Explicacion` es una lista de hechos, lecturas, reglas y evidencias que la
  justifican, y distingue lo sabido, lo inferido y lo ignorado.
- `situacion(?Playa, ?Situacion, -Evidencia)` — situaciones deducidas (resaca probable,
  oleaje peligroso, rebote, cambio sostenido, resultado vencido, boya en silencio,
  orden del salvavidas vigente), consultables en cualquier dirección: dada una playa,
  sus situaciones; dada una situación, qué playas la cumplen.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- Toda inferencia (por ejemplo, el oleaje de una playa sin boya) se marca como
  inferencia y cita los hechos que la sustentan; nunca se presenta como una lectura.
- La API expone al menos: el estado de las playas y las boyas, la bandera con su
  explicación, el historial de banderas y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Peor de varios factores.** Con cielo despejado, oleaje de periodo largo y marea baja,
   una playa con banco de arena recibe una bandera de peligro y otra sin banco no. La
   explicación nombra el factor que pesó y qué cambiaría al subir la marea. Un aviso de
   fauna convive con las demás banderas sin ocultarlas.
2. **Marejada y rebote.** Una lectura que cruza el umbral y regresa no cambia la bandera
   de ida y vuelta. Con una marejada sostenida la bandera sube antes de que el número
   alcance el nivel más alto. Con una lectura que ya permite bajar, la respuesta puede
   ser mantener, y dice qué falta. La explicación dice a quién se le falla.
3. **Laboratorio tardío.** Un resultado sobre el límite que contradice una bandera
   vigente se marca como contradicción y la respuesta dice qué corresponde. Un
   resultado bajo el límite con lluvia fuerte posterior a la muestra da «no lo sé» y no
   «cumple». Nunca se declara limpia una playa solo por un número viejo.
4. **Boya callada.** Con una boya sin reportar, la bandera de las playas que dependen de
   ella no queda en verde por defecto. La estimación desde una vecina o desde el viento
   se marca como inferencia con su fuente; una playa sin con qué estimar responde «no lo
   sé» y nunca «calma».
5. **Salvavidas contra sistema.** Una orden del salvavidas para subir la bandera y una
   para bajarla no se resuelven con la misma frase: la respuesta dice quién rige, por
   qué, qué terminaría la orden y queda registrada en el historial. Repetir la orden
   no cambia el resultado sin que cambie algo en los hechos.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar las 6 playas con su
bandera y el color de cada una, el estado de las boyas, la explicación de la decisión,
el historial de banderas con quién las izó y la respuesta a «qué falta». Debe distinguir
a la vista lo medido de lo inferido y de lo que no se sabe, y verse bien en celular.
