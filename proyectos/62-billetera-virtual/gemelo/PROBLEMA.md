# #62 — Billetera virtual: gemelo digital con programación lógica

> Extensión del proyecto #62. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la billetera: un proceso por cuenta, un coordinador de
transferencias, una bitácora de movimientos y una caída a mitad de una transferencia. Esa
simulación responde «¿se movió el dinero sin crearse ni perderse?». Quien opera la
billetera necesita algo más: «¿esta operación debe pasar, en qué estado está, y qué le
digo a quien reclama?».

El gemelo digital es el **modelo lógico** de la billetera: hechos que reflejan su estado
y reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque lo difícil aquí
no es sumar, sino decidir qué operación es legítima y justificarlo ante cliente y auditor.

## La billetera que se clona

Una billetera virtual de una fintech mexicana, reducida a 6 cuentas de personas, una
cuenta del sistema (contraparte del mundo exterior), 2 bancos externos y un día de
operación. La billetera y las personas son del ejercicio, no empresas reales.

| Parte | Contenido |
|---|---|
| Entidades | titular → cuenta; cuenta del sistema; bancos externos; solicitudes de transferencia |
| Estado por cuenta | nivel de cuenta, estado de la verificación de identidad, movimientos |
| Estado por movimiento | cuenta, monto en centavos (entero), transferencia a la que pertenece, instante; no se modifica ni se borra |
| Estado por transferencia | clave de idempotencia, origen, destino, monto y su historia: sucesos con instante |
| Estado del sistema | si cada banco externo responde, y los límites de cada nivel |
| Eventos | llega una solicitud, se registra un débito o un crédito, se envía al banco, el banco confirma o devuelve, cae el sistema, vence una verificación |
| Decisiones | ¿aceptar?, ¿es un reintento?, ¿cuánto puede gastar ahora?, ¿qué sigue para esta transferencia?, ¿cómo se repara? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original: la 1, 2, 3 y 5 de su problema, escenario y casos
difíciles; la 4 solo de sus datos del mundo real, que mencionan los límites antifraude, el
nivel de cuenta y la verificación de identidad sin dar cifras. En cada una, tu gemelo debe
llegar a una decisión **y poder explicarla**.

### Situación 1 — Cien pesos, dos órdenes de ochenta

- **Qué pasa.** Marisol tiene 100 pesos. Casi a la vez entran dos órdenes suyas de 80
  pesos: una a Beto, desde el celular, y otra a Chuy, desde el sitio web. Solo una puede
  tener éxito, y la que llegó primero por la red no es necesariamente la que quedó
  primero en la bitácora. En una variante, Marisol tiene además una transferencia a otro
  banco todavía pendiente.
- **Qué datos hay.** Movimientos de Marisol, las dos solicitudes con su llegada y su
  orden de registro, y los sucesos de su transferencia pendiente. Ningún dato dice «este
  es su saldo disponible» ni «esta orden va primero».
- **Qué debe deducir.** Cuánto puede gastar Marisol cuando le toca a cada orden, cuál va
  primero según un criterio de orden que **tú declaras**, y si la segunda alcanza.
- **Qué debe contestar.** Cuál se acepta, cuál se rechaza y por qué se rechaza, con el
  saldo que había en ese momento y no el de hoy. Es un dilema: las dos tienen razón y a
  una persona se le falla; la regla debe justificar a cuál. Si los hechos no alcanzan para
  ordenarlas, «no lo sé». Lo intuitivo es «con 100 pesos pasa una de las dos»; en la
  variante con la transferencia pendiente, sospéchalo.
- **Por qué es lógica.** El saldo no está en ningún campo: es una conclusión de los
  movimientos y de lo comprometido. El orden se declara una vez y vale para las 100
  operaciones simultáneas del escenario original.

### Situación 2 — El mismo «enviar 200 pesos», dos o tres veces

- **Qué pasa.** Por mala señal, la app de Beto manda «enviar 200 pesos a Ana» hasta tres
  veces. A veces es el mismo intento; a veces la app generó otra clave para él; a veces
  Beto de verdad le paga 200 dos veces; y una vez la misma clave llega con otro monto. Si
  cobras de más, pierde Beto; si descartas un pago real, pierde Ana.
- **Qué datos hay.** Las solicitudes con su clave, origen, destino, monto y momento, y el
  resultado ya registrado de cada clave. Ningún dato dice «esto es un reintento».
- **Qué debe deducir.** Para cada solicitud: si repite una anterior, es nueva o
  contradice una clave ya usada; y qué resultado corresponde a un reintento cuando el
  primer intento fue rechazado, terminó o sigue en curso.
- **Qué debe contestar.** «Reintento: mismo resultado, sin mover dinero», «operación
  nueva», «clave reutilizada con otro contenido» o «no lo sé» (dos claves distintas con
  todo lo demás igual: ¿dos pagos o un duplicado?), siempre con las razones. Lo intuitivo
  es «mismo monto, mismo destino, mismos segundos: duplicado». Sospéchalo. Si el primer
  intento fue rechazado por saldo insuficiente y el reintento llega cuando ya hay saldo,
  tu gemelo debe decir qué política aplica y por qué.
- **Por qué es lógica.** Reconocer un reintento es comparar contra la historia, no mirar
  una solicitud. «Duplicado» y «no puedo saber si lo es» obligan a tres resultados.

### Situación 3 — La transferencia al otro banco que no contesta

- **Qué pasa.** Ana envía dinero a otro banco. La transferencia queda *pendiente*: el
  dinero ya salió de su saldo en la app pero no ha llegado, y el banco puede confirmarla o
  devolverla en minutos. Mientras, Ana intenta gastar ese dinero otra vez. El banco deja
  de contestar y luego llegan avisos desordenados: una confirmación dos veces, o una
  devolución después de una confirmación.
- **Qué datos hay.** Los sucesos de la transferencia con su instante, si el banco responde
  desde cuándo, y los movimientos de Ana. Ningún dato dice «sigue pendiente» ni «Ana puede
  gastar tanto».
- **Qué debe deducir.** En qué etapa de su vida está la transferencia y qué sucesos son
  posibles desde ahí; cuánto puede gastar Ana mientras tanto; y cuándo un aviso es
  repetido o imposible. Una cadena: sucesos → etapa → dinero comprometido → qué puede
  hacer.
- **Qué debe contestar.** La etapa con su razón; qué se hace con cada aviso (aplicarlo,
  ignorarlo por repetido, marcarlo como imposible); y «no lo sé» cuando el banco no
  contesta pasados los minutos esperados. Lo intuitivo es «pasó el tiempo, falló: devuelve
  el dinero a Ana». Sospéchalo: devolver algo que quizá ya se liquidó crea dinero de la
  nada. Dilema: Ana quiere su dinero y el sistema debe proteger sus invariantes.
- **Por qué es lógica.** La etapa es consecuencia de una secuencia de sucesos válidos, no
  un campo que alguien actualiza, y «sin noticias» no es lo mismo que «falló».

### Situación 4 — El monto que hoy sí y mañana no

- **Qué pasa.** Beto quiere enviar un monto grande para pagar una cirugía. El límite
  depende del nivel de su cuenta, de su verificación de identidad (aprobada, pendiente o
  vencida) y de lo que ya movió hoy: envió dinero, recibió una devolución y una
  transferencia suya fue rechazada. Su verificación venció esta mañana. Si la billetera
  deja pasar de más, arriesga una sanción; si bloquea de más, Beto no paga a tiempo.
- **Qué datos hay.** Nivel, estado y fecha de la verificación, los movimientos de hoy con
  su tipo y resultado, y los límites de cada nivel (los fijas tú). Ningún dato dice «lo
  que Beto ya gastó hoy» ni «el nivel que le aplica ahora».
- **Qué debe deducir.** Qué movimientos cuentan para el límite del día; qué nivel aplica
  ahora; qué margen queda; y si una verificación sin dato se puede dar por buena. Una
  cadena: movimientos → acumulado → nivel efectivo → límite → margen.
- **Qué debe contestar.** Permitir, rechazar o exigir una acción (por ejemplo, volver a
  verificar), con la regla que mandó, y qué tendría que cambiar para poder enviar ese
  monto. «No lo sé» cuando falta el dato de la verificación. Es un choque entre
  cumplimiento y cliente: tu gemelo debe decir a quién se le falla y por qué.
- **Por qué es lógica.** Los límites son políticas declaradas una vez; una misma
  operación cambia de veredicto según el contexto de la cuenta.

### Situación 5 — Se cayó entre el débito y el crédito

- **Qué pasa.** El sistema cae justo entre el débito y el crédito de una transferencia.
  Al volver hay transferencias a medias: con débito y sin crédito, y por un fallo de
  escritura alguna con crédito y sin débito (dinero creado de la nada). Los movimientos
  no se pueden borrar. El destinatario de una de ellas fue bloqueado mientras tanto, y
  la conciliación del día no cuadra.
- **Qué datos hay.** Movimientos y sucesos con su instante, el estado de las cuentas y la
  cuenta del sistema. Ningún dato dice «a medias», «no cuadra» ni «la causa es esta».
- **Qué debe deducir.** Qué transferencias están incompletas o inconsistentes; en cuánto
  se desvía la suma del sistema de lo que debería ser y qué transferencias lo explican;
  y qué salidas son legítimas desde cada estado.
- **Qué debe contestar.** Por cada transferencia: completar, compensar con un movimiento
  nuevo, o «no lo sé», con la causa de la desviación. Dilema: completar le cumple al
  destinatario, compensar le devuelve a la persona que envió; con el destino bloqueado,
  alguien pierde. Lo intuitivo es «borra el crédito huérfano»; sospéchalo.
- **Por qué es lógica.** Auditar es deducir qué pasó a partir de lo que quedó. La suma
  total del sistema debe dar cero siempre, y esa invariante señala dónde buscar.

## Por qué no basta un script

Con `if saldo >= monto: transferir()` resuelves una cuenta, un solo hilo, sin reintentos
y sin caídas. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Acepto la orden de Marisol a Beto? | decisión |
| ¿Por qué se rechazó la de Chuy? | explicación |
| ¿Cuáles transferencias quedaron a medias? | todas las respuestas |
| ¿Qué tendría que cambiar para que Beto envíe ese monto hoy? | la pregunta al revés |
| ¿Qué pasaría si el banco B confirmara hasta mañana? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué invariantes nunca pueden romperse, y qué hechos necesitas para detectar que se
   rompió una después de una caída?
2. ¿Cómo reconoce tu gemelo un reintento legítimo de una operación nueva?
3. ¿Cómo distingue «el banco falló» de «no sé si el banco falló»?
4. ¿Qué parte de la explicación le sirve al cliente, cuál a quien audita y cuál es ruido?
5. En Erlang cada cuenta es un proceso y un coordinador recupera transferencias a medias.
   ¿Qué de eso podría alimentar a este gemelo, y qué decide el gemelo que un proceso no
   puede?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la billetera, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar solicitudes simuladas
  o graficar saldos.

## Supuestos de esta extensión

- Escala reducida: 6 cuentas, una cuenta del sistema y 2 bancos externos en un día, contra
  las 10,000 cuentas y las 50 transferencias por segundo del escenario original. Los
  titulares y bancos son del ejercicio, no negocios reales.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir. Las llegadas simultáneas, un reintento, una caída o un banco mudo
  entran como hechos; las reglas no sortean nada.
- Los montos en pesos de los ejemplos (100, 80, 200) vienen del original, pero los
  nombres («Marisol», «Beto», «Ana», «banco B») y los números de transferencia son del
  ejercicio. Tú los usas en centavos, enteros, como pide el original.
- Tú defines, y lo declaras como supuesto: cuántos niveles de cuenta hay y cuánto permite
  cada uno, qué movimientos cuentan para el límite del día, cuándo vence una verificación
  y qué pasa si falta el dato, cuántos minutos son «demasiados» para un banco pendiente,
  el criterio de orden entre solicitudes simultáneas y qué política sigue un reintento
  de una operación rechazada. El original no da esas cifras ni esas reglas.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Contracargo cuando el destinatario ya gastó el dinero y su saldo no alcanza.
- Cuenta de un menor o de un negocio, con apoderados y firmas conjuntas.
- Cobros recurrentes que chocan con un saldo comprometido o con un límite.
- Patrones sospechosos: muchas cuentas pequeñas enviando a una sola.

---
*Las cifras de dominio (100 y 80 pesos, 200 pesos con 2 o 3 repeticiones, transferencias
externas que tardan minutos, 10,000 cuentas, 50 transferencias por segundo, 5 % de
reintentos y 100 operaciones simultáneas) vienen del problema original; los límites por
nivel, la escala y los ejemplos son del ejercicio. Verifica la fuente vigente antes de
citarlas en tu entrega.*
