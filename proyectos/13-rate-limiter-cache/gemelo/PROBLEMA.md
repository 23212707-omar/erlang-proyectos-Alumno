# #13 — Rate limiter / caché: gemelo digital con programación lógica

> Extensión del proyecto #13. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En Erlang construiste un limitador con token bucket, una caché en ETS y un limpiador de
expiraciones. Esa simulación responde «¿aguanta el pico?». Quien opera una API pública
necesita algo más: «¿a quién se atiende, a quién se le dice que espere, y qué copia
guardada todavía es creíble?».

El gemelo digital es el **modelo lógico** de la operación: hechos que reflejan su estado
y reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque aquí no se
trata de contar rápido, sino de **conceder, negar, desempatar y justificar**.

## La plataforma que se clona

«Frontera Abierta» es la API que una cooperativa de ahorro de Tijuana (Caja Frontera)
ofrece a aplicaciones de terceros. **No existe: es un escenario planteado por esta
extensión**; el original pide un limitador y una caché sin dueño. Se reduce a 6 clientes
con 8 llaves, 2 nodos de la API y 5 clases de dato.

| Parte | Contenido |
|---|---|
| Entidades | clientes titulares (casa de cambio, fintech de nómina, comercio, app turística) y sus llaves; visitantes anónimos por dirección; nodos A y B; clases de dato en caché |
| Personas | Marisol, gerente de plataforma (cambia planes, autoriza excepciones); Ernesto, oficial de seguridad (suspende clientes); los desarrolladores de cada cliente; el auditor interno |
| Estado por cliente | plan y fecha efectiva, pago confirmado o pendiente, ampliación escrita, contrato de nómina y día de pago, peticiones de la última hora, suspensión |
| Estado por copia | clase de dato, nodo, cuándo se guardó, si se sabe de un cambio en el origen |
| Eventos | llega una petición y se contesta; un cliente cambia de plan o paga; cae o regresa el enlace entre nodos; cae o regresa el sistema central (el origen); cambia un dato en el origen |
| Decisiones | ¿se atiende o se da 429, y con qué espera?; ¿es abuso?; ¿se sirve la copia?; ¿a quién primero?; ¿qué se expulsa?; ¿qué se cobra? |
| Reglamento (inventado) | (a) la cuota por hora es del cliente titular y la comparten todas sus llaves; sin llave, es por dirección de red y de plan Anónimo; (b) planes: Anónimo 60 por hora, Registrado 5,000, Convenio 20,000, contados en cualquier hora corrida, no en la hora del reloj; (c) un cambio de plan rige desde su fecha efectiva, pero una mejora solo cuenta con pago confirmado; una ampliación firmada por gerencia reemplaza al plan, no se suma, mientras esté vigente; (d) al rebasar el límite se contesta 429 con tiempo de espera; reintentar sin esperar cuenta como abuso, y el abuso sostenido lo suspende el oficial de seguridad; (e) un cliente con contrato de nómina no se suspende en su día de pago sin autorización de gerencia, y el contrato fija multa si falla el pago a sus trabajadores; (f) cada clase de dato tiene vigencia: saldo 30 segundos, tasa de cambio 5 minutos, horario de sucursales 6 horas, reporte mensual 1 día; con el origen caído solo la tasa y el horario pueden servirse vencidos, marcados «referencial» y hasta el doble de su vigencia; un saldo nunca se sirve vencido, y para autorizar un pago ni una copia vigente sirve si pudo cambiar; para cerrar una operación de cambio la tasa nunca puede ir vencida; (g) el origen atiende una consulta de tasa a la vez y la memoria de la caché es fija y está llena; (h) los nodos se reportan la cuenta de cada cliente; sin enlace, cada uno conoce solo la suya y el último reporte; el excedente de un Convenio se cobra por petición, el de los demás planes se rechaza, y a nadie se le cobra por una falla de la cooperativa |

## Situaciones que tu gemelo debe razonar

Las cinco las plantea esta extensión y todas retoman un caso del original (planes
cambiados en caliente, el cliente a 100 veces su límite, datos obsoletos, la llave popular
que expira, dos nodos). En cada una, tu gemelo debe llegar a una decisión **y poder
explicarla**.

### Situación 1 — ¿Cuál es el límite de esta llave a las 10:40?

- **Qué pasa.** Cambios del Pacífico, una casa de cambio, tiene plan Registrado y pidió
  subir a Convenio con fecha efectiva a las 10:30; su pago se confirma hasta las 10:52.
  Tiene dos llaves (web y móvil) y ya sumó más de 5,000 peticiones desde las 9:40. A las
  10:40 llega otra con la llave móvil. Si se rechaza mal, sus clientes en la ventanilla
  no pueden cotizar; si se acepta mal, se regala un plan que no se ha pagado.
- **Qué datos hay.** Planes con fecha efectiva, pagos, ampliaciones, llaves y titulares,
  y cada petición con su instante. Ningún dato dice «este es su límite».
- **Qué debe deducir.** En cadena: la llave es de un titular, luego la cuota se comparte
  con la otra llave, luego qué plan rige a las 10:40, luego qué límite resulta, luego
  cuántas peticiones caen en la hora corrida, y de ahí si cabe una más.
- **Qué debe contestar.** Atender o dar 429, con el límite que aplicó y por qué; cuánto
  esperar; y qué tendría que pasar para que la respuesta cambie.
- **Por qué es lógica.** El límite no se mide: se concluye de hechos de distintas
  personas y fechas, y cambia a mitad de la hora.

### Situación 2 — Quincena: el cliente que parece atacar

- **Qué pasa.** Es día de pago y NóminaYa, fintech con contrato de nómina, dispersa pagos
  de miles de trabajadores. Manda 100 veces su límite por hora y el sistema se ralentiza
  para los demás. Ernesto quiere suspenderlo; Marisol, la única que puede autorizar lo
  contrario, no contesta. Si lo suspenden, miles no cobran y la cooperativa paga multa;
  si no, los otros clientes se quedan sin servicio.
- **Qué datos hay.** Peticiones por segundo, cuántas recibieron 429 y con qué espera,
  cuáles son reintentos hechos antes de esa espera, el calendario de pago (el día 15 cayó
  en domingo y quizá se adelantó) y las autorizaciones registradas.
- **Qué debe deducir.** Qué parte del tráfico es reintento que ignora la espera y qué
  parte es trabajo nuevo; si hoy es de verdad su día de pago; si la suspensión está
  permitida sin autorización; y a quién se le falla con cada salida.
- **Qué debe contestar.** Suspender, dejar pasar o frenar solo a ese cliente, con quién
  pierde, qué regla cedió y qué dato (o quién) cambiaría el veredicto.
- **Por qué es lógica.** Dos partes tienen razón: la protección y el contrato chocan, y la
  política que decide se declara una vez, con su justificación.

### Situación 3 — El saldo que sigue ahí (y la tasa que ya venció)

- **Qué pasa.** El nodo B guardó el saldo de una socia a las 10:00:00. Desde las
  10:00:05 su enlace con el origen, por donde llegan los avisos de cambio, está caído.
  A las 10:00:25 llegan dos consultas por ese saldo: una de la app que solo lo muestra y
  otra de un comercio que quiere autorizar un pago. Además B guarda una tasa de cambio de
  hace 8 minutos. Un saldo falso hace rechazar un pago legítimo o aceptar uno sin fondos;
  una tasa vieja en una operación cuesta dinero.
- **Qué datos hay.** Cuándo se guardó cada copia, su vigencia, qué eventos hubo y cuándo,
  y para qué se pide cada consulta. Nadie dice si el saldo cambió durante la caída.
- **Qué debe deducir.** Qué tan creíble es cada copia (no hay dato de «frescura») y, según
  el uso, si se sirve. Si el saldo cambió es «no se sabe», no «no cambió».
- **Qué debe contestar.** Por consulta: servir la copia, servirla como referencial, ir al
  origen o negarla, con su razón; y «sí», «no» o «no sé» sobre si la copia es confiable.
- **Por qué es lógica.** Lo intuitivo es mirar la vigencia: el saldo parece bueno y la
  tasa mala. Pero lo servible depende del uso y de lo que se ignora, y a veces es lo contrario.

### Situación 4 — Las siete de la mañana: la tasa expira y no cabe todo

- **Qué pasa.** A las 7:00 expira la tasa de cambio, la llave más pedida. Llegan miles de
  peticiones: Cambios del Pacífico (que necesita la tasa vigente para cerrar operaciones),
  registrados y anónimos. El origen solo atiende una consulta de tasa a la vez. Además
  la memoria está llena: guardar la tasa nueva obliga a expulsar una entrada, y una
  candidata es un reporte mensual que a un cliente Convenio le costó mucho calcular. Si el origen se
  satura, nadie recibe nada; si todos reciben la copia vieja, la casa de cambio cierra mal.
- **Qué datos hay.** Las peticiones por plan y para qué se usa la tasa, la copia vencida,
  el estado del origen, y el tamaño, uso y costo de rehacer cada entrada.
- **Qué debe deducir.** Quién recibe la copia vencida como referencial, quién espera el
  dato nuevo, a quién se le da 429, quién pasa primero al origen y qué entrada sale.
- **Qué debe contestar.** Un destino por petición y la entrada expulsada, con la regla
  que prevaleció y a quién se le falló.
- **Por qué es lógica.** Recursos que no alcanzan y reglas opuestas: la prioridad se
  declara una vez y el «¿y si no estuviera llena?» usa las mismas reglas.

### Situación 5 — Dos nodos, un solo límite

- **Qué pasa.** Pagos Playas, cliente Convenio, comparte su cuota entre los nodos A y B.
  Entre las 14:10 y las 14:14 cae el enlace entre ellos. En el último reporte A contaba
  9,000 y B 8,000 peticiones de la hora; en la caída A siguió contando y B quedó mudo. A
  las 14:12 llega otra petición a A. Al volver el enlace, B informa de 4,000 nuevas. El
  auditor revisa el excedente: el cliente dice que lo causó la caída, no él.
- **Qué datos hay.** Conteos con su instante por nodo, eventos del enlace, el plan.
- **Qué debe deducir.** Qué sabe A a las 14:12 (cuánto es seguro que ya se contó y hasta
  cuánto pudo haber llegado); si se pasó del límite; y después, cuánto fue el excedente y
  quién lo originó.
- **Qué debe contestar.** A las 14:12: atender, rechazar o «no se sabe», con el rango de
  la cuenta y la política aplicada. Al cerrar: qué se cobra, qué se perdona y por qué.
- **Por qué es lógica.** Se razona con cotas, no con un número, y la auditoría repite la
  misma lógica con los datos completos.

## Por qué no basta un script

Con `if peticiones_en_la_hora > limite_del_plan: responder_429()` resuelves un cliente
con un solo nodo y un solo plan. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Se atiende la petición 31 de la llave móvil? | decisión |
| ¿Por qué se rechazó si el plan ya era Convenio? | explicación |
| ¿Qué peticiones de las 7:00 reciben la tasa vieja? | todas las respuestas |
| ¿Qué tendría que cambiar para servir ese saldo de copia? | la pregunta al revés |
| ¿Qué habría pasado si el enlace no hubiera caído? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir a un cliente y su cuota en un instante?
2. Cuando «proteger a los demás» choca con «cumplir el contrato», ¿dónde queda escrito
   cuál gana y qué haría falta para que cambie?
3. ¿Cómo distingue tu gemelo «la copia es buena» de «no sé si la copia es buena»?
4. ¿Qué parte de la explicación le sirve al cliente rechazado y cuál solo al auditor?
5. En Erlang decidiste si el conteo podía ser impreciso a cambio de velocidad. ¿Qué
   decide el gemelo con esa imprecisión, y qué hace cuando ya no se puede ignorar?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la plataforma, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch: solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en ella.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para simular tráfico o graficar.

## Supuestos de esta extensión

- Inventado por esta extensión: «Frontera Abierta», Caja Frontera, sus clientes, personas,
  llaves, nodos, el reglamento (a)-(h), el plan Convenio y las vigencias de cada clase de
  dato. Son datos del ejercicio. Los 60 y 5,000 por hora de Anónimo y Registrado
  vienen del original como ejemplo de una API conocida.
- Escala reducida: 6 clientes, 8 llaves, 2 nodos y 5 clases de dato (el original maneja
  50,000 claves). Los números de los ejemplos (peticiones, instantes, 8 minutos, día 15)
  son datos del ejercicio, no estadísticas.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir. Caídas y retrasos no se sortean: entran como hechos.
- Tú defines y declaras como supuesto: cuándo el abuso es «sostenido»; cuánta imprecisión
  admite un conteo; cuándo un reintento «ignora» la espera; la política cuando no se sabe
  si el enlace perdió peticiones; qué se expulsa y por qué criterio; qué regla gana en
  cada choque.

## Extensiones posibles

Para quien quiera ir más lejos; investiga y cita tus fuentes antes de fijar cifras.

- Algoritmos de límite distintos (token bucket, ventana deslizante) y cómo cambian lo
  que se concede en una ráfaga.
- Clientes de un mismo grupo corporativo con una cuota común.
- Datos que dependen unos de otros: si cambia el saldo, qué copias se invalidan.

---
*Las cifras del dominio (60 y 5,000 peticiones por hora, 100 veces el límite, dos nodos,
memoria fija) vienen del problema original. El escenario, el plan Convenio y las
vigencias son inventados: verifica la fuente vigente de toda cifra antes de citarla.*
