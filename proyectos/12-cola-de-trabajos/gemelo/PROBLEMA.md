# #12 — Cola de trabajos: gemelo digital con programación lógica

> Extensión del proyecto #12. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste la cola: trabajos que entran, trabajadores que los
toman, fallas y reintentos. Esa simulación responde «¿qué está pendiente, en ejecución,
fallido o muerto?». Quien opera la cola necesita algo más: «¿en qué orden puede correr
todo esto, qué ya no va a correr nunca, y por qué?».

El gemelo digital es el **modelo lógico** de la cola: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ella. Se escribe en Prolog porque los trabajos no
son una fila sino una red de dependencias: hay que recorrerla, justificar cada turno y
saber decir «no lo sé».

## La cola que se clona

La cola de una aplicación web (correos, reportes, imágenes, llamadas a una API externa),
reducida a 12 trabajos de 3 tipos, 4 trabajadores y 1 servicio externo.

| Parte | Contenido |
|---|---|
| Entidades | tipo de trabajo → trabajo; dependencias entre trabajos; trabajadores; un servicio externo |
| Estado por trabajo | tipo (dura 50 ms, 2 s o 60 s), prioridad, de qué trabajos depende, si usa el servicio externo, su hora programada si la tiene, y su historia: cuándo se encoló, cuándo lo tomó un trabajador, cuándo terminó o falló |
| Estado del sistema | cuántos trabajadores hay (tope de 4, por los 4 núcleos del equipo) y si el servicio externo responde o está caído, y desde cuándo |
| Eventos | se encola un trabajo, un trabajador lo toma, termina, falla, el servicio externo se cae o vuelve, el sistema se reinicia |
| Decisiones | ¿en qué orden corren?, ¿quién ocupa un trabajador ahora?, ¿reintentar, esperar o dar por muerto?, ¿se vuelve a lanzar el trabajo dudoso?, ¿es creíble lo que dice el registro? |

## Situaciones que tu gemelo debe razonar

Las cuatro primeras salen del problema original; la quinta usa sus datos para plantear
algo que el original no pide: revisar el registro. En cada una, tu gemelo debe llegar a
una decisión **y poder explicarla**.

### Situación 1 — El orden que respeta las dependencias

- **Qué pasa.** Hay trabajos que dependen de otros: el correo que envía un reporte no
  sale antes de que el reporte exista. Si A depende de B y B de A, ninguno puede empezar.
- **Qué datos hay.** Los trabajos encolados y, para cada uno, de cuáles depende.
- **Qué debe deducir.** Un orden en el que ningún trabajo va antes que aquellos de los
  que depende, directa o indirectamente; y si existe un ciclo, qué trabajos lo forman.
- **Qué debe contestar.** El plan completo; si hay varios órdenes válidos, cuáles son;
  y, cuando no hay ninguno, el ciclo que lo impide en vez de un simple «no».
- **Por qué es lógica.** «Depende de», directa o indirectamente, es una relación que
  se define una vez y se recorre en cualquier dirección. Es un problema de grafos.

### Situación 2 — El trabajo muerto y los que esperaban por él

- **Qué pasa.** Un trabajo «envenenado» falla siempre y, tras N intentos, termina en la
  cola de muertos. Los que dependían de él siguen como pendientes, pero ya no van a
  correr. Si en cambio el servicio externo se cae 5 minutos, lo que lo usa solo se retrasa.
- **Qué datos hay.** Las dependencias, los fallos de cada trabajo, cuáles usan el
  servicio externo y el estado de ese servicio. Ningún dato dice «bloqueado».
- **Qué debe deducir.** Qué trabajos quedaron detenidos para siempre, cuáles solo están
  retrasados y cuáles no resultan afectados, siguiendo la red hasta el final.
- **Qué debe contestar.** La lista de afectados con la causa de origen de cada uno y el
  camino de dependencias que lo conecta con ella.
- **Por qué es lógica.** El bloqueo no es un dato de ningún trabajo: es una conclusión
  que se propaga por la red, y cambia según la razón por la que falló el origen.

### Situación 3 — Urgente, pero depende de uno lento

- **Qué pasa.** Sin prioridades, los trabajos largos (60 s) bloquean a los cortos
  (50 ms), y solo hay 4 trabajadores. Pero un trabajo corto y urgente puede depender de
  uno largo; y uno programado para «dentro de 3 horas» puede llegar a su hora con un
  requisito sin terminar.
- **Qué datos hay.** Prioridad, tipo, dependencias, hora programada, hora actual y
  trabajadores ocupados.
- **Qué debe deducir.** Qué regla manda cuando chocan la prioridad, la dependencia, la
  hora programada y el tope de trabajadores; y qué trabajos ocupan los lugares libres.
- **Qué debe contestar.** Quién corre ahora y quién espera; para cada uno que espera,
  la regla que lo detuvo y qué tendría que pasar para que le toque.
- **Por qué es lógica.** Las prioridades entre reglas se declaran una vez y valen para
  todos los casos, también para los que nadie previó.

### Situación 4 — ¿Terminó o no terminó?

- **Qué pasa.** El sistema se reinicia con trabajos en ejecución. La entrega es «al
  menos una vez»: si un trabajador no confirma en el tiempo de visibilidad (30 s), otro
  toma el trabajo y puede ejecutarse dos veces. Uno de 60 s rebasa ese tiempo siempre.
- **Qué datos hay.** Cuándo se tomó cada trabajo, si hay confirmación de que terminó,
  cuánto dura su tipo y la hora actual. Nadie registra «se ejecutó a medias».
- **Qué debe deducir.** Si el trabajo terminó, si no terminó o si no se puede saber; si
  repetirlo es inofensivo o peligroso; y qué pasa con los que dependen de él.
- **Qué debe contestar.** Tres respuestas distintas: «terminó», «no terminó» y «no lo
  sé». Para los dudosos, si se vuelven a lanzar o se retienen, y la razón.
- **Por qué es lógica.** «No hay confirmación» no significa «no se ejecutó». Y la duda
  se hereda: quien depende de un trabajo dudoso tampoco tiene su turno asegurado.

### Situación 5 — El registro que cuenta una historia imposible

- **Qué pasa.** El panel muestra qué está pendiente, en ejecución, fallido o muerto,
  pero el registro puede contar algo que no pudo ocurrir: un trabajo que terminó sin
  que nadie lo tomara, uno muerto que vuelve a ejecutarse, uno que corrió antes que su
  requisito, o un reintento lanzado antes de su espera (1 s, 2 s, 4 s, 8 s...).
- **Qué datos hay.** Los eventos de cada trabajo con su instante y las dependencias.
- **Qué debe deducir.** Si la historia de cada trabajo es una secuencia válida de
  estados y, si no lo es, cuál es el primer paso que la rompe.
- **Qué debe contestar.** Qué trabajos tienen una historia inconsistente y por qué; y,
  para cualquier trabajo, cuáles son los siguientes pasos válidos desde donde está.
- **Por qué es lógica.** La misma descripción de «qué puede seguir a qué» sirve para
  revisar una historia, para generar los pasos permitidos y para rendir cuentas.

## Por qué no basta un script

Con `while cola: ejecutar(cola.pop(0))` despachas una fila de trabajos que no dependen
entre sí y que nunca fallan. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Qué trabajos toman ahora los 4 trabajadores? | decisión |
| ¿Por qué el reporte va antes que el correo urgente? | explicación |
| ¿En cuántos órdenes válidos pueden correr estos seis trabajos? | todas las respuestas |
| ¿Qué tendría que pasar para que el trabajo 9 pueda correr? | la pregunta al revés |
| ¿Qué pasaría si el trabajo 3 termina en la cola de muertos? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir un trabajo en un instante?
2. Si el estado de un trabajo (pendiente, fallido, muerto) no se guarda, ¿de qué se deduce?
3. Cuando la prioridad y la dependencia se contradicen, ¿dónde queda escrito cuál gana?
4. ¿Cómo distingue tu gemelo «no terminó» de «no sé si terminó»?
5. En Erlang la cola, los trabajadores y los reintentos son procesos supervisados. ¿Qué
   de eso podría alimentar a este gemelo, y qué decide el gemelo que un proceso no puede?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la cola, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra el plan
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar trabajos y fallas
  simulados o graficar.

## Supuestos de esta extensión

- Escala reducida: 12 trabajos, 4 trabajadores y 1 servicio externo, contra los 10,000
  trabajos encolados de golpe y los 200 en ejecución al reiniciar del escenario original.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir. Por lo mismo, el *jitter* de los reintentos no se sortea en las
  reglas: tú decides cómo representarlo.
- Tú defines las dependencias y prioridades; el N de «N intentos», que el original no
  da; qué tipos se pueden repetir sin daño; qué regla gana en cada choque; y desde
  cuándo un trabajo tomado y sin confirmar está en duda. Decláralo como supuesto.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Trabajos con fecha límite: qué plan cumple todas y cuál trabajo es imposible de salvar.
- Límite de llamadas por minuto al servicio externo, repartido entre los trabajos.
- Varios servicios externos que dependen entre sí: qué cae cuando cae uno.
- Cancelar un trabajo: qué pasa con los que dependían de él y con lo ya ejecutado.

---
*Las cifras son de referencia y vienen del problema original. Verifica la fuente vigente
antes de citarlas en tu entrega.*
