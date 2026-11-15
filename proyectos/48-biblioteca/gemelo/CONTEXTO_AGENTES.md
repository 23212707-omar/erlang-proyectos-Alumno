# Contexto para agentes — gemelo digital del proyecto #48 (Biblioteca)

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
  (plazo exacto dentro de cada rango, tarifa, tope de libros, adeudo que bloquea, si los
  días inhábiles generan multa, número de renovaciones, cuándo se da un libro por perdido,
  qué horas cuentan del plazo de una reserva, orden de registros simultáneos) se marca
  como supuesto y se le pide al estudiante la fuente.
- Es un ejercicio con datos simulados, no el sistema de una biblioteca real.

## Dominio

| Término | Significado |
|---|---|
| Título (ISBN) | La obra; las reservas se hacen sobre él, no sobre un ejemplar |
| Ejemplar | Copia física con código de barras; de material general o de sala |
| Material | General (se presta a domicilio) o de sala (plazo corto) |
| Préstamo | Ejemplar en manos de un alumno desde una fecha, con renovaciones |
| Renovación | Ampliación del plazo; el original la permite si nadie lo ha apartado |
| Reserva | Solicitud de un alumno en la cola de un título, con su instante |
| Apartado | Ejemplar guardado para quien va al frente de la cola; vence si no se recoge |
| Día inhábil | Día en que la biblioteca no abre (calendario que define el estudiante) |
| Multa | Cargo por día de retraso; el adeudo es lo multado menos lo pagado |
| Bloqueo | Suspensión del servicio al acumular adeudo |
| Mostrador | Punto donde se captura un préstamo o devolución; cada uno tiene su hora |

Cifras de referencia (todas del problema original): préstamo de 3 a 15 días (reserva de
sala de 2 a 3 días, general de 7 a 15); 3 a 5 libros a la vez; multa de $5 a $10 MXN por
día; una obra tiene de 1 a 20 ejemplares; en finales, más de 10 personas por ejemplar;
10,000 ejemplares, 3,000 usuarios y 300 préstamos al día; un título con 1 ejemplar y 25
reservas; reserva atendida que no se recoge en 48 horas. Son órdenes de magnitud. Marcadas
como inventadas por esta extensión: la escala reducida (unos 8 títulos, unos 12
ejemplares, unos 8 alumnos, 2 mostradores, una cola de unas 6 reservas), el calendario
concreto de días inhábiles, el mostrador de cada registro, los avisos con estado, la
revisión de ejemplares y la mezcla de materiales dentro de un título.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar préstamos simulados o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  Si el escenario necesita azar (qué mostrador captura primero, cuándo se devuelve de
  verdad un libro), entra como hecho, no se sortea.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Hora).                                     % instante del modelo, en horas
dia_inhabil(Dia).                                % día del calendario en que la biblioteca no abre
ejemplar(Codigo, Isbn, Material).                % Material: general | sala
prestamo(Prestamo, Codigo, Usuario, Hora).       % préstamo capturado; el vencimiento se deduce
renovacion(Prestamo, Hora).                      % una renovación concedida
reserva(Reserva, Usuario, Isbn, Hora).           % solicitud en la cola de un título
evento_ejemplar(Codigo, Evento, Hora, Origen).   % prestado(Usuario) | devuelto | revisado(Estado) | perdido | recuperado; Origen: mostrador o buzón
aviso(Reserva, Estado, Hora).                    % enviado | recibido | rebotado
pago_multa(Usuario, Monto, Hora).                % pagos de multa registrados
politica(Nombre, Valor).                         % plazos, tarifa, topes, espera...; los fija el estudiante
```

## Contrato del gemelo

- `decide(+Caso, -Decision, -Explicacion)` — predicado central. `Caso` es un alumno, un
  par alumno-ejemplar, un préstamo, una reserva o un ejemplar; los demás préstamos,
  reservas, eventos y pagos entran como hechos. `Decision` dice el veredicto (prestar o no;
  renovar o negar; cuánto se debe y si hay bloqueo; a quién se entrega el ejemplar y a
  quién se avisa; conservar o liberar una reserva; o «no se sabe»). Cuando el caso es un
  ejemplar (eje transiciones), `Decision` incluye su siguiente estado o la secuencia
  válida y, al pedir más soluciones, las demás alternativas defendibles con los datos, en
  su orden de conveniencia. `Explicacion` es una lista de hechos y condiciones que
  justifican la decisión, incluida la parte a la que se le falla.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (préstamo vencido,
  adeudo, alumno bloqueado, registros en conflicto, ejemplar no prestable, reserva en
  riesgo de vencer, lugar real en la cola, aviso sin constancia), consultables en
  cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe. Un dato
  ausente (devolución sin registro, aviso enviado sin recepción, ejemplar en revisión sin
  resultado) nunca cuenta como «no».
- La API expone al menos: el estado de cada ejemplar y de la cola de cada título, la
  decisión con su explicación, la lista de alumnos bloqueados con su adeudo, las reservas
  en riesgo y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Multa y bloqueo.** El vencimiento depende del material y de las renovaciones; el
   adeudo descuenta los pagos; el reglamento elegido para los días inhábiles produce el
   mismo resultado en cada consulta. Un alumno bloqueado no recibe préstamo y la
   explicación nombra los préstamos que pesan. Con una devolución sin registro, la
   respuesta es «no se sabe», distinta de «debe» y de «no debe»; la consulta inversa dice
   cuánto pagar o qué registro aclarar.
2. **Dos registros, un ejemplar.** Dos préstamos vigentes del mismo código dan «en
   conflicto», no se resuelven en silencio por la hora más temprana. La respuesta separa
   lo que consta de lo que no, dice a quién corresponde el ejemplar si hay base para
   decirlo, y señala qué verificación falta.
3. **Cola.** El lugar real de una reserva no es su posición en la lista cuando alguien
   delante no puede recibir el libro. Un ejemplar dañado o perdido no se entrega a nadie.
   La espera sale como rango o «no se sabe», y la hipótesis de perder el ejemplar cambia
   las respuestas de toda la cola sin predicados nuevos.
4. **Reserva no recogida.** Un aviso enviado sin recepción no basta para liberar la
   reserva: sale «no se sabe» o «conservar». Si el aviso consta y el plazo venció según el
   reglamento elegido, se libera al siguiente y se dice qué le toca a quien aparece tarde.
5. **Renovación.** Un ejemplar de sala, dañado o en revisión no cuenta como disponible para
   quien espera. Con reservas pendientes que quedarían sin atender se niega; sin ellas se
   renueva si el alumno cumple lo demás. La explicación nombra la causa y la consulta
   inversa dice qué tendría que cambiar.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el estado de cada ejemplar,
la cola de cada título con el lugar real de cada reserva, el adeudo y el bloqueo de cada
alumno, los registros en conflicto, las reservas apartadas con el estado de su aviso, la
decisión con su explicación y la respuesta a «qué falta». Debe verse bien en celular.
