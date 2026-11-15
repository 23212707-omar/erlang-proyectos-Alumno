# #20 — Release y despliegue: gemelo digital con programación lógica

> Extensión del proyecto #20. El problema original está en
> [`../problema/readme.md`](../problema/readme.md) y no cambia. Aquí no hay solución:
> la construyes tú, con apoyo de tu agente (ver [`CONTEXTO_AGENTES.md`](CONTEXTO_AGENTES.md)).

## Del simulador al gemelo

En la parte de Erlang empaquetaste una aplicación, la instalaste en el CM5, la arrancaste
como servicio y practicaste la marcha atrás. Esa simulación responde «¿quedó instalada y
arrancó?». Quien autoriza una liberación a las 2 a. m., en una institución que maneja el
dinero de otras personas, necesita algo más: «¿en qué orden, qué se rompe si falla, hasta
cuándo se puede regresar y quién lo paga?».

El gemelo digital es el **modelo lógico** del programa de liberaciones: hechos que
reflejan qué hay instalado y corriendo, y reglas que reflejan cómo se decide en él. Se
escribe en Prolog porque aquí no se calcula: se deduce qué versión corre de verdad, qué
orden de arranque es válido, qué arrastra una falla y se sabe decir «no lo sé».

## La operación que se clona

La «Caja Popular Cerro Colorado» es una caja de ahorro de Tecate, Baja California. **No
existe: es un escenario planteado por esta extensión**, no por el problema original. Sus
seis servicios son releases de Erlang que corren en un CM5 (aarch64, Debian 13, OTP
27.3.4.19, como en el original); cada situación es una noche distinta sobre el mismo mapa.

| Parte | Contenido |
|---|---|
| Entidades | servicios (autenticación, cuentas, avisos, transferencias, nómina, portal), sus versiones, artefactos, instancias y puertos, la configuración por ambiente (producción y pruebas) |
| Personas | la jefa de infraestructura (autoriza), el desarrollador de turno (construye y ejecuta), la oficial de cumplimiento (vigila que el socio sea avisado), la gerente de sucursales (abren a primera hora) y una empresa afiliada que paga su nómina por la caja |
| Dependencias | un servicio necesita a otros: **dura** (sin ella no arranca) o **blanda** (sin ella funciona degradado). Transferencias depende de cuentas, autenticación y avisos; nómina, de transferencias y cuentas; avisos, de autenticación; el portal depende duro de autenticación y cuentas, y blando de transferencias |
| Estado por servicio | versión instalada, versión que responde, si se está migrando, qué versiones de sus requisitos acepta, de dónde salió su configuración, en qué puerto escucha, conexiones activas |
| Eventos | se descarga, instala, detiene o arranca un servicio; empieza o termina un paso de migración; se corta la luz; un servicio responde su versión; se abre o cierra una conexión |
| Decisiones | ¿en qué orden arranca?, ¿está listo?, ¿se puede regresar?, ¿quién se lleva a quién?, ¿quién ocupa el puerto?, ¿se aprueba este diseño? |
| Reglamento (inventado) | (a) no hay liberación sin autorización vigente ni respaldo de cuentas verificado esa noche; (b) los cambios van en la ventana de la madrugada y todo cambio debe poder deshacerse por completo antes del margen previo a la apertura de sucursales; (c) un servicio arranca solo con sus dependencias duras arriba y en versión compatible; una blanda ausente solo degrada; (d) nada arranca con la configuración de otro ambiente ni con una variable obligatoria faltante; (e) una operación de socio en curso (transferencia, dispersión de nómina) no se corta a la mitad: se termina o no se empieza; (f) un error que cobra de más a los socios se corrige en la primera liberación autorizada y probada; (g) solo se instala en producción un artefacto construido para la plataforma del destino |

## Situaciones que tu gemelo debe razonar

Las cinco las plantea esta extensión. La 1, la 2, la 3 y la 4 retoman casos y datos del
problema original (el corte de luz, la versión 1.1 con migración y su rollback, el puerto
compartido y el apagado con SIGTERM, la variable faltante y las versiones distintas); la 5
es nueva y sale del foco del proyecto (orden de arranque y dependencias). En cada una,
tu gemelo debe llegar a una decisión **y poder explicarla**.

### Situación 1 — Vuelve la luz a medio despliegue

- **Qué pasa.** En plena liberación de la versión 1.1 se corta la luz con la migración de
  cuentas a medias: dos de sus tres pasos terminaron y el tercero empezó. Al volver la
  luz, systemd arranca los seis servicios a la vez y el tablero marca «6 de 6 activos».
  El desarrollador, de memoria, anotó «migración terminada». Si transferencias y nómina
  operan sobre un esquema a medias, se mueve dinero de socios sobre datos inciertos.
- **Qué datos hay.** La bitácora de instalación y de migración con sus instantes, lo que
  responde cada servicio sobre su versión, la hora de la nota y la del corte, qué versión
  acepta cada requisito y qué paso de migración no se documentó como deshacible o no.
- **Qué debe deducir.** Qué versión corre de verdad en cada servicio y con qué certeza;
  en qué estado quedó el esquema de cuentas; qué servicios están «arriba» pero no son
  válidos y por qué cadena (cuentas → transferencias → nómina; cuentas → portal).
- **Qué debe contestar.** Los órdenes de arranque válidos para lo que sí puede subir; los
  bloqueados con la causa de origen y el camino que los une; y por servicio: versión
  cierta, probable o no se sabe.
- **Por qué es lógica.** «Arriba» no es «bien»; la versión se concluye de varias fuentes
  que pueden contradecirse (una nota imposible, un servicio que dice otra cosa que el
  disco), y el esquema a medias no es ni la versión vieja ni la nueva.

### Situación 2 — El punto de no retorno

- **Qué pasa.** Otra noche la liberación 1.1 terminó, pero casi al final de la ventana
  transferencias empieza a rechazar códigos válidos. La jefa pide «regresar a la 1.0,
  que son unos minutos». Pero transferencias 1.0 solo acepta cuentas 1.0, y uno de los
  pasos de la migración de cuentas borró una columna y no se puede deshacer. Los socios
  siguen operando de madrugada por el portal. La ventana, el respaldo y el margen del
  reglamento corren contra el reloj.
- **Qué datos hay.** Los eventos de la liberación, qué versiones acepta cada servicio,
  qué pasos de la migración se deshacen, cuándo se tomó y verificó el respaldo, cuánto
  tarda cada acción y el «ahora».
- **Qué debe deducir.** Qué servicios habría que regresar y en qué orden; si alguna ruta
  de regreso es posible y cuánto tardaría contando el camino más largo entre acciones
  encadenadas; qué movimientos de socios se perderían; hasta qué momento regresar era
  seguro.
- **Qué debe contestar.** Si regresar es posible, y cuál es la ruta o por qué no hay;
  la alternativa de mantener lo nuevo y qué se apaga o se degrada con ella; y a quién le
  cuesta cada opción.
- **Por qué es lógica.** Lo intuitivo («marcha atrás en minutos») es justo lo que el
  reglamento y los datos desmienten: regresar un binario no regresa los datos. Y la
  respuesta cambia con la hora, aunque nada del sistema cambie.

### Situación 3 — Un puerto, dos reclamos y 90 segundos

- **Qué pasa.** Se libera una nueva versión de transferencias que corrige un cobro
  duplicado: cada hora que pasa, algunos socios pagan de más. Para no perder conexiones,
  la instancia nueva arranca mientras la vieja drena tras recibir SIGTERM; systemd espera
  90 s antes del SIGKILL. Pero hay una dispersión de nómina de la empresa afiliada que
  suele durar más que eso, y ambas instancias, además, piden el mismo puerto: producción
  heredó el archivo de pruebas, donde avisos usa ese mismo puerto. Un lado tiene razón por
  la regla (e), el otro por la (f).
- **Qué datos hay.** Las instancias de cada servicio y los puertos que piden, cuándo
  vive cada una, las conexiones activas con su inicio, el plazo de apagado y el cobro
  duplicado como hecho.
- **Qué debe deducir.** En qué instantes dos instancias chocan por un puerto, incluido el
  choque oculto con avisos; qué conexiones sobreviven al apagado y cuáles se cortan; y
  si existe un plan sin choque que respete a la vez las reglas (e) y (f).
- **Qué debe contestar.** Un plan completo (puerto de cada instancia, cuándo arranca la
  nueva, cuándo se detiene la vieja) o, si no existe, qué regla cede, a quién se le falla
  y qué le cuesta; y todas las asignaciones de puertos válidas.
- **Por qué es lógica.** Dos partes tienen razón; la prioridad entre reglas se declara
  una vez y el choque de puertos es un problema de asignación que se resuelve sin probar
  a ciegas en producción.

### Situación 4 — ¿Está listo para arrancar en producción?

- **Qué pasa.** El desarrollador construyó nómina en su Mac y todo compiló y pasó las
  pruebas con la misma versión de OTP que el destino. Avisos viene del servidor de
  integración con una dependencia nativa; transferencias trae sus variables completas
  pero copiadas del archivo de pruebas; autenticación no tiene una variable obligatoria
  (el caso del original), y la bóveda de secretos de cuentas no respondió. Arrancar
  transferencias así movería dinero real contra la base de pruebas.
- **Qué datos hay.** Para cada artefacto: dónde se construyó, para qué plataforma,
  si incluye el runtime y qué OTP; el destino; las variables que cada servicio requiere y
  de qué ambiente salió cada valor, o que falta, o que no se pudo consultar.
- **Qué debe deducir.** Si el artefacto corre en el destino; si la configuración es
  la del ambiente correcto y está completa; y qué servicios no pueden salir por culpa de
  otro (autenticación faltante → avisos → transferencias).
- **Qué debe contestar.** Por servicio: listo, no listo o no se sabe, y qué falta; y el
  caso que el tablero llamaría «listo» pero no lo es.
- **Por qué es lógica.** «Compiló», «coincide la versión» y «la variable existe» son lo
  intuitivo y no bastan; y «falta» no es lo mismo que «no pude comprobarlo».

### Situación 5 — El aviso que espera al aviso

- **Qué pasa.** La oficial de cumplimiento exige que cada transferencia genere un
  comprobante por avisos, así que se propone que avisos dependa duro de transferencias.
  Pero transferencias ya dependía duro de avisos (el código de confirmación). Con un
  corte total, la caja no podría arrancar sola y la quincena de la empresa afiliada
  quedaría sin pagar.
- **Qué datos hay.** Todas las dependencias, con su tipo, antes y después del cambio
  propuesto, y la criticidad de cada servicio.
- **Qué debe deducir.** Si el diseño nuevo tiene ciclo y cuál; qué servicios se llevaría
  una caída de cada uno, siguiendo el camino y distinguiendo parar de degradar; y bajo
  qué cambios mínimos de tipo de dependencia el diseño volvería a tener orden de arranque.
- **Qué debe contestar.** Aprobado o rechazado, nombrando el ciclo en lugar de fallar en
  silencio; si se aprueba, todos los órdenes de arranque; y la respuesta a «¿qué pasaría
  si autenticación cae?» y a «¿si cae avisos?».
- **Por qué es lógica.** Un orden de arranque no se calcula: se razona sobre una red, y
  que no exista también es una respuesta que se explica.

## Por qué no basta un script

Con `if version_instalada == "1.1": arrancar()` resuelves un servicio con una sola fuente
de verdad y sin dependencias. Tu gemelo debe contestar, **con las mismas reglas**:

| Pregunta | Tipo de consulta |
|---|---|
| ¿Puede arrancar ya la nómina? | decisión |
| ¿Por qué no puede regresarse a la 1.0 ahora? | explicación |
| ¿En qué órdenes puede arrancar todo? | todas las respuestas |
| ¿Hasta qué hora era seguro regresar? | la pregunta al revés |
| ¿Qué pasaría si autenticación cae a mitad del día de pago? | hipótesis |

En un script, cada pregunta es una función nueva. En un modelo lógico son cinco
consultas sobre lo mismo. Prolog aquí no es un accesorio de otra herramienta: es el
programa.

## Preguntas guía

1. ¿Qué hechos necesitas para describir qué corre en el CM5 en un instante?
2. Si «la versión» no es un hecho único, ¿de qué fuentes se deduce y cuál pesa más?
3. Cuando «no cortar a un socio» choca con «dejar de cobrarle de más», ¿dónde queda
   escrito cuál gana?
4. ¿Cómo distingue tu gemelo «falta la variable» de «no pude comprobarla»?
5. En Erlang viste `rebar3 release`, systemd y el rollback. ¿Qué de eso alimentaría a
   este gemelo, y qué decide el gemelo que un script de despliegue no puede?

## Qué entregas

- El gemelo en SWI-Prolog: hechos de la operación, reglas y su servidor web.
- Pruebas plunit: al menos una por situación.
- La interfaz, diseñada en Google Stitch. Solo pregunta al gemelo y muestra la decisión
  con su explicación; ninguna regla vive en la interfaz.
- Tus supuestos y las cifras de este documento que verificaste.
- Un párrafo: qué resolviste en Erlang, qué en Prolog, y por qué cada cosa en su lugar.
- Opcional: llamar a Python **desde** Prolog (Janus) para generar bitácoras simuladas o
  graficar la red de dependencias.

## Supuestos de esta extensión

- Inventado por esta extensión, no por el original: la caja, sus seis servicios y
  dependencias, las personas, la empresa afiliada, el cobro duplicado, la migración de
  tres pasos, las versiones compatibles y el reglamento (a)-(g). Son datos del ejercicio,
  no hechos del mundo.
- Números del ejercicio: ventana de cambios de 2:00 a 5:00 a. m.; las sucursales abren
  a las 7:00 y todo debe poder deshacerse antes de las 6:00; reiniciar un servicio, 2
  minutos; migrar cuentas, 40; restaurar el respaldo, 75; tomar el respaldo, 10. Los
  nombres e instantes de los ejemplos son solo ilustrativos.
- El original no fija escala: pide un release de una app en un CM5. Aquí son seis
  servicios y a lo sumo dos instancias de uno.
- El «ahora» es un hecho del modelo, no el reloj del sistema, para que las respuestas
  se puedan repetir. Los cortes de luz y las fallas entran como hechos, no se sortean.
- Tú defines y declaras como supuesto: cuánta certeza da cada fuente de versión y cuál
  gana si se contradicen; qué regla gana en cada choque; cuántas conexiones activas
  hacen inaceptable un apagado; qué hacer cuando la bóveda no responde; y cuál es el
  cambio mínimo de dependencias para romper un ciclo.

## Extensiones posibles

Para quien quiera ir más lejos. Estas situaciones no vienen del problema original:
investiga y cita tus fuentes antes de fijar cifras.

- Liberaciones azul-verde o por etapas, con un servicio a la vez.
- Dos equipos que piden la misma ventana para liberaciones que se estorban.
- Una actualización en caliente (`relup`) frente al reemplazo con reinicio.
- Un proveedor externo (el banco que liquida) que cambia su interfaz sin avisar.

---
*Las cifras del original (OTP 27.3.4.19, aarch64, Debian 13, SIGTERM y 90 s de espera
antes de SIGKILL, las versiones 1.0 y 1.1, las 2 a. m.) vienen de él; verifica la fuente
vigente antes de citarlas. El escenario, sus tiempos y su reglamento son inventados.*
