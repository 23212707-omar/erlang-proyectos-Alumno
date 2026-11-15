# Contexto para agentes — gemelo digital del proyecto #13 (Rate limiter / caché)

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
| Frontera Abierta / Caja Frontera | API y cooperativa **inventadas** por esta extensión; no existen |
| Cliente titular / llave | Quien contrata la API y las credenciales de sus aplicaciones; la cuota es del titular |
| Plan | Anónimo, Registrado o Convenio; fija el límite por hora |
| Hora corrida | Cualquier lapso de una hora hacia atrás, no la hora del reloj |
| 429 y espera | Respuesta de «demasiadas peticiones» con el tiempo que el cliente debe aguardar |
| Abuso | Tráfico sostenido sobre el límite, incluido reintentar sin esperar |
| Contrato de nómina | Convenio que protege la dispersión de pagos en el día de pago |
| Vigencia / referencial | Cuánto vive una copia; dato vencido servido con esa etiqueta |
| Origen | Sistema central de la cooperativa, del que se llenan las copias |
| Enlace entre nodos | Canal por donde los nodos A y B se reportan cuentas |
| Excedente | Peticiones sobre el límite; en Convenio se cobran, en los demás se rechazan |

Cifras de referencia, todas del problema original: 60 y 5,000 peticiones por hora de
una API conocida; un cliente a 100 veces su límite; 50,000 claves y 20,000 peticiones por
segundo en el pico; presupuesto fijo de memoria para la caché; dos nodos. Todo lo demás
(clientes, personas, planes y límites de Convenio, vigencias de cada clase de dato,
reglamento (a)-(h), horas y conteos de los ejemplos) es **inventado por esta extensión**:
son datos del ejercicio, no estadísticas. Lo que el estudiante fije (qué es abuso
«sostenido», cuánta imprecisión admite un conteo, qué se expulsa, la política cuando no
se sabe, qué regla gana) es supuesto suyo.

## Arquitectura (obligatoria)

- **Todo en SWI-Prolog**: estado, reglas, explicación y servidor web
  (`library(http/...)`, respuestas JSON bajo `/api/`, archivos estáticos para la interfaz).
- **Ninguna decisión del dominio fuera de Prolog.** Ni umbrales ni reglas en JavaScript,
  Python u otro lenguaje. La interfaz solo consulta y muestra.
- Python es opcional y solo **llamado desde Prolog** con Janus (`py_call/2`), para
  generar tráfico simulado o graficar. Prolog nunca es una librería de Python aquí.
- Sin `get_time`, `random` ni fecha del sistema en las reglas: el «ahora» es un hecho.
- Solo bibliotecas estándar de SWI-Prolog (`plunit`, `lists`, `aggregate`, `apply`,
  `clpfd`, `http`).
- Dentro de `gemelo/` aplica este stack, no el de Erlang/OTP del resto del repositorio.
  No modifiques el código Erlang ni `../problema/readme.md`.

## Vocabulario base de hechos

Punto de partida común; el estudiante puede añadir predicados, no renombrar estos.

```prolog
ahora(Segundo).                         % segundos desde las 00:00 del día del escenario
cliente(Cliente, Contrato).             % Contrato: nomina | estandar
llave(Llave, Cliente).                  % la cuota es del titular; sin llave: anónimo
plan(Cliente, Plan, Desde, Pago).       % Plan: anonimo | registrado | convenio
                                        % Desde: fecha efectiva; Pago: segundo o pendiente
autorizacion(Cliente, Accion, DadaPor, Desde, Hasta).  % ampliar(Limite) | suspender
calendario_pago(Cliente, Dia).          % día de pago; puede faltar o haberse movido
vigencia(Clase, Segundos).              % saldo | tasa | horario | reporte | visitas
peticion(Id, Llave, Recurso, Nodo, Segundo).  % Llave puede faltar; Nodo: a | b
respuesta(Id, Codigo, EsperaSegundos).  % 200 | 429 | 503, lo que se contestó
copia(Clave, Clase, Nodo, GuardadaEn).  % entrada de la caché, con su instante
conteo(Nodo, Cliente, Cuenta, Segundo). % cuenta que un nodo reporta de un cliente
evento(Sujeto, Suceso, Segundo).        % enlace_cae | enlace_regresa | origen_cae |
                                        % origen_regresa | cambio_en_origen | suspendido
```

Sin reglas. Las reglas del negocio las dicta el estudiante en español y las escribe él.
El azar no entra en las reglas: una caída o un retraso entra como hecho o como supuesto.

## Contrato del gemelo

- `decide(+Peticion, -Decision, -Explicacion)` — predicado central. `Decision` dice
  atender, dar 429 (con la espera), servir la copia, servirla como referencial, ir al
  origen o negar; si no se sabe, aplica la política declarada para la duda.
  `Explicacion` es una lista de hechos y condiciones, incluye qué reglas chocaron y cuál
  se impuso (el desempate) y, cuando compite con otra petición o entrada, la nombra.
- `situacion(?Entidad, ?Situacion, -Evidencia)` — situaciones deducidas sobre un
  cliente, una llave, una copia o un nodo (por ejemplo límite efectivo, hora corrida,
  copia confiable, tráfico de abuso, cuenta mínima y máxima posible), consultables en
  cualquier dirección.
- Toda condición distingue tres resultados: se cumple, no se cumple, no se sabe.
- La API expone al menos: el estado de clientes y copias, la decisión con su explicación,
  «qué falta para que cambie» y la respuesta a hipótesis («si el enlace no hubiera
  caído», «si la tasa no estuviera vencida»).

## Criterios de aceptación

Sin valores exactos a propósito: el estudiante fija su escenario y sus umbrales.

1. **Límite efectivo.** Una mejora de plan con fecha efectiva pasada y pago pendiente no
   sube el límite, y la explicación nombra la cadena (llave, titular, plan vigente,
   límite, peticiones de la hora corrida). Al confirmarse el pago, la misma consulta
   cambia de veredicto y el 429 dice cuándo cambiaría.
2. **Quincena.** Ante el cliente a 100 veces su límite, el gemelo separa los reintentos
   hechos antes de la espera del trabajo nuevo, verifica si hoy es día de pago (y dice
   «no se sabe» si el calendario falta), y no suspende sin la autorización que el
   reglamento exige. La respuesta nombra la regla que cedió y a quién se le falla.
3. **Copias.** Una copia de saldo dentro de su vigencia, tras una caída del enlace, da
   «no se sabe» y no se usa para autorizar un pago, aunque sí puede mostrarse con aviso;
   una tasa vencida con el origen caído se sirve como referencial y se niega para cerrar
   una operación. Nunca se afirma «no cambió» cuando solo se ignora.
4. **Avalancha.** Al expirar la tasa, la respuesta asigna un destino a cada petición y
   una entrada a expulsar, con la regla que prevaleció; nadie pasa al origen en
   silencio, y quien recibe 429 trae su razón. La hipótesis «memoria no llena» cambia
   el resultado.
5. **Dos nodos.** Sin enlace, la cuenta se reporta como mínimo conocido y máximo posible.
   Si el mínimo ya rebasa el límite se rechaza; si solo el máximo lo rebasa, da «no se
   sabe» y se aplica la política declarada. Al volver el enlace, la auditoría separa lo
   cobrable de lo perdonado por falla de la cooperativa y dice por qué.
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

Se diseña en Google Stitch antes de programarla. Debe mostrar el estado de cada cliente
(plan vigente, límite efectivo, peticiones de la hora, suspendido o no), las copias con
su confiabilidad, la petición con su decisión y su explicación, la respuesta a «qué
falta» y la bitácora de la auditoría. Debe verse bien en celular.
