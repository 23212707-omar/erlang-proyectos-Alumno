# Contexto para agentes — gemelo digital del proyecto #14 (Acortador de URLs)

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
- Las políticas del servicio (desempate entre peticiones, alias reservados, espera de un
  alias vencido, vigencia de una validación) no vienen del original: las define el
  estudiante y las declara como supuestos. Pregúntaselas; no las decidas tú.

## Dominio

| Término | Significado |
|---|---|
| Enlace | URL corta que lleva a un destino; puede tener alias, vigencia y dueño |
| Alias | Nombre personalizado del enlace, en lugar del código generado |
| 301 | Redirección permanente: el navegador la guarda y ya no pasa por el servicio |
| 302 | Redirección temporal: cada visita pasa por el servicio y se puede contar |
| Bloqueo | Desactivar un enlace malicioso para que deje de redirigir |
| Colisión | Dos peticiones, o dos ids, que quieren el mismo identificador |
| Contador | Total de visitas que lleva el enlace; no es el registro de cada visita |
| Phishing | Enlace que imita a otro sitio para robar datos o dinero |
| Lista de bloqueo | Dominios conocidos como maliciosos, con su fecha de actualización |

Cifras de referencia, todas del problema original: ids de 7 caracteres en base62
(unos 3.5 billones de combinaciones); relación lectura:escritura de 100:1 o más; 301
cacheada por el navegador y 302 no; colisiones aleatorias tras unos 2 millones de ids;
1 millón de enlaces, 500 redirecciones por segundo y ráfaga de 5,000 por segundo a un
solo enlace. Los ejemplos de `PROBLEMA.md` (taquería, gimnasio, `promo`) son
ilustrativos, no datos.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar visitas simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
  El gemelo no genera ids ni sortea colisiones: razona sobre peticiones que entran como
  hechos.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundo).                         % segundos desde el inicio del escenario
usuario(Usuario, Rol).                  % anonimo | registrado | moderador
enlace(Enlace, Dueno, Destino, Tipo).   % Tipo: 301 | 302
alias(Alias, Enlace).                   % alias que apuntan a un enlace
reservado(Alias, Motivo).               % alias que nadie puede tomar
solicitud(Solicitud, Usuario, Alias, Destino, Segundo).   % alta pedida
evento(Sujeto, Evento, Segundo).        % creado | vencido | bloqueado | validado |
                                        % contador_reiniciado | cambio_tipo | ...
visita(Enlace, Visitante, Segundo).     % registro individual de una visita
reporte(Reporte, Enlace, Usuario, Segundo).
dominio(Destino, Dominio).              % dominio de cada URL de destino
lectura(Enlace, Variable, Valor, Segundo).   % Variable: contador_visitas
rango(Variable, Minimo, Maximo).        % valores posibles de una lectura
```

`Sujeto` en `evento/3` puede ser un enlace, un alias, un dominio, un contador o una
lista. La vigencia, el estado de un enlace (activo, vencido, bloqueado) y si un alias
está libre **no son hechos**: se deducen de los eventos. Si hay azar, entra como hecho
o como supuesto del estudiante.

## Contrato del gemelo

- `decide(+Solicitudes, -Decision, -Explicacion)` — predicado central. El primer
  argumento es la lista de solicitudes (puede ser de una: un alta, un reporte, una URL)
  y `Decision` es el reparto completo: a quién se asigna cada alias, qué se bloquea,
  qué URL se acepta. Al pedir más soluciones da los demás repartos válidos, y si no
  existe ninguno lo dice y señala el motivo, sin fallar en silencio. `Explicacion` es
  una lista de hechos, condiciones y políticas, incluida la regla que perdió cuando
  hubo conflicto y a quién se le falla.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas (por ejemplo
  alias disponible o no, enlace alcanzable pese al bloqueo, visitas dudosas, alias
  vacío en el sistema pero en uso, destino no verificable), consultables en cualquier
  dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado deducido de enlaces y alias, la decisión con su
  explicación y «qué falta para que cambie».

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus políticas.

1. **Alias disputado.** Dos peticiones por el mismo alias reciben respuestas distintas
   y la explicación nombra el desempate usado y a quién se le falla. Un alias reservado
   o vencido no se trata como libre. La consulta inversa enumera las alternativas válidas
   para quien perdió y qué tendría que cambiar para que ganara.
2. **Reporte y caché.** Un enlace reportado se bloquea, se vigila o pide más evidencia
   según quién reporta y qué más se sabe; el bloqueo arrastra a los alias que comparten
   destino. Si el enlace era 301, la evidencia nombra a los visitantes que aún pueden
   llegar sin pasar por el servicio y marca que el bloqueo no los cubre. Con un reporte
   falso, la explicación dice a quién se le falló.
3. **Visitas.** Para cada tramo de tiempo se distingue lo que se puede afirmar, lo que
   se descarta y lo que no se sabe. Un contador que baja sin reinicio registrado, o que
   queda por debajo de los registros individuales, se señala como imposible. Un tramo
   con 301 no se da por completo ni por vacío.
4. **Alias vencido.** Un alias vencido con visitas posteriores o con 301 emitido no
   aparece como libre sin condición; la evidencia muestra la cadena completa. La
   consulta inversa da el primer momento posible y la evidencia que lo cambiaría.
5. **Validación.** Cada URL recibe aceptable, no aceptable o no se sabe. Una validación
   anterior, o una lista desactualizada, no basta por sí sola para afirmar que es
   segura, y la explicación dice qué dato falta para decidir.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar los enlaces con su estado
deducido (activo, vencido, bloqueado, «no se sabe»), los alias y quién los tiene, la
decisión con su explicación, la línea de tiempo de eventos con las entradas en duda, las
alternativas de alias y la respuesta a «qué falta». Debe verse bien en celular.
