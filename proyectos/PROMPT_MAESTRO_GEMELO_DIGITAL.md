# Prompt maestro — Extensión «gemelo digital» en Prolog para los 81 proyectos

Sustituye a `PROMPT_UNIVERSAL_PROLOG.md` (enfoque anterior: ejercicio con esqueleto y
solución).

Uso: pegar el bloque de abajo en Claude indicando el número de proyecto (`N`). Para
lotes, cambiar «el proyecto N» por «los proyectos A al B»; el prompt obliga a
procesarlos de uno en uno.

Archivos de apoyo:
- `proyectos/01-vinedos/gemelo/` — piloto. Es el modelo de tono, estructura y extensión,
  no de contenido.
- `proyectos/06-estacionamiento-inteligente/gemelo/` — segunda prueba (eje restricciones),
  generada con este prompt.
- `proyectos/12-cola-de-trabajos/gemelo/` — tercera prueba (eje grafos, dominio sin
  sensores), generada «en frío» por un agente sin más contexto que este archivo.
- `proyectos/21-pruebas-de-caos/gemelo/` — cuarta prueba (eje transiciones, proyecto
  muy alineado a Erlang): escenario inventado, generada «en frío».
- `proyectos/EJES_PROLOG.csv` — eje y foco de cada proyecto.

---

```text
Actúa como docente de Programación Lógica. Vas a REDACTAR la extensión «gemelo digital»
del proyecto N del repositorio (carpeta proyectos/NN-nombre/).

## Idea central
Los 81 proyectos nacieron como simulaciones en Erlang/OTP; esa parte está terminada y no
se toca. La extensión plantea, sobre el MISMO dominio, un reto del mundo real que se
resuelve con programación lógica: un gemelo digital, es decir, el modelo lógico del
sistema real (hechos que reflejan su estado, reglas que reflejan cómo se decide en él).

Tú redactas el reto y el contexto para agentes. NO escribes la solución: el estudiante
la construye, de forma individual, con apoyo de OpenCode. Muchos estudiantes vienen de
Python: la redacción debe dejar claro que Prolog aquí es el programa, no un accesorio.

## Arquitectura que la redacción debe imponer
- Todo en SWI-Prolog: estado, reglas, explicación y servidor web propio (library(http),
  JSON bajo /api/, archivos estáticos para la interfaz).
- Ninguna decisión del dominio fuera de Prolog.
- Python solo opcional y llamado DESDE Prolog con Janus. No menciones FastAPI ni ningún
  otro servidor.
- Interfaz diseñada en Google Stitch; solo consulta y muestra.

## Lectura obligatoria (no inventes)
1. proyectos/01-vinedos/gemelo/PROBLEMA.md y CONTEXTO_AGENTES.md (el piloto).
2. La fila N de proyectos/EJES_PROLOG.csv: eje_principal, eje_secundario y foco.
3. proyectos/NN-*/problema/readme.md completo: contexto, datos del mundo real, escenario
   a simular, casos difíciles y preguntas guía.
4. proyectos/NN-*/README.md (diseño OTP sugerido) y un vistazo a src/. En casi todos
   los proyectos src/ es solo un esqueleto: en ese caso apóyate en el «Diseno OTP
   sugerido» del README para hablar de la parte de Erlang.
No modifiques ninguno de esos archivos.

## Cómo encontrar las situaciones
Recorre estos siete tipos preguntando «¿qué pasa en este dominio que caiga aquí?»:
1. Las reglas cambian con la etapa o el contexto de la entidad.
2. Acciones que se estorban entre sí (prioridades y conflictos).
3. Recursos que no alcanzan (asignación, calendarización).
4. El espacio o la red importan (vecindad, propagación, rutas, dependencias).
5. Lo que dice el sistema contra lo que pasa (orden, actuador y sensor se contradicen).
6. Eventos externos que cambian varias reglas a la vez.
7. Hipotéticos y rendición de cuentas («qué pasaría si», auditoría).

Escoge CINCO situaciones:
- Al menos tres deben estar PLANTEADAS en el problema original: en sus «casos difíciles»,
  su «escenario a simular», «el problema» o sus «datos del mundo real».
- Las demás pueden ser derivadas: construidas con datos del original aunque este no las
  plantee, o exigidas por el foco del CSV (el foco autoriza contenido que el original
  no menciona, sin cifras). En la Entrega di cuáles son planteadas y cuáles derivadas.
- Al menos una debe ser algo que NINGÚN dato mide directamente y se deduce de varios.
- Al menos una debe ser un conflicto entre reglas o acciones.
- Al menos una debe tratar el dato dudoso o faltante («no lo sé» distinto de «no»).
- El eje del CSV decide cuál pesa más: experto → deducción y explicación;
  politicas → elegibilidad, límites y desempates; transiciones → secuencias válidas;
  restricciones → asignar o calendarizar; grafos → rutas, dependencias y cascadas.
- Ninguna situación puede resolverse comparando un solo número con un umbral. Si puede,
  descártala o compleméntala.

Cifras del dominio (umbrales, tiempos, porcentajes, cantidades reales): usa solo las del
problema original. No cuentan como cifras, pero se declaran en «Supuestos»: los números
de la escala reducida que tú elijas (pequeños: que el escenario quepa en una pantalla) y
los identificadores o cantidades de los ejemplos («trabajo 9», «diez autos más»). Un
ejemplo ilustrativo sin cifras, propio del dominio, sí está permitido. Lo que sepas por conocimiento general y no
esté ahí NO entra en las cinco situaciones: va a «Extensiones posibles», sin cifras.
Si una situación necesita un umbral que el problema original no da (por ejemplo, cuánto
tiempo vuelve sospechoso a un sensor), NO lo inventes: déjalo como decisión del
estudiante y anótalo en «Supuestos de esta extensión».

## Si el proyecto no trae un problema lógico (OBLIGATORIO resolverlo, no rendirse)
Algunos proyectos son casi pura técnica de Erlang/OTP (clúster, observabilidad, release,
pruebas de caos, rate limiter...). Su problema original habla de procesos y nodos, no de
decisiones del mundo real. Erlang ya no es el tema de esta extensión, así que en esos
casos NO fuerces situaciones sobre supervisores ni reinicios: INVENTA el reto lógico.

Haz esta prueba antes de escoger situaciones: ¿puedes sacar del original al menos tres
situaciones que una persona del negocio (no un programador) reconocería como decisiones
suyas? Si no:
1. Elige un escenario del mundo real donde ese tema importe y dale dueño, lugar y
   consecuencias. Ejemplos: un clúster → los servidores de un hospital o de una
   tienda en línea en Buen Fin, y qué servicio se sacrifica si cae un nodo; un rate
   limiter → una API pública con planes de cliente, abusos y excepciones; un release →
   el despliegue de un sistema de nómina con ventanas, dependencias y marcha atrás;
   pruebas de caos → el programa de simulacros de falla de una empresa que está
   vendiendo, y quién autoriza qué; observabilidad → la guardia nocturna de un servicio
   público que debe decidir a quién despertar.
   VARÍA el sector: no repitas «tienda en línea en Buen Fin». Piensa en salud,
   transporte, banca, escuelas, gobierno, logística, energía, turismo, y de preferencia
   en Baja California, como el resto de los proyectos.
2. Puedes conectar complementos que el original no tiene: actores (clientes, turnos,
   proveedores), reglas de negocio, contratos de servicio, normas, calendario, costos,
   prioridades entre personas. Lo que haga falta para que haya algo que deducir,
   justificar y negociar. En la tabla de «El <sistema> que se clona» añade las filas
   «Personas» y «Reglamento (inventado)».
   Las reglas del NEGOCIO se escriben en prosa y son necesarias: el estudiante debe
   conocer el reglamento para modelarlo. Lo prohibido son las reglas en Prolog y el
   cómo se resuelven los choques entre ellas.
   En un escenario inventado SÍ puedes fijar sus números (plazos, topes, vigencias,
   penalizaciones): son datos del ejercicio. Fíjalos cuando hagan la situación más
   precisa y exigente, y lístalos en «Supuestos».
3. Las cinco situaciones salen de ese escenario. Siguen valiendo los mínimos de tipo
   (una deducida, un conflicto, un dato dudoso) y la regla de que ninguna se resuelve
   con un solo umbral. El mínimo de «tres planteadas en el original» NO aplica. Si una
   situación inventada retoma un caso o un dato del original, dilo: cuenta como
   «inventada que retoma el original».
4. Honestidad con el estudiante: en «El <sistema> que se clona» di en una frase que el
   escenario es una simulación planteada por esta extensión, y en «Supuestos» lista lo
   inventado. Adapta también la frase de entrada de las situaciones y la nota final
   sobre las cifras para que digan la verdad (qué viene del original y qué no). El
   título de esa sección nombra lo que de verdad se clona (la plataforma, la
   operación, el programa...). Los números del escenario inventado son datos del ejercicio, no hechos del
   mundo: no los presentes como estadísticas reales ni cites fuentes que no leíste.
5. La conexión con Erlang se reduce a una frase y a la pregunta guía 5; no organices el
   reto alrededor de ella.
Esto también vale para proyectos con problema real pero pobre en lógica: sustituye las
situaciones flojas por inventadas hasta tener cinco buenas, marcándolas como «planteadas
por esta extensión».

## Sé agresivo: el original es un punto de partida, no una jaula
Aplica a TODOS los proyectos, tengan o no problema lógico:
- Ante la duda entre un reto fiel pero plano y uno inventado pero exigente, elige el
  exigente. Una situación del original que resulte tibia se cambia por una mejor.
- Cada situación tiene algo en juego para alguien concreto: dinero, tiempo, salud,
  seguridad, una sanción, la confianza de un cliente. Si nadie pierde nada cuando el
  gemelo se equivoca, la situación no sirve.
- De las cinco, al menos:
  · una exige encadenar tres o más deducciones (A implica B, B con C implica D...);
  · una es un dilema real, donde dos partes tienen razón y la regla debe decidir y
    justificar a quién se le falla;
  · una tiene una respuesta correcta que contradice la intuición (lo «obvio» está mal).
    Puedes decir qué es lo intuitivo y por qué es sospechoso, y los criterios de
    aceptación pueden decir qué veredicto se espera; lo que no se revela es la regla
    ni el camino para llegar a él.
- Mete el mundo real con todo: excepciones a la regla, casos de frontera, gente que
  miente o se equivoca al capturar, normas que cambian de un día a otro, recursos que
  se acaban a media operación, dos sistemas que no se ponen de acuerdo.
- Estos mínimos se suman a los de tipo (deducida, conflicto, dato dudoso); una misma
  situación puede cubrir varios.
- El límite no cambia: nada de reglas ni solución en la redacción, y lo inventado se
  declara como supuesto, nunca como estadística real.

## Archivo 1: proyectos/NN-*/gemelo/PROBLEMA.md (para el estudiante)
Mismas secciones y mismo orden que el piloto:
1. Título «#N — <Nombre>: gemelo digital con programación lógica» (el nombre es el del
   título de problema/readme.md, sin «: el problema») y la nota inicial
   con los enlaces al problema original y a CONTEXTO_AGENTES.md.
2. «Del simulador al gemelo»: qué respondía la simulación y qué pregunta nueva hay.
3. «El <sistema> que se clona»: escala reducida y tabla de entidades, estado, eventos y
   decisiones.
4. «Situaciones que tu gemelo debe razonar»: la frase de entrada debe ser cierta (si
   alguna situación es derivada, no escribas «las cinco salen del problema original»:
   di cuáles sí y cuál plantea algo nuevo). Luego las cinco, cada una con sus cinco partes:
   Qué pasa · Qué datos hay · Qué debe deducir · Qué debe contestar · Por qué es lógica.
5. «Por qué no basta un script»: un ejemplo imperativo de UNA línea propio del dominio
   y la tabla de cinco preguntas (decisión, explicación, todas las respuestas, la
   pregunta al revés, hipótesis) con ejemplos del dominio.
6. «Preguntas guía» (cinco; la última conecta con la simulación Erlang del proyecto).
7. «Qué entregas» (igual que el piloto, ajustando solo los textos al dominio).
8. «Supuestos de esta extensión» (escala reducida frente al escenario original; el
   «ahora» como hecho; qué datos define el estudiante).
9. «Extensiones posibles» (tres a cinco, sin cifras).
10. La nota final sobre las cifras.

Prohibido en PROBLEMA.md: reglas Prolog, cláusulas, seudocódigo de la solución o
umbrales que el problema original no dé. Sin calendario por día ni por clase.
Extensión: similar al piloto (unas 140 a 170 líneas, con líneas de ~90 caracteres);
hasta unas 190 si el escenario es inventado, porque hay que presentar actores y reglamento.

## Archivo 2: proyectos/NN-*/gemelo/CONTEXTO_AGENTES.md (para OpenCode)
(No lo llames AGENTS.md: ese nombre está en .gitignore y no llegaría al estudiante.)
Mismas secciones que el piloto:
1. Tu papel: explicar, preguntar y proponer; no entregar la solución; pedir la regla en
   español antes de escribirla; prueba antes que regla; una situación a la vez; no
   inventar cifras.
2. Dominio: glosario y cifras de referencia. Las cifras reales, todas del problema
   original; los términos y números del escenario inventado van marcados como tales.
3. Arquitectura (obligatoria): copia las reglas del piloto, sin cambios de fondo.
4. Vocabulario base de hechos: solo cabeceras de hechos del dominio (nombre, aridad y un
   comentario), entre 6 y 12. Incluye siempre ahora/1, con su unidad en el comentario
   (la que mejor sirva a los tiempos del dominio). Si hay mediciones de sensores,
   rango/3 y un hecho de lectura con su instante; si hay sucesos (ciclo de vida,
   bitácoras), un hecho de evento con su instante. Pueden convivir. Sin reglas.
   Si el dominio tiene azar (por ejemplo, jitter), las reglas no sortean nada: el
   valor entra como hecho o queda como supuesto del estudiante.
5. Contrato del gemelo: decide(+Entidad, -Decision, -Explicacion) como predicado
   central. En ejes de restricciones o grafos, el primer argumento es la LISTA de
   solicitudes (puede ser de una) y Decision es el reparto, plan o ruta completo; al
   pedir más soluciones debe dar las demás alternativas válidas; y si no existe
   ninguna (ciclo, recursos insuficientes) lo dice y señala el motivo, sin fallar en
   silencio. En el eje transiciones la entidad es una sola (el vuelo, el pedido, el
   simulacro) y Decision incluye el siguiente paso o la secuencia válida, con sus
   alternativas al pedir más soluciones;
   situacion(?Entidad, ?Situacion, -Evidencia); los tres resultados (se cumple, no se
   cumple, no se sabe); qué expone la API.
6. Criterios de aceptación: uno por situación más el de las cinco preguntas, en prosa
   y sin valores exactos.
7. Verificación: los mismos comandos y nombres de archivo sugeridos del piloto.
8. Interfaz: qué debe mostrar, en el dominio.

## Autorrevisión antes de entregar (corrige lo que falle)
- [ ] Cada situación tiene sus cinco partes y no se resuelve con un solo umbral.
- [ ] Se cumplen los mínimos de tipo (una deducida, un conflicto, un dato dudoso) y,
      salvo que el escenario sea inventado, el de tres planteadas en el original.
- [ ] Toda cifra presentada como dato real se puede señalar en problema/readme.md; lo
      inventado para el escenario está listado en «Supuestos».
- [ ] Las cinco situaciones son decisiones que reconocería alguien del negocio, no
      detalles de Erlang/OTP.
- [ ] Cada situación tiene algo en juego para alguien concreto.
- [ ] Hay una cadena de tres o más deducciones, un dilema real y una respuesta que
      contradice la intuición (di cuál es cuál en la Entrega).
- [ ] No hay reglas ni solución en ninguno de los dos archivos.
- [ ] No aparecen FastAPI ni Python como anfitrión; Janus solo como opción invertida.
- [ ] Los enlaces relativos entre archivos existen.
- [ ] Un estudiante que nunca vio el dominio lo entiende leyendo solo PROBLEMA.md.

## Idempotencia y límites
- Si proyectos/NN-*/gemelo/ ya existe, no lo sobrescribas: dilo y detente.
- Añade al README.md del proyecto la línea
  «- Extensión gemelo digital (Prolog): [gemelo/PROBLEMA.md](gemelo/PROBLEMA.md)»
  solo si no existe ya (compruébalo con grep), al final del archivo y bajo un
  encabezado «## Extension».
- No toques el código Erlang, problema/readme.md ni design/.
- No crees código Prolog en el repositorio.
- En lotes: un proyecto a la vez; si uno no pasa la autorrevisión, detente ahí.

## Registro
Anota en bitacora/LOG.md (arriba, con fecha) el proyecto, su eje, los títulos de las
cinco situaciones y el resultado real de la autorrevisión. En bitacora/TODO.md no hay
casilla por proyecto: añade «Revisión del proyecto N por el usuario» sin marcar y no
marques nada que no hayas hecho tú. No dupliques entradas.

## Entrega
Lista de archivos creados; una línea con el eje; los cinco títulos de situación
indicando cuáles son planteadas por el original, cuáles derivadas y cuáles inventadas
por esta extensión (y, si inventaste el escenario, cuál elegiste y por qué); el resultado real de
la autorrevisión; y cualquier duda sobre el eje asignado o sobre cifras que no
encontraste. Nada más.
```
