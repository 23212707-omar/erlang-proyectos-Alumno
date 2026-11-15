# Contexto para agentes — gemelo digital del proyecto #77 (Valle de Guadalupe, bodega)

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
| Mosto | Jugo de uva (con hollejos, en tintos) antes y durante la fermentación |
| °Brix | Medida del azúcar del mosto; baja mientras la levadura fermenta |
| Densidad | Lo que mide el sensor del tanque; sube o baja con el azúcar disuelto |
| Fermentación alcohólica | Azúcar a alcohol y calor; es exotérmica |
| Fermentación atorada | La levadura se detiene y deja azúcar residual |
| Maloláctica | Fermentación posterior, de semanas, en que se suaviza la acidez |
| Camisa de glicol | Envoltura del tanque por la que circula líquido frío para enfriarlo |
| Remontado o bazuqueo | Mojar el sombrero de hollejos en tintos; trabajo manual con horario |
| Trasiego | Pasar el vino de un tanque a otro |
| Coupage | Mezcla de lotes |
| Lote | Uva de una variedad y fecha, con sus análisis y su trazabilidad |

Cifras de referencia, todas del problema original: ~24 °Brix produce ~13-14 % de
alcohol; el °Brix baja ~1-2 por día en fermentación activa; blancos y rosados 12-18 °C,
tintos 24-30 °C; a más de ~35 °C las levaduras sufren y pueden detenerse; fermentación
alcohólica de 5 a 14 días, maloláctica de semanas, crianza de meses a años; escenario
de 30 tanques, 6 variedades, lecturas cada 15 min y vendimia de 3 semanas; un tinto que
sube 1 °C por hora por falla del glicol; densidad sin bajar 3 días. Las fases, en orden:
recepción y estrujado, maceración en frío, fermentación alcohólica, maloláctica,
crianza, embotellado.

Marcado como del ejercicio, no del original: la escala de 8 tanques y 4 variedades, las
personas (enólogo de guardia, jefe de bodega, propietario) y los identificadores y horas
de los ejemplos. El estudiante no debe presentarlos como datos reales.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar lecturas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Si hay jitter en las lecturas, entra como hecho o como supuesto, no se sortea.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Minuto).                         % minutos desde el inicio de la vendimia simulada
rango(Variable, Minimo, Maximo).       % rango físico posible: temperatura, densidad
lectura(Tanque, Variable, Valor, Minuto).
lote(Lote, Variedad, Tipo, MinutoRecepcion).   % Tipo: tinto | blanco | rosado
contenido(Tanque, Lote, MinutoDesde).  % qué lote ocupa el tanque desde cuándo
fase(Tanque, Fase, MinutoDesde).       % recepcion | maceracion_frio | alcoholica | malolactica | crianza | embotellado
analisis(Tanque, Medida, Valor, Minuto).       % laboratorio, p. ej. brix
trasiego(Origen, Destino, Minuto).
mezcla(LoteNuevo, LoteOrigen).         % coupage: un hecho por lote de origen
evento(Tanque, Evento, Detalle, Minuto).       % orden de enfriar, falla de glicol, remontado, aviso, respuesta
persona(Persona, Rol).                 % enologo | jefe_bodega | propietario
guardia(Persona, MinutoDesde, MinutoHasta).
```

## Contrato del gemelo

- `decide(+Tanque, -Decision, -Explicacion)` — predicado central. La entidad es un solo
  tanque. `Decision` incluye el siguiente paso válido (o la secuencia válida hasta la
  fase pedida) y, cuando corresponde, a quién avisar; al pedir más soluciones debe dar
  las demás alternativas válidas. `Explicacion` es una lista de hechos y condiciones que
  justifican la decisión. Si no existe ningún paso válido, lo dice y señala el motivo,
  sin fallar en silencio.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  emergencia de temperatura, fermentación atorada, procedencia de un lote), consultables
  en cualquier dirección. La entidad puede ser un tanque o un lote.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de los tanques, la decisión con su explicación, el
  orden de atención de las alertas abiertas, el linaje de un tanque o lote y «qué falta
  para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Desviación o emergencia.** Un tanque fuera de rango pero estable o en descenso no
   es emergencia; uno que sube con la orden de enfriar sin efecto sí, con la evidencia
   completa. El tanque más urgente no tiene por qué ser el más caliente, y la
   explicación dice por qué.
2. **Densidad quieta.** La misma densidad sin cambio da «atorada», «terminó» o «sensor
   sospechoso» según el resto de los datos, y «no se sabe» cuando no alcanzan. Cumplir
   los días de la fase no basta para declarar que terminó.
3. **Transiciones.** Un cambio de fase fuera de secuencia o ya irreversible se niega
   con motivo; con datos suficientes se da el siguiente paso o la secuencia, y con
   alternativas si las hay. Quien no puede autorizar el paso lo ve negado y se le dice
   con quién pasar. Falta de análisis es «no se sabe», no «no».
4. **Linaje.** Un tanque trasegado y mezclado devuelve su procedencia con cada paso que
   la sustenta; reutilizar el tanque no confunde el lote. La consulta inversa lista los
   tanques que descienden de un lote. Un trasiego sin registro marca el tramo como
   desconocido y no inventa lote.
5. **Madrugada.** Con dos alertas abiertas y quien está de guardia sin contestar, el
   gemelo ordena la atención, dice a quién avisar ahora y cuándo escalar, distingue
   «no ha contestado» de «no se le avisó» y deja la razón de lo que no se hizo.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar cada tanque con su fase,
temperatura y densidad, la decisión con su explicación, el linaje de un lote, la lista
ordenada de alertas abiertas con a quién se avisó, y la respuesta a «qué falta». Debe
verse bien en celular: el enólogo la consulta de madrugada.
