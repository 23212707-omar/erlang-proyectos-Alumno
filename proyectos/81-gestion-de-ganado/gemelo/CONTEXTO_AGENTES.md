# Contexto para agentes — gemelo digital del proyecto #81 (Gestión de ganado)

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
| SINIIGA | Sistema oficial de identificación; cada animal lleva un arete oficial |
| Arete | Identificador del animal; puede perderse, repetirse o capturarse mal |
| Categoría | Becerro, vaquilla, vaca o toro; con necesidades y calendarios distintos |
| Lote | Grupo de animales que se maneja junto y ocupa un potrero |
| Potrero | Parcela de pastoreo; tiene pasto y agua, y puede estar en descanso |
| Pastoreo rotacional | Usar los potreros por turnos para dar descanso al pasto |
| Sobrepastoreo | Más animales de los que el pasto aguanta; degrada el terreno por años |
| Campaña sanitaria | Vacunación con calendario (brucelosis, tuberculosis, rabia paralítica bovina) |
| Guía de tránsito | Documento exigido para mover animales entre predios |
| Trazabilidad | Poder demostrar qué animal es, dónde estuvo y qué vacunas tiene |

Cifras de referencia, todas del problema original: ganancia diaria de ~0.5-1.0 kg en un
becerro en pastoreo; un becerro destetado a los ~7 meses pesa unos 180-220 kg; pesajes
mensuales (a veces cada tres meses) capturados a mano; escenario de 400 animales,
8 potreros y 3 campañas de vacunación al año; sequía que reduce 50 % el pasto de dos
potreros; un animal que «pierde» 100 kg por error de captura. El coeficiente de
agostadero se dice en el original solo como «decenas de hectáreas por unidad animal»:
no lo conviertas en regla.

Marcado como del ejercicio, no del original: la escala de 12 animales, 3 lotes y 4
potreros, y los identificadores de los ejemplos (lote 2, potrero 3, vaquilla 7). El
estudiante no debe presentarlos como datos reales.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar pesajes simulados o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Si hay ruido en los pesajes, entra como hecho o como supuesto, no se sortea.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Dia).                            % días desde el inicio del año simulado
rango(Variable, Minimo, Maximo).       % rango físico posible: peso en kg, ganancia diaria
lectura(Sujeto, Variable, Valor, Dia). % pesaje de un registro; pasto o agua de un potrero
registro(Registro, Arete, Categoria).  % un renglón del hato; Arete puede faltar o repetirse
lote(Lote, Registro).                  % a qué lote pertenece un registro
ubicacion(Lote, Potrero, DiaDesde).    % dónde ha estado cada lote y desde cuándo
colinda(PotreroA, PotreroB).           % se puede pasar de uno a otro
comparte_agua(PotreroA, PotreroB).     % usan el mismo aguaje
campana(Campana, Dia).                 % campaña sanitaria del año (tipo y fecha)
aplicacion(Registro, Campana, Dia).    % vacuna aplicada a un registro
evento(Sujeto, Tipo, Detalle, Dia).    % síntoma, brote, arete perdido, captura, guía solicitada
```

El azar no entra en las reglas: si el estudiante quiere ruido en los pesajes, el valor
entra ya como hecho (o lo genera Janus fuera de las reglas).

## Contrato del gemelo

- `decide(+Entidad, -Decision, -Explicacion)` — predicado central. La entidad es un
  animal o un lote; `Decision` es alerta o no, aislar, mover (con destino y ruta), dejar
  salir o retener, o equivalentes; `Explicacion` es una lista de hechos y condiciones
  que justifican la decisión, incluida la regla que bloqueó otras opciones.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  caída de peso real o de captura, mismo animal, expuesto al brote, elegible para salir),
  consultables en cualquier dirección. La evidencia distingue dato de inferencia.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de animales, lotes y potreros, la decisión con su
  explicación, los lotes y animales aislados (con certeza o por precaución) y «qué falta
  para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Alerta o ruido.** Dos animales con caídas distintas pueden recibir el veredicto
   contrario al que sugiere el tamaño de la caída: la mayor puede ser ruido de captura y
   la menor, una alerta. Un lote entero que baja junto da otra causa que un animal solo,
   y un hueco de pesajes da «no se sabe», distinto de «ruido».
2. **Identidad.** Dos registros con el mismo arete pueden ser el mismo animal o dos
   distintos según su historial; un arete ausente no se resuelve borrando. Sin evidencia
   suficiente la respuesta es «no se sabe». Cada veredicto cita el historial.
3. **Brote.** El gemelo devuelve los lotes y animales expuestos con la cadena que los
   sustenta (animal, lote, potrero, otro lote o aguaje, vacuna). Un lote sin síntomas
   puede aparecer aislado; uno cercano que llegó después puede quedar fuera. Lo que
   carece de registro queda como «no se sabe» y no como «no expuesto». Distingue lo
   que se aísla con certeza de lo que se aísla por precaución; la hipótesis de otro
   potrero con brote cambia el resultado.
4. **Sequía.** Con pasto reducido, el gemelo entrega destino y ruta por lote. El
   potrero con más pasto no es elegido si le falta agua, está en descanso o su camino
   cruza un potrero con brote. Si ninguno sirve, lo dice y señala el motivo; si hay que
   fallarle al hato o al pasto, la explicación dice a quién y con qué regla.
5. **Salida.** Un lote con un animal sin arete legible o sin la campaña vigente no
   sale completo; el gemelo dice qué animal lo impide y qué cambiaría el veredicto. El
   animal más pesado no tiene prioridad por serlo. Si la regla permite una salida
   parcial, la explicación dice a quién se le falla. Con el dato de contacto o de
   vacuna incompleto la respuesta es «no se sabe».
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

Se diseña en Google Stitch antes de programarla. Debe mostrar cada lote con su potrero,
sus animales y su estado sanitario, el pasto y el agua de cada potrero, la decisión con
su explicación (distinguiendo dato de inferencia), la cadena de exposición de un brote y
la respuesta a «qué falta». Debe verse bien en celular y leerse al sol: el ranchero la
consulta en el corral, junto a la báscula.
