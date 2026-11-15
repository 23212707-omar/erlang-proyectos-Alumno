# Contexto para agentes — gemelo digital del proyecto #10 (API REST con cowboy y PostgreSQL)

Este archivo es para el agente (OpenCode u otro) que acompaña al estudiante. Léelo
completo, junto con [`PROBLEMA.md`](PROBLEMA.md) y
[`../problema/readme.md`](../problema/readme.md), antes de proponer cualquier cosa.

## Tu papel

- El proyecto es individual y se califica el razonamiento del estudiante. **Explica,
  pregunta y propone; no entregues la solución completa.**
- Antes de escribir una regla, pide al estudiante que la diga en español.
- Primero la prueba plunit, después la regla.
- Trabaja una situación a la vez, en el orden de `PROBLEMA.md`.
- No inventes cifras. Las del dominio vienen del problema original; cualquier otra se
  marca como supuesto y se le pide al estudiante la fuente.

## Dominio

| Término | Significado |
|---|---|
| Despensa Frontera | Banco de alimentos **inventado** por esta extensión; no existe |
| Organización afiliada | Comedor, escuela, albergue o parroquia con convenio; recibe cupos |
| Delegado | Persona que aparta en nombre de una organización; la credencial es suya |
| Convenio / al corriente | Vigencia del acuerdo y entrega a tiempo del informe de reparto |
| Cupo | Cajas por producto que una organización puede apartar al mes |
| Cámara fría | Requisito de los refrigerados; se declara y se verifica en visita |
| Emergencia | Declaración de dirección que cambia la prioridad de una organización |
| Clave de petición | Identificador generado por la app del delegado; la versión vieja no lo manda |
| Pool | Conexiones a la base que la API tiene disponibles; se agotan |
| Idempotencia | Repetir una petición no debe repetir su efecto |

Cifras de referencia, todas del problema original: 200 usuarios concurrentes con 80 %
lecturas y 20 % escrituras; la base se reinicia 20 segundos; el mismo `POST` puede llegar
2 o 3 veces; PostgreSQL trae 100 conexiones por omisión y abrir una por petición no
escala. Todo lo demás (organizaciones, productos, cajas, fechas, reglamento (a)-(g),
nodos y relojes) es **inventado por esta extensión**: son datos del ejercicio, no
estadísticas. Lo que el estudiante fije (desfase tolerado, «frescura», «sin demora»,
productos escasos, sustitutos, qué regla gana) es supuesto suyo.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar peticiones simuladas o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundo).                         % segundos desde el día 1 del mes del escenario
credencial(Credencial, Persona, Org, Desde).  % de quién es y para qué organización
baja(Persona, Efectiva, Aviso, Captura).      % tres instantes distintos de una misma baja
convenio(Org, Desde, Hasta).
informe(Org, Mes, SegundoEntrega).      % informe de reparto del mes anterior
cupo(Org, Producto, CajasPorMes).
camara_fria(Org, SegundoVerificacion).  % declarada y verificada en visita
emergencia(Org, Desde, Hasta).
excepcion(Org, DadaPor, Desde, Hasta).  % excepción escrita de dirección
peticion(Id, Credencial, Tipo, Producto, Cajas, Clave, Nodo, Segundo).
                                        % Tipo: consultar | apartar | cancelar
                                        % Clave puede faltar; Segundo es el del reloj del nodo
existencia(Producto, Cajas, Segundo).   % lectura de bodega, con su instante
evento(Id, Suceso, Segundo).            % grabada | aceptada | rechazada | preparada |
                                        % base_cae | base_regresa
```

Sin reglas. Las reglas del negocio las dicta el estudiante en español y las escribe él.
El azar no entra en las reglas: un retraso o un desfase entre relojes entra como hecho o
como supuesto.

## Contrato del gemelo

- `decide(+Peticion, -Decision, -Explicacion)` — predicado central. `Decision` dice
  aceptar, rechazar, aceptar parcialmente, encolar o aceptar con aviso de dato viejo;
  si no se sabe, aplica la política declarada para la duda. `Explicacion` es una lista de
  hechos y condiciones, incluye qué reglas chocaron y cuál se impuso (el desempate) y,
  cuando compite con otra petición, nombra a la otra.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre una
  petición, una credencial o una organización (por ejemplo al corriente, cupo efectivo,
  elegible, repetida, existencia confiable, vigente en tal instante), consultables en
  cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de organizaciones y existencias, la decisión con su
  explicación, «qué falta para que cambie» y la respuesta a hipótesis («si la baja se
  hubiera capturado antes»).

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Elegibilidad.** Una credencial vigente de una organización que no está al corriente
   no recibe un sí, y la explicación nombra cada condición que falla. Quitando una
   condición a la vez, la consulta inversa dice cuál trámite cambia el veredicto.
2. **Última unidad.** Entre una organización dentro de cupo y otra en emergencia con un
   requisito vencido, la decisión nombra las reglas que chocaron, la que cedió y a quién
   se le falló. Si el orden de llegada no se puede determinar, responde «no se sabe» y
   aplica la política declarada, nunca un resultado silencioso.
3. **Repetidas.** En las peticiones de la escuela, el reintento con K1 no cuenta dos veces,
   la de K2 es un viaje nuevo y la de K1 con otro contenido se señala como inválida. La
   que no trae clave, durante la caída, da «no se sabe», distinto de «repetida» y de
   «nueva». El cupo usado se reporta como cifra firme o como rango.
4. **Base caída.** Con la existencia dudosa, apartar un producto escaso y apartar uno
   abundante reciben respuestas distintas, y una cancelación nunca se rechaza por
   existencia dudosa. Toda respuesta que no sea «aceptar» trae su razón.
5. **Auditoría.** Un apartado después de la baja efectiva y antes de la captura da
   «legítimo», «ilegítimo» o «no se sabe» según la política declarada, con la evidencia
   y la fuente de cada una. La hipótesis «baja capturada a tiempo» cambia la respuesta y
   dice a quién habría ido la existencia.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el estado de cada
organización (al corriente, suspendida, en emergencia), las existencias con su
confiabilidad, la petición con su decisión y su explicación, la respuesta a «qué falta» y
la bitácora de la auditoría. Debe verse bien en celular.
