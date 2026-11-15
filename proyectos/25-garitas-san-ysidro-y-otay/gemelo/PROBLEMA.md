# #25 — Garitas San Ysidro y Otay: gemelo digital con programación lógica

> Extensión del proyecto #25. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang simulaste las garitas: un proceso por carril que recibe lecturas
cada 15 minutos, un predictor con promedios móviles, un incidente que dispara la espera
y un carril que deja de reportar. Esa simulación responde «¿cuánto se espera?». Quien
tiene que cruzar necesita algo más: «¿por dónde cruzo, cuándo salgo, y por qué?».

El gemelo digital es el **modelo lógico** de las garitas: hechos que reflejan su estado y
reglas que reflejan cómo se decide en ellas. Se escribe en Prolog porque lo que hay que
resolver aquí no es promediar, sino decidir qué dato creer, qué carril le toca a cada
viaje y qué ruta conviene, y poder justificarlo, incluso cuando hay que decir «no sé».

## Las garitas que se clonan

Las dos garitas hacia el norte, reducidas a 7 carriles, 3 zonas de origen en Tijuana y una
mañana de lunes (patrón de alta demanda que menciona el original).

| Parte | Contenido |
|---|---|
| Entidades | zona de origen → garita (San Ysidro, Otay) → carril; viajes con sus ocupantes |
| Carriles | San Ysidro: General, Ready Lane, SENTRI. Otay: esos tres y FAST (comercial) |
| Estado por carril | lecturas de espera con su fuente y su hora; historia del mismo día y hora |
| Estado por garita | cuántas cabinas abren y si hay un incidente o una revisión que frene a todos |
| Estado del viaje | zona de salida, tipo (auto o camión de carga), ocupantes y sus credenciales |
| Eventos | llega una lectura propia, se actualiza el feed oficial, un carril deja de reportar, una garita sufre un incidente, alguien pide una recomendación, un viaje cruza |
| Decisiones | ¿cuánta espera creer?, ¿avisar?, ¿qué carriles puede usar este viaje?, ¿qué ruta y a qué hora?, ¿fue razonable lo que se recomendó? |

## Situaciones que tu gemelo debe razonar

Tres salen del problema original (la 1, la 2 y la 4, esta con complementos); la 3 y la 5
plantean algo nuevo con sus datos: qué carril puede usar cada viaje y rendir cuentas de
una recomendación. En cada una, tu gemelo debe llegar a una decisión **y poder
explicarla**.

### Situación 1 — Dos fuentes, dos esperas, un carril callado

- **Qué pasa.** Son las 7:40. Para el General de San Ysidro hay una lectura propia de
  hace pocos minutos y un dato del feed oficial de la agencia CBP, que se actualiza cada
  1 o 2 horas y siempre va atrasado respecto a la realidad. Dicen cosas distintas. Y el
  Ready Lane de la misma garita lleva 2 horas sin reportar.
- **Qué datos hay.** Lecturas de espera con su fuente y su hora, el rango físico
  razonable de una espera, qué carriles son hermanos (misma garita) y lo que pasó a esta
  hora en las últimas cuatro semanas. Ningún dato dice «la espera creíble ahora».
- **Qué debe deducir.** Para cada carril, qué espera se puede sostener hoy y con qué base:
  medida, inferida de sus hermanos y de la historia, o desconocida. Un silencio no es
  una fila corta ni un carril cerrado: puede ser cualquiera de las dos o una falla.
- **Qué debe contestar.** Para cada carril, la espera con su estado («sabido»,
  «inferido» o «no lo sé»), las lecturas que la sustentan y la edad de cada una. Una
  inferencia nunca se presenta como lectura. Qué lectura faltaría para dejar de dudar.
- **Por qué es lógica.** Quien ve un número viejo como si fuera de hoy decide mal: cruza
  tarde o desiste cuando no debía. «Corta» y «no sé» no son lo mismo, y distinguirlas es
  razonar sobre relaciones entre fuentes, carriles y tiempo, no leer un valor.

### Situación 2 — El salto de la espera y el aviso que cuesta

- **Qué pasa.** En media hora la espera de un carril sube de 40 a 150 minutos. Puede
  ser un incidente real, o un sensor que falló y mintió. Avisar a quienes van en camino
  puede salvarles horas, o puede mandar a miles a la otra garita por una falsa alarma
  y saturarla. Callar hasta estar seguro puede dejarlos atrapados en la fila.
- **Qué datos hay.** Las lecturas de los carriles hermanos y de la otra garita, cuántas
  cabinas abren, el feed oficial con su atraso y la historia del mismo día y hora. Ningún
  dato dice «incidente».
- **Qué debe deducir.** Si hay incidente: se cumple, no se cumple o no se sabe, según
  cuántas fuentes independientes concuerdan y si el salto es de un carril o de la garita
  entera. Un promedio móvil que suaviza el salto no puede ocultarlo.
- **Qué debe contestar.** El veredicto con su evidencia; si avisar, esperar o avisar con
  reservas; a quién se le falla con cada decisión (a los atrapados o a los desviados en
  vano); y qué observación nueva resolvería la duda.
- **Por qué es lógica.** Dos partes tienen razón: la prisa y la prudencia. La regla que
  decide entre ellas se escribe una vez y se justifica ante cualquiera.

### Situación 3 — Qué carril le toca a este viaje

- **Qué pasa.** Un auto lleva tres personas. Una tiene credencial de viajero confiable
  vigente; otra, un documento con RFID vigente; de la tercera el registro no dice nada,
  aunque ella afirma que la tiene. El carril SENTRI es hoy el más corto. Aparte, un camión
  de carga solo tiene carril comercial en Otay, aunque San Ysidro esté más despejado.
- **Qué datos hay.** Los carriles y su tipo, las credenciales de cada ocupante con su
  estado (vigente, vencida o que no consta) y la espera de cada carril, con su base.
- **Qué debe deducir.** Qué carriles puede usar cada viaje de verdad. Hay conflicto entre
  la espera más corta y el derecho a usar ese carril. «No consta» no es «no tiene».
- **Qué debe contestar.** Los carriles permitidos, los prohibidos y los condicionados a
  que algo se confirme, con la razón de cada uno y qué se pierde si el viaje se equivoca
  de carril. La pregunta al revés: qué tendría que constar para abrir el SENTRI.
- **Por qué es lógica.** Una credencial dudosa de una sola persona cambia la respuesta
  de todo el grupo, y la espera más corta puede estar fuera de alcance.

### Situación 4 — La garita con menos espera hoy no es la mejor

- **Qué pasa.** Un lunes a las 6:00, una conductora debe cruzar con una cita al otro
  lado. San Ysidro tuvo un incidente hace poco; la gente que estaba ahí empieza a
  cambiarse a Otay. En el original, las esperas dependen de cuántas cabinas abren, la
  hora, los incidentes y las revisiones secundarias, y en pico pueden pasar de 3 horas.
- **Qué datos hay.** Las esperas actuales por carril, el traslado desde su zona a cada
  garita, la historia del mismo día y hora, el incidente y la hora a la que llegaría a
  cada garita. Ningún dato dice cuánto esperará *cuando llegue*.
- **Qué debe deducir.** El incidente empuja demanda a Otay; esa demanda sube su espera
  con algún retraso; el traslado fija a qué hora se llega; y la espera que importa es la
  de esa hora, no la de ahora. Con eso, qué rutas (zona, garita, carril) son viables.
- **Qué debe contestar.** Todas las rutas posibles ordenadas, con el tiempo total
  estimado de cada una, su incertidumbre y el supuesto en que descansa. Cuándo salir:
  ya o más tarde. Si dos rutas son indistinguibles, que lo diga en vez de elegir al azar.
- **Por qué es lógica.** Una cascada de tres o más pasos entre garitas, carriles y horas
  es una red por recorrer. Lo intuitivo es ir a donde la espera es hoy menor; aquí eso
  puede ser lo peor, y el gemelo debe poder defender por qué.

### Situación 5 — «¿Por qué me mandaste ahí?»

- **Qué pasa.** El lunes a las 6:30 el gemelo recomendó a un trabajador, que cruza todos
  los días, un carril de Otay. Esperó casi tres horas y llegó tarde a su turno. Su
  patrón pide cuentas: ¿fue un error del sistema o mala suerte?
- **Qué datos hay.** Las lecturas y los eventos con su hora, la recomendación que se
  emitió con su minuto y el cruce real. El «ahora» es un hecho, así que se puede volver
  a preguntar con el «ahora» de entonces.
- **Qué debe deducir.** Qué sabía el gemelo a las 6:30 y qué solo se supo después, y
  con lo que sabía, qué habría recomendado. Intuitivo: si salió mal, se recomendó mal.
  No siempre: un hecho posterior o la falta de datos explican el resultado sin culpar a
  la lógica.
- **Qué debe contestar.** Uno de tres veredictos: justificada con lo que se sabía, mal
  razonada con lo que se sabía, o debió abstenerse por falta de datos. Con las lecturas
  que lo sustentan y la señal que habría cambiado el resultado, si la hubo.
- **Por qué es lógica.** Rendir cuentas es razonar sobre el pasado con el conocimiento
  de entonces, y las mismas reglas deben servir para decidir hoy y para auditar ayer.

## Por qué no basta un script

Con `carril = min(esperas, key=esperas.get)` eliges el carril más corto con datos
perfectos. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Por dónde cruza el viaje 7 desde la Zona Río? | decisión |
| ¿Por qué no por el SENTRI de San Ysidro, si hoy es el más corto? | explicación |
| ¿Qué carriles puede usar este auto con estas tres personas? | todas las respuestas |
| ¿Qué tendría que constar para que la familia use el SENTRI? | la pregunta al revés |
| ¿Qué pasaría si Otay cierra cabinas a las 9? ¿Qué se habría recomendado a las 6:30? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio: es el programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir un carril en un instante, y cuáles son
   lecturas y cuáles inferencias?
2. ¿Cuándo prefieres decir «no sé» a dar un número, y cómo lo distingue tu gemelo de
   una espera corta?
3. ¿Cuánta historia pesa más: la de hace 15 minutos o la del mismo día y hora de hace
   4 semanas? ¿Dónde queda escrito?
4. Cuando el aviso y la prudencia chocan, ¿dónde queda escrito cuál gana y a quién se
   le falla?
5. ¿Qué proceso de tu simulación en Erlang (un carril, el predictor, el dato obsoleto
   del dashboard) podría alimentar a este gemelo?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de las garitas, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para simular lecturas o graficar.

## Supuestos de esta extensión

- Escala reducida: 2 garitas, 7 carriles, 3 zonas de origen y una mañana, contra el
  escenario completo del original (2 garitas, 3 tipos de carril, lecturas cada 15 min).
- Los tiempos de traslado, el rango de una espera creíble, el desfase con que un
  incidente empuja demanda a la otra garita, cuántas lecturas hacen falta para creer un
  salto y cuánto atraso vuelve vieja una lectura los defines tú y los declaras.
- Las credenciales de los ocupantes, qué credencial habilita qué carril (el original solo
  dice «documentos con RFID» y «viajero confiable») y que todos los ocupantes de un auto
  deban cumplirlo son reglas de este ejercicio, no de la agencia: verifícalas.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas se
  puedan repetir y se pueda preguntar «¿qué sabías a las 6:30?». Los identificadores y
  horas de los ejemplos («viaje 7», «las 9») son ilustrativos.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Filas peatonales, que tienen otra dinámica que los carriles vehiculares.
- Camiones de carga con inspección secundaria y su efecto sobre el carril comercial.
- Cruce hacia el sur, en el regreso de los domingos por la tarde.
- Día festivo de uno de los dos países que cambia el patrón de demanda.

---
*Las cifras de las garitas (3 horas de espera en pico, lecturas cada 15 minutos, feed de
1 a 2 horas, salto de 40 a 150 minutos en 30, silencio de 2 horas) vienen del problema
original y son órdenes de magnitud; verifica la fuente vigente antes de citarlas. La
escala reducida, los traslados y las credenciales de los ocupantes son de esta extensión.*
