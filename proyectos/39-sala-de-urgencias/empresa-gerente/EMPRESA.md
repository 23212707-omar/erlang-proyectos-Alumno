# Hospital El Milagro Niño Jesús — Ficha de la empresa (FICTICIA)

> Toda esta empresa, sus nombres, RFC, domicilios, personas y cifras son **inventados** para
> el ejercicio académico. Cualquier parecido con un hospital real es coincidencia. El sistema
> que se diseña es una **simulación educativa de gestión de colas, no un dispositivo médico**.
> Las cifras del negocio son órdenes de magnitud plausibles, no datos verificados.

## 1. Datos fiscales y legales

| Campo | Valor |
|---|---|
| Razón social | Servicios Hospitalarios El Milagro, S.A. de C.V. |
| Nombre comercial | Hospital El Milagro Niño Jesús |
| RFC (ficticio) | SHM080722QA5 |
| Régimen fiscal | 601 — General de Ley Personas Morales |
| Constitución | 22 de julio de 2008, Tijuana, B.C. (escritura 31,205, notaría ficticia núm. 12) |
| Domicilio fiscal | Calle Niño Jesús 1450, Col. Zona Urbana Río, Tijuana, Baja California, C.P. 22010 (dirección ficticia; verificar C.P.) |
| Uso de CFDI habitual | D01 — Honorarios médicos, dentales y gastos hospitalarios (pacientes); G03 para proveedores |
| Objeto social | Prestación de servicios de atención médica hospitalaria, urgencias, hospitalización y cirugía |
| Capital social | $60,000,000 MXN |
| Camas | 60 camas censables (verificar definición) y 12 espacios de atención en urgencias |
| Licencia sanitaria | Licencia ficticia COFEPRIS-BC-0000 como establecimiento de atención médica con servicio de urgencias |

### Socios y representación

| Persona | Rol | Participación |
|---|---|---|
| Lic. Sofía Sandoval Ruiz | Presidenta del consejo y representante legal | 40 % |
| Dr. Ramón Sandoval Ruiz | Director médico y socio fundador | 25 % |
| Fondo de inversión ficticio "Vida Frontera" | Socio inversionista | 25 % |
| Dr. Aldo Díaz | Jefe médico de urgencias (socio minoritario) | 10 % |

### Obligaciones y trámites reales del giro

- **COFEPRIS / Secretaría de Salud:** licencia sanitaria, aviso de responsable sanitario y de
  funcionamiento del establecimiento (verificar los que aplican).
- **Normas de atención:** servicios de urgencias (NOM-027-SSA3), expediente clínico
  (NOM-004-SSA3) y otras NOM aplicables; verificar cuáles y su vigencia.
- **Datos personales:** el expediente es información sensible; aplica la normativa de
  protección de datos personales en posesión de particulares (verificar) y aviso de privacidad.
- **SAT:** CFDI 4.0, IVA (los servicios médicos tienen tratamiento específico; verificar),
  contabilidad electrónica y declaración anual.
- **IMSS e INFONAVIT** para el personal; cédulas profesionales vigentes del personal médico.
- **Aseguradoras y convenios:** el hospital factura a aseguradoras de gastos médicos y a
  empresas con convenio; manejo de preautorizaciones.
- **Protección civil** y plan hospitalario para eventos con múltiples víctimas.
- **Residuos peligrosos biológico-infecciosos (RPBI):** manejo conforme a la norma
  correspondiente (verificar).

## 2. Contexto real del lugar y del sector

- Tijuana es una de las ciudades más pobladas de la frontera norte, con mucha movilidad y
  población flotante; hay lesiones de tránsito, accidentes laborales y alta demanda por la
  cercanía de la frontera.
- Conviven hospitales públicos (IMSS, ISSSTE, Secretaría de Salud estatal), privados y
  asistenciales. Muchos pacientes llegan a urgencias de un hospital privado por rapidez o
  porque el público está saturado.
- En urgencias se usan escalas de triage como **ESI** (5 niveles, 1 = reanimación inmediata,
  5 = no urgente) y **Manchester** (rojo inmediato, naranja ≤10 min, amarillo ≤60 min,
  verde ≤120 min, azul ≤240 min). En México es común simplificar a **rojo, amarillo y verde**.
- La saturación se agrava cuando pacientes ya atendidos esperan cama y bloquean espacio.
- Picos reales: noches de viernes y sábado, días festivos, vacaciones, eventos masivos y
  accidentes carreteros.
- Competencia: otros hospitales privados de la ciudad y, en la frontera, servicios médicos
  del lado de Estados Unidos para algunos pacientes con seguro.

## 3. Historia en breve

El hospital nació en 2008 cuando la familia Sandoval Ruiz convirtió una clínica de barrio en
hospital, y le puso "El Milagro Niño Jesús" porque la hija menor de la familia sobrevivió a
una complicación de recién nacida y la abuela había hecho una promesa al Niño Jesús. La
imagen sigue en la entrada de urgencias.

El Dr. Aldo Díaz, médico urgenciólogo con 18 años de guardias, llegó hace seis años como jefe
de urgencias y hoy es socio minoritario.

El año que cambió su forma de pensar: **una noche de viernes con un choque múltiple** en la
vía rápida. Llegaron 8 lesionados casi juntos mientras la sala estaba llena. Nadie murió por
la sala, pero una paciente con dolor abdominal que parecía "verde" esperó cuatro horas, se
descompensó y casi se pierde. Desde entonces el Dr. Díaz no quiere que el orden de atención
dependa de la memoria de la enfermera de turno ni del pizarrón.

## 4. Operación

### Recursos de urgencias (escenario del proyecto)

| Recurso | Cantidad |
|---|---|
| Médicos de guardia simultáneos | 5 |
| Camillas / espacios de atención | 12 |
| Enfermería de triage | 2 por turno |
| Rayos X, laboratorio, quirófano compartido | recursos finitos que se piden y a veces se esperan |

### Flujo actual (el que se quiere reemplazar)

- La persona llega, se registra en admisión y una enfermera de triage le asigna **rojo,
  amarillo o verde**.
- La cola es un pizarrón y la memoria del personal. Cuando hay un accidente, se improvisa.
- El triage se repite "cuando alguien se acuerda"; no hay aviso automático.
- No hay medición confiable de cuánto se tarda en pasar a consulta ni por nivel.
- Cuando el paciente es atendido, a veces espera cama de hospitalización y ocupa una camilla
  de urgencias.

### Escala del escenario

- Unas **100 llegadas en 12 horas**, mezcla de los 5 niveles (ESI) con predominio de verde y
  amarillo.
- Eventos extraordinarios: **accidente con 8 heridos** que llegan al mismo tiempo.
- Pacientes que **empeoran** mientras esperan; por ejemplo un verde que pasa a rojo tras 90
  minutos.

### Personal

| Puesto | Personas | Nota |
|---|---|---|
| Director médico | 1 | Dr. Ramón Sandoval |
| Jefe médico de urgencias | 1 | Dr. Aldo Díaz |
| Médicos de guardia | 5 por turno | adscritos y residentes |
| Enfermería | 2 en triage + 6 en sala | |
| Admisión / trabajo social | 2 por turno | |
| Soporte de TI | 1 | Un técnico que atiende todo el hospital |

## 5. Números del negocio (ficticios)

| Concepto | Cifra aproximada |
|---|---|
| Atenciones de urgencias al año | ~70,000 |
| Distribución típica | 5 % críticos, 20 % amarillos o urgentes, 75 % verdes o no urgentes |
| Tiempo puerta-a-médico objetivo (rojo) | inmediato |
| Tiempo puerta-a-médico objetivo (amarillo) | ≤60 min |
| Tiempo puerta-a-médico objetivo (verde) | ≤120 min |
| Ingresos por urgencias | ~$85 millones MXN al año (particulares, aseguradoras y convenios) |
| Costo por turno de 12 h en urgencias | ~$45,000 MXN en personal e insumos |
| Presupuesto aprobado para este proyecto | $250,000 MXN, y quiere verlo operando antes de las vacaciones de verano |

## 6. Calendario del año / ciclo de operación

| Periodo | Qué pasa |
|---|---|
| Lunes a jueves | Demanda moderada, pico por la tarde |
| Viernes y sábado de noche | **Pico:** accidentes, riñas, intoxicaciones |
| Semana Santa y vacaciones de verano | Más lesiones por turismo y carretera |
| Fin de año | Picos por festejos |
| Invierno | Más cuadros respiratorios |

## 7. Lo que le duele al negocio

1. **Inanición:** el paciente de bajo nivel que nunca pasa porque siempre llega alguien más
   grave.
2. **Gravedad contra tiempo de espera:** ¿cuánto vale esperar tres horas frente a un caso
   algo más grave que llegó ahora?
3. **Reclasificación:** un paciente que empeora en la sala de espera sin que nadie lo note.
4. **Desbordamiento:** no hay camillas libres, y hay pacientes ya atendidos esperando cama.
5. **Accidente múltiple:** 8 heridos al mismo tiempo; que no se pierda ni se duplique ninguno.
6. **Pérdida de información:** si falla el sistema a mitad de turno, el jefe no puede perder
   ni a un solo paciente en espera.
7. **No saber qué medir:** saber que "ya se saturó" demasiado tarde.
8. **Reputación y quejas:** un paciente que se siente ignorado se queja con la dirección, con
   la aseguradora y en redes.

## 8. Qué NO es de este negocio

- No es un dispositivo médico ni sustituye al juicio clínico: el sistema ordena colas, no
  diagnostica.
- No quiere integrarse todavía con el sistema de expediente clínico ni con facturación; solo
  gestionar la cola de urgencias.
- No quiere una nube externa con datos de pacientes; busca algo que corra en una máquina local
  del hospital y que el personal pueda entender.
