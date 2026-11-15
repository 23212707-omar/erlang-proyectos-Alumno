# #35 — Control de calidad: gemelo digital con programación lógica

> Extensión del proyecto #35. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la línea de calidad: un proceso por lote que recibe
defectos y un evaluador que lo pasa de en inspección a aprobado o rechazado. Esa
simulación responde «¿cuántos defectos van y de qué color es el semáforo?». El ingeniero
de calidad necesita algo más: «¿paro la línea o solo aviso, qué lotes retengo y por qué,
y cómo se lo explico al cliente y al auditor?».

El gemelo digital es el **modelo lógico** de la línea: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque lo difícil aquí
no es contar defectos, sino deducir que el proceso se va, decidir cuando muestra y
proceso se contradicen y rastrear todo lo que un defecto pudo contaminar.

## La línea de calidad que se clona

Una planta de Tijuana que surte a un cliente automotriz y a uno de dispositivos médicos,
reducida a 3 características, 2 estaciones y 8 lotes. El tiempo se cuenta en minutos.

| Parte | Contenido |
|---|---|
| Entidades | planta → estación → característica; lote con su materia prima; cliente |
| Estado por característica | media y desviación de referencia, tolerancia, crítica o normal, rango físico |
| Estado por lote | tamaño, minuto y estación de producción, materia prima, muestreo, semáforo e historial |
| Eventos | se mide (minuto de medición y de captura), se inspecciona, se rechaza, se reinspecciona, se envía |
| Decisiones | ¿proceso bajo control?, ¿verde, amarillo o rojo?, ¿paro o solo aviso?, ¿qué contengo?, ¿reabro? |

## Situaciones que tu gemelo debe razonar

Las cinco parten del problema original: la 1 de las reglas de Western Electric/Nelson y
la deriva de la media, la 2 del muestreo por aceptación junto con la carta de control, la
3 y la 5 de sus «casos difíciles», la 4 del lote rechazado que comparte materia prima con
otros cuatro. Lo que añade esta extensión (criticidad, un cliente con la línea parada,
causa del rechazo pendiente) es complemento derivado. En cada una, tu gemelo debe llegar
a una decisión **y poder explicarla**.

### Situación 1 — La deriva que ninguna medición delata

- **Qué pasa.** Durante unas 3 horas la media de una característica crítica se corre
  poco a poco. Ninguna medición sale de los límites de ±3 desviaciones estándar y el Cpk
  calculado sigue por encima del mínimo común de 1.33 (1.67 en críticas). Producción dice
  que todo está verde. Cada lote que sale así puede llegar al cliente fuera de
  especificación.
- **Qué datos hay.** Mediciones con su minuto, media y desviación de referencia,
  tolerancia, criticidad y los lotes de cada tramo. Ningún dato dice «el proceso se
  desvía».
- **Qué debe deducir.** Si hay señal de causa especial según los patrones del original
  (8 puntos del mismo lado de la media, 6 en tendencia, 2 de 3 cerca del límite), desde
  qué medición empieza y qué lotes se produjeron en ese tramo.
- **Qué debe contestar.** Si procede parar la línea o solo avisar, y por qué (cadena:
  patrón → proceso inestable → lotes del tramo en duda → característica crítica), qué
  lotes se retienen y qué haría volver a verde. Lo intuitivo («ningún punto fuera de
  límites y buen Cpk, así que verde») es sospechoso: un Cpk calculado sobre un proceso
  que se mueve no describe al de mañana.
- **Por qué es lógica.** La señal nace de que varios hechos coincidan en el tiempo, no
  de un valor que cruce una línea; y pide reacción distinta según la característica.

### Situación 2 — La muestra pasó, el proceso no

- **Qué pasa.** Un lote de 1,000 piezas del tramo de la situación 1 se inspecciona con
  una muestra de 80 y los defectos hallados caen dentro de lo que el plan acepta. El
  cliente automotriz tiene su línea detenida esperando ese lote. Calidad dice que se
  produjo con el proceso señalado y no debe salir. Si se libera y falla, el cliente
  recibe pieza mala y la planta una sanción; si se retiene y estaba bien, se paga una
  línea parada ajena.
- **Qué datos hay.** El plan de muestreo, el resultado de la inspección, la señal de
  proceso con su minuto de inicio, la criticidad y el cliente.
- **Qué debe deducir.** Qué dice cada regla por separado (muestreo y carta de control) y
  cuál prevalece aquí, según cómo se declaren las prioridades.
- **Qué debe contestar.** El semáforo del lote, a quién se le falla (al cliente que
  espera o a la calidad) y con qué justificación, y qué evidencia lo cambiaría. Con la
  misma muestra pero una característica no crítica, o un lote anterior a la señal, la
  respuesta debe poder cambiar y explicarse.
- **Por qué es lógica.** Ambas partes tienen razón. La regla que decide se escribe una
  vez y la explicación nombra a la que perdió.

### Situación 3 — Mediciones que faltan o llegan desordenadas

- **Qué pasa.** En una estación, la medición de las 10:15 se capturó después de la de las
  10:30, faltan dos tomas seguidas y una medición trae un valor imposible (un dedazo).
  Es además el arranque de un producto nuevo, con pocas mediciones. Rojo por una racha
  no confirmada para una línea sin motivo; verde porque «no hay nada anormal» puede dejar
  pasar una deriva mientras nadie midió.
- **Qué datos hay.** Cada medición con minuto de medición y de captura, el rango físico
  de la característica y cuántas mediciones válidas hay.
- **Qué debe deducir.** Cuáles mediciones son válidas, imposibles o tardías; qué orden
  real tienen; y si con lo que hay un patrón se cumple, no se cumple o no se puede saber.
- **Qué debe contestar.** «Sí», «no» y «no lo sé» por patrón. Con huecos y pocos datos
  el semáforo no es verde por defecto ni rojo por sospecha, y el gemelo dice qué
  medición faltante lo resolvería. Con el orden de captura puede aparecer una tendencia
  que con el de medición no existe (o al revés).
- **Por qué es lógica.** «No se cumple» y «no tengo cómo saberlo» no son lo mismo, y el
  silencio de una estación no es una buena noticia.

### Situación 4 — El lote rechazado y todo lo que pudo contaminar

- **Qué pasa.** Se rechaza un lote que comparte materia prima con otros 4. De ellos, uno
  ya se envió al cliente médico, dos al automotriz y uno sigue en planta; uno se hizo
  mezclando dos lotes de materia prima. Un sexto lote, de la misma línea y turno, no
  tiene registrada su materia prima. La causa del rechazo no está confirmada: puede ser
  la materia prima o el proceso. Si se omite un lote, el defecto llega a un paciente o a
  un vehículo.
- **Qué datos hay.** Materia prima de cada lote (si se registró), envíos con su minuto,
  el minuto del rechazo, la causa (confirmada o pendiente) y las señales de la estación.
- **Qué debe deducir.** Los lotes que pueden estar afectados por cada posible causa,
  dónde está hoy cada uno (planta o cliente) y cuáles se enviaron después del rechazo.
- **Qué debe contestar.** Qué contener, a quién notificar y por qué cada lote está en la
  lista (materia prima, mezcla o tiempo en la línea). El lote sin registro es «no se
  sabe», no «limpio» ni «afectado». También la pregunta al revés, desde el reclamo de un
  cliente por un lote enviado.
- **Por qué es lógica.** Es recorrer relaciones entre entidades hacia adelante y hacia
  atrás, y la lista cambia según la causa. Buscar solo el lote rechazado deja fuera lo
  que importa.

### Situación 5 — Reabrir un lote rechazado

- **Qué pasa.** Un lote rechazado se reinspecciona y la nueva muestra sale limpia. El
  cliente pide liberarlo. La causa original era la deriva de una estación que sigue sin
  corregirse, y un lote que comparte materia prima con él sigue retenido. Luego, el
  auditor pregunta con qué información se decidió cada paso. Reabrir mal es mandar un
  lote ya declarado malo; negar sin razón es tirar producto bueno.
- **Qué datos hay.** Eventos del lote con quién y cuándo, ambas inspecciones, el estado
  de la causa y de los vecinos, y las mediciones ya capturadas en cada minuto (algunas
  llegaron tarde).
- **Qué debe deducir.** Si el lote puede cambiar de color, qué condiciones faltan, quién
  puede autorizarlo y qué prohíben las políticas aunque la muestra haya pasado.
- **Qué debe contestar.** La decisión justificada sin borrar el rechazo, qué faltaría
  para reabrir, y qué semáforo tenía el lote en un minuto pasado con lo que entonces se
  sabía, distinto del de hoy con todos los datos. Lo intuitivo («pasó la reinspección,
  vuelve a verde») es sospechoso: una muestra limpia no corrige una causa que sigue
  activa.
- **Por qué es lógica.** El semáforo no se guarda, se deduce del historial; así se puede
  preguntar por un minuto pasado o por «qué pasaría si esta medición no hubiera llegado
  tarde».

## Por qué no basta un script

Con `if defectos_en_muestra > maximo: rechazar()` resuelves un lote con una muestra
perfecta y un proceso estable. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué semáforo tiene el lote 5? | decisión |
| ¿Por qué amarillo si la muestra pasó? | explicación |
| ¿Qué lotes comparten materia prima con el lote 3? | todas las respuestas |
| ¿Qué medición falta para poder poner verde la estación 2? | la pregunta al revés |
| ¿Qué semáforo tendría el lote 5 si la medición de las 10:15 hubiera llegado a tiempo? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir una estación y un lote en un instante, y cuáles
   se deducen de las mediciones en lugar de guardarse?
2. Cuando la muestra dice «acepta» y el proceso dice «sospecha», ¿dónde queda escrito
   cuál gana y qué se le dice a quien pierde?
3. ¿Cómo distingue tu gemelo «el proceso está bajo control» de «no tengo mediciones
   suficientes para saberlo»?
4. ¿Qué parte de la cadena de trazabilidad le sirve al ingeniero de calidad y qué parte
   es ruido?
5. En tu simulación en Erlang, ¿qué garantizaba que defectos registrados al mismo tiempo
   dejaran un semáforo consistente, y qué le toca decidir al gemelo que ese mecanismo no
   decide?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la línea de calidad, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar mediciones simuladas
  o graficar la carta de control.

## Supuestos de esta extensión

- Escala reducida: 3 características, 2 estaciones y 8 lotes, contra las 6 características
  cada 15 minutos y los 20 lotes por turno del original. Tú generas los datos.
- El «ahora» es un hecho del modelo, en minutos desde el inicio de tu ventana, no el
  reloj del sistema, para que las respuestas se puedan repetir.
- Decisión tuya, escrita como supuesto: cuántos defectos acepta y rechaza el plan de
  muestreo; qué es «cerca del límite» en la regla de 2 de 3; qué características son
  críticas; cuántas mediciones válidas hacen falta para opinar de un proceso; qué manda
  cuando muestra y proceso se contradicen; qué es un lote «del tramo»; qué causa contiene
  por materia prima y cuál por tiempo; cuántas reinspecciones se permiten y quién
  autoriza reabrir.
- Las horas, los envíos de la situación 4, los identificadores («lote 5», «estación 2»)
  y la planta con sus dos clientes son ilustrativos e inventados.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Plan de muestreo que se endurece o se relaja según el historial reciente del proveedor.
- Calibración vencida de un instrumento: las mediciones que hizo, ¿valen?
- Ajuste de la máquina a media corrida y qué hacer con la carta de control después.
- Dos características correlacionadas: una en señal y otra aún no.
- Un reclamo del cliente que llega semanas después y pide la historia completa del lote.

---
*Las cifras de dominio (límites de ±3 desviaciones estándar, 8 puntos del mismo lado, 6 en
tendencia, 2 de 3 cerca del límite, Cpk de 1.33 y 1.67, lote de 1,000 piezas con muestra
de 80, 6 características cada 15 minutos, 20 lotes por turno, deriva de 3 horas, lote
rechazado con otros 4 que comparten materia prima) vienen del problema original. Los demás
números (la escala de 3 características, 2 estaciones y 8 lotes, y los ejemplos) son de
esta extensión. Verifica la fuente vigente antes de citarlas en tu entrega.*
