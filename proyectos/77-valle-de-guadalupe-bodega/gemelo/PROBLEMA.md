# #77 — Valle de Guadalupe, bodega: gemelo digital con programación lógica

> Extensión del proyecto #77. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la vendimia: tanques con su fase, sensores de temperatura
y densidad, fallas inyectadas. Esa simulación responde «¿qué está pasando en cada
tanque?». El enólogo necesita algo más: «¿qué hago ahora, a quién aviso y por qué?».

El gemelo digital es el **modelo lógico** de la bodega: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque aquí no se
calcula: se deduce lo que ningún sensor mide, se justifica cada paso y se sabe decir
«no lo sé».

## La bodega que se clona

Una bodega pequeña del Valle de Guadalupe en plena vendimia, reducida a 8 tanques y
4 variedades (dos tintas y dos blancas o rosadas), con lecturas cada 15 minutos.

| Parte | Contenido |
|---|---|
| Entidades | bodega → tanque → lote de uva; camisa de glicol por tanque; sensores de temperatura y densidad; análisis de laboratorio |
| Personas | el enólogo de guardia, el jefe de bodega y el propietario |
| Estado por tanque | lote que contiene y desde cuándo, fase, temperatura (°C), densidad, °Brix del último análisis, si la camisa de glicol tiene orden de enfriar |
| Estado por lote | variedad, tipo (tinto, blanco o rosado), fecha de recepción, tanques por los que ha pasado, lotes con los que se mezcló |
| Eventos | llega una lectura, un sensor deja de reportar, se ordena enfriar, falla el glicol, se hace un remontado, se trasiega o se mezcla, se pide cambiar de fase, se avisa a alguien |
| Decisiones | ¿es una desviación normal o una emergencia?, ¿está atorada la fermentación?, ¿se puede cambiar de fase y quién lo autoriza?, ¿de qué lote es este vino?, ¿a quién despierto? |

## Situaciones que tu gemelo debe razonar

Las cinco salen del problema original: cada una retoma su escenario, sus casos difíciles,
sus preguntas guía o sus datos del mundo real, y le añade el detalle que obliga a
razonar. En cada una, tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — ¿Desviación normal o emergencia?

- **Qué pasa.** Una noche, un tinto en fermentación activa sube 1 °C por hora porque la
  camisa de glicol dejó de enfriar. Pero la fermentación es exotérmica: un tanque sano
  también se calienta, y casi siempre hay alguno fuera de su rango un rato. A más de
  ~35 °C las levaduras sufren y se detienen: azúcar residual, riesgo de bacterias y miles
  de litros en juego. Al enólogo le toca distinguir el calor de siempre de la falla.
- **Qué datos hay.** Temperatura con su instante, tipo de lote, fase, la orden de enfriar
  y si la camisa está abierta. Ningún sensor mide «falló el glicol» ni «se va a pasar».
- **Qué debe deducir.** Si el tanque está dentro de lo normal para su tipo y su fase, en
  una desviación tolerable o en emergencia; si el enfriamiento ordenado está haciendo
  efecto o se contradice con lo que mide el sensor; y qué tan cerca está el punto en que
  las levaduras sufren, según hacia dónde va la temperatura.
- **Qué debe contestar.** El veredicto con sus razones y qué tanque de la bodega es el
  más urgente esa noche. Lo intuitivo es que sea el más caliente; revisa si es cierto.
- **Por qué es lógica.** La emergencia no está en ningún dato: nace de encadenar fase,
  tipo, rango, tendencia y una orden que el sensor desmiente.

### Situación 2 — La densidad que dejó de bajar

- **Qué pasa.** En un tanque la densidad lleva 3 días sin bajar. Pueden ser tres cosas
  distintas: una fermentación atorada (azúcar que se quedó sin consumir, riesgo de
  bacterias), una fermentación que ya terminó porque se acabó el azúcar, o un sensor de
  densidad atascado. La alcohólica dura de 5 a 14 días y el °Brix baja de 1 a 2 grados
  por día mientras fermenta activa. Decidir mal es perder el lote o abrirlo antes de
  tiempo.
- **Qué datos hay.** Lecturas de densidad con su instante, temperatura, tiempo en la fase
  y análisis de laboratorio cuando los hay. Ningún dato dice «atorada».
- **Qué debe deducir.** Cuál de las tres explicaciones sostienen los datos, si ninguna
  (o más de una) y qué análisis o lectura faltaría para decidir entre ellas.
- **Qué debe contestar.** «Atorada», «terminó», «sensor sospechoso» o «no lo sé», con la
  evidencia; y qué le falta saber. Una densidad quieta no siempre es mala noticia, ni
  cumplir los días de la fase prueba que terminó.
- **Por qué es lógica.** Varias explicaciones compiten por los mismos datos, y «no
  tengo cómo saberlo» es una respuesta válida y distinta de «no pasa nada».

### Situación 3 — El paso sin vuelta atrás

- **Qué pasa.** Las fases van de la recepción y el estrujado, a la maceración en frío, la
  fermentación alcohólica, la maloláctica, la crianza y el embotellado. Algunos pasos no
  se deshacen: un vino sacado antes de tiempo de la alcohólica se queda con azúcar, y
  uno embotellado no vuelve al tanque. Llega camión de uva, el jefe de bodega necesita
  liberar un tanque y el enólogo dice que el vino no está listo. Los dos tienen razón.
- **Qué datos hay.** Fase vigente y desde cuándo, análisis, quién pide el cambio, quién
  está en turno y lo que cada rol puede autorizar.
- **Qué debe deducir.** Qué pasos son válidos hoy para cada tanque, cuáles son
  irreversibles, quién puede autorizar cada uno y qué pasa cuando falta el análisis que
  habilita el paso.
- **Qué debe contestar.** El siguiente paso válido, con las alternativas, o la secuencia
  válida hasta la fase pedida; si el cambio se niega, por qué y con quién habría que
  pasar. En el choque entre la uva que espera y el vino que no está listo, a quién se le
  falla y por qué.
- **Por qué es lógica.** Es razonar sobre secuencias permitidas y sobre quién puede
  mover qué, no sobre un contador de días.

### Situación 4 — ¿Sigue siendo el mismo lote?

- **Qué pasa.** Un tanque se trasiega a otro, después dos lotes se mezclan (coupage) y el
  tanque vacío recibe uva de otro lote. Semanas más tarde aparece un problema de calidad
  en lo que sale de un tanque: hay que decir de qué uvas viene y qué más está tocado.
- **Qué datos hay.** Lotes con variedad y fecha, qué tanque contuvo qué y desde cuándo,
  trasiegos, mezclas y análisis. Ningún dato dice «este vino viene de...».
- **Qué debe deducir.** El linaje de un tanque, paso por paso; qué lote ocupa hoy cada
  tanque; y, al revés, qué tanques descienden de un lote dado.
- **Qué debe contestar.** La procedencia con cada trasiego y mezcla que la sustenta, y
  la lista de tanques afectados si un lote resulta malo. Si falta el registro de un
  trasiego, ese tramo es «no se sabe», no un lote inventado. Que sea el mismo tanque no
  implica que sea el mismo lote; tú decides cuándo un lote sigue siéndolo.
- **Por qué es lógica.** La trazabilidad es una relación que se recorre hacia atrás y
  hacia adelante con las mismas reglas.

### Situación 5 — La madrugada: ¿a quién despierto y cuándo?

- **Qué pasa.** A las tres de la mañana hay dos alertas abiertas (por ejemplo, la del
  glicol y una densidad sin bajar) y un solo enólogo de guardia, que no contesta. Hay jefe
  de bodega y propietario. Despertar a alguien por lo normal gasta su confianza; no
  hacerlo por una emergencia cuesta un lote. Mientras, los tintos esperan su remontado.
- **Qué datos hay.** Alertas con su instante, quién está de guardia en cada horario, a
  quién ya se avisó, qué respondió o si calló, y los remontados pendientes.
- **Qué debe deducir.** Cuál alerta se atiende primero, a quién se avisa ahora, cuándo
  se escala al siguiente, y por qué un silencio puede ser que no contestó, que no se le
  avisó o que no se sabe si lo recibió.
- **Qué debe contestar.** El aviso con persona, motivo y momento, y el porqué de lo que
  no se hizo (rendición de cuentas). La alerta más grave no siempre es la que se atiende
  primero: piensa qué se puede salvar todavía y qué ya no.
- **Por qué es lógica.** Cada alerta pasa por estados (abierta, avisada, atendida,
  escalada) y hay que razonar con los recursos que faltan y con el silencio.

## Por qué no basta un script

Con `if temperatura > 35: avisar()` resuelves un tanque con datos perfectos y nadie
dormido. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué hago con el tanque 3? | decisión |
| ¿Por qué? | explicación |
| ¿Qué tanques están hoy en emergencia? | todas las respuestas |
| ¿Qué tendría que pasar para que el tanque 3 pase a maloláctica? | la pregunta al revés |
| ¿Qué pasaría si el glicol del tanque 3 falla a las tres de la mañana? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir un tanque en un instante, y cuáles son lecturas?
2. ¿Qué transición de fase es irreversible y quién la autoriza?
3. ¿Qué diferencia una desviación normal de una emergencia, y dónde queda escrita?
4. ¿Cómo distingue tu gemelo «la densidad no baja» de «no sé si la densidad baja»?
5. Tu `gen_statem` por tanque en Erlang: ¿qué fases y transiciones permitía, y cuáles
   tendría que explicar el gemelo y no solo ejecutar?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la bodega, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar lecturas simuladas o
  graficar.

## Supuestos de esta extensión

- Escala reducida: 8 tanques y 4 variedades, contra los 30 tanques y 6 variedades del
  escenario original; lecturas cada 15 minutos, como el original, sobre unos días de
  vendimia y no las tres semanas.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir.
- Los tanques, números y horas de los ejemplos («tanque 3», las tres de la mañana) y las
  personas de la bodega son del ejercicio; lo que cada rol puede autorizar lo defines tú
  (el original solo pregunta quién autoriza).
- Las decisiones tuyas, porque el original no da la cifra ni la regla: cuánto subir por
  hora es emergencia, qué margen es «cerca» de ~35 °C, rangos por fase (el original los
  da por tipo de vino, no por fase), cuánto °Brix residual cuenta como «terminó», cuánto
  silencio vuelve dudoso a un sensor, cuándo un lote deja de ser el mismo y cuánto
  esperar a que alguien conteste antes de escalar.
- El original no cuadra del todo consigo mismo: 24 °Brix bajando de 1 a 2 por día
  tardan más que los 5 a 14 días de la alcohólica. Verifícalo y anota tu criterio.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Capacidad de glicol compartida: no alcanza para enfriar todos los tanques a la vez.
- Orden de recepción de uva y asignación de tanques cuando llegan varios camiones.
- Crianza en barrica: rotación de barricas y trazabilidad de su historial.

---
*Las cifras son de referencia y vienen del problema original. Verifica la fuente vigente
antes de citarlas en tu entrega.*
