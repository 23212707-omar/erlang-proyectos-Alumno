# Catalogo de proyectos Erlang/OTP

81 temas para 40 estudiantes: **12 trios + 2 binas = 14 equipos**. Cada equipo elige un
numero distinto (primero en llegar se queda). Toda UI se disena en Google Stitch.

## Roles del trio

- **Backend**: OTP, arbol de supervision, logica del dominio.
- **Frontend**: Stitch, `design/`, integracion con cowboy.
- **Ops/QA**: release, systemd, recon, eunit/ct, pruebas de caos.

Los roles rotan a mitad del curso. Las binas toman temas de nivel inicial.

## Niveles sugeridos

| Nivel | Perfil | Ejemplos |
|---|---|---|
| Inicial | Sensores simples, CRUD basico | 5, 13, 14, 52, 54, 58 |
| Intermedio | Maquinas de estado, paneles, DB | 1, 2, 6, 10, 12, 34, 43, 59 |
| Avanzado | Tiempo real, distribucion, alta concurrencia | 15, 16, 18, 21, 22, 39, 64, 67 |

---

## Agro e IoT

1. **Viñedos**: un proceso por sensor (humedad de suelo, temperatura, hoja mojada) por hilera; `gen_statem` para riego; alertas de helada y mildiu; supervisor por parcela.
2. **Invernadero**: ventilacion, humedad y CO2 con `gen_statem` y lazo de control; modo seguro si falla un sensor.
3. **Riego por zonas**: programador de valvulas con colas y prioridades; recupera estado tras un corte de luz.
4. **Apiario o ganado**: telemetria de colmenas o collares; muchos dispositivos y deteccion de "dejo de reportar".
5. **Estacion meteorologica**: ingesta de datos, promedios en ETS y `/metrics` con prometheus.

## Ciudad y edificios

6. **Estacionamiento inteligente**: cada cajon es un proceso; reservas y disponibilidad en tiempo real, caso Aeropuerto de TJ (Foco disponibilidad).
7. **Control de acceso**: gen_server por puerta, bitacora de eventos, revocacion de credenciales.
8. **Monitor de energia**: medidores con consumo, alarmas por umbral y agregacion por piso.
9. **Semaforos o cruceros**: maquinas de estado coordinadas con `rest_for_one`.

## Servicios web y datos

10. **API REST con cowboy y PostgreSQL**: CRUD con epgsql y poolboy, pruebas de carga.
11. **Chat o notificaciones**: WebSockets de cowboy, un proceso por sala.
12. **Cola de trabajos**: workers con reintentos y backoff, con supervision.
13. **Rate limiter / cache**: ETS con `read_concurrency` y expiracion de entradas.
14. **Acortador de URLs**: caso basico para empezar con cowboy y ETS.

## Sistemas distribuidos

15. **Cluster de 2-3 nodos**: replicacion de estado, `net_kernel` y failover.
16. **Broker MQTT simple**: pub/sub con un proceso por conexion.
17. **Servidor de juego** (tres en raya, trivia, ajedrez): un proceso por partida y matchmaking.
18. **Subasta o reservas**: concurrencia sin condiciones de carrera.

## Operacion y calidad

19. **Observabilidad**: recon, metricas Prometheus y `logger` con metadata.
20. **Release y despliegue**: `rebar3 release`, servicio systemd y `remote_console`.
21. **Pruebas de caos**: matar procesos a proposito y verificar que el arbol de supervision se recupera.

## Aviacion y transporte

22. **Torre de control TIJ**: dashboard de vuelos del Aeropuerto de Tijuana con estados (programado, abordando, despego, demorado); un proceso por vuelo y `gen_statem` por ciclo de vida.
23. **Puertas de abordar**: asignacion dinamica de puertas con conflictos y reasignacion.
24. **Cruce CBX / puente peatonal**: colas, tiempos de espera y capacidad por hora.
25. **Garitas San Ysidro y Otay**: tiempos de espera por carril y prediccion simple con promedios moviles.
26. **Central camionera / rutas urbanas**: seguimiento de unidades y llegada estimada.
27. **Taxis o rides**: matchmaking de conductores y pasajeros.
28. **Puerto de Ensenada**: gruas, contenedores y turnos de atraque.
29. **Flotilla de reparto**: rastreo GPS simulado y reasignacion de entregas.
30. **Bicicletas o scooters compartidos**: disponibilidad de estaciones y rebalanceo.
31. **Control de pista y rampa**: secuenciacion de despegues y aterrizajes con prioridades.

## Industria y manufactura

32. **Linea de produccion**: estaciones como procesos, cuellos de botella y paros.
33. **OEE de maquinas**: disponibilidad, rendimiento y calidad en tiempo real.
34. **Almacen / inventario**: entradas, salidas, alertas de minimos y trazabilidad.
35. **Control de calidad**: lotes, defectos y semaforo de rechazo.
36. **Mantenimiento predictivo**: vibracion y temperatura simuladas con alertas de falla.
37. **Cadena de frio**: monitoreo de temperatura en transporte y bodega.
38. **Andon digital**: boton de llamada de ayuda y escalamiento por tiempo.

## Salud

39. **Sala de urgencias**: triage, cola por prioridad y tiempos de atencion.
40. **Camas de hospital**: ocupacion, altas y limpieza.
41. **Signos vitales**: monitor de pacientes con alarmas.
42. **Farmacia**: inventario, caducidades y recetas.
43. **Citas medicas**: agenda sin traslapes y recordatorios.
44. **Banco de sangre**: tipos, caducidad y emergencias.

## Educacion y campus

45. **Control de laboratorios**: reservas de salas y equipos del TecNM Tijuana.
46. **Asistencia por QR**: pase de lista en tiempo real.
47. **Cafeteria**: pedidos, cola y tiempo estimado.
48. **Biblioteca**: prestamos, multas y reservas.
49. **Estacionamiento del campus**: variante del 6, con cajones por edificio.
50. **Examen en linea**: temporizador por alumno, tolerante a reconexion.
51. **Tablero de avisos**: notificaciones por carrera y grupo.

## Energia y medio ambiente

52. **Calidad del aire**: red de sensores con alerta por contaminacion (pm2.5).
53. **Paneles solares**: produccion contra consumo y recomendaciones de uso.
54. **Gestion de agua**: fugas, presion y consumo por colonia.
55. **Residuos**: contenedores con nivel de llenado y ruta de recoleccion.
56. **Sismos**: ingesta de eventos y alertas por magnitud.
57. **Incendios forestales**: sensores de temperatura y humo en canones.
58. **Playa y oleaje**: bandera de seguridad segun condiciones.

## Comercio, finanzas y servicios

59. **Punto de venta**: ventas concurrentes, corte de caja y tickets.
60. **Restaurante**: comandas, cocina, mesas y tiempos.
61. **Cotizador de divisas**: peso/dolar con historico y alertas.
62. **Billetera virtual**: transferencias seguras, sin doble gasto.
63. **Reservas de hotel**: disponibilidad por fecha sin sobreventa.
64. **Taquilla de eventos**: venta de boletos con concurrencia alta.
65. **Subasta de ganado o productos**: puja en tiempo real.
66. **Mercado de abastos / tianguis**: pedidos de comerciantes y repartidores.

## Seguridad y ciudad

67. **Centro de emergencias 911**: despacho de unidades por prioridad y cercania.
68. **Alarmas de domicilio**: eventos, falsos positivos y escalamiento.
69. **Camaras y accesos**: bitacora de eventos y busqueda por rango de tiempo.
70. **Alumbrado publico**: lamparas con fallas reportadas y mapa de reparacion.
71. **Proteccion civil**: seguimiento de albergues e inventario durante un evento.

## Entretenimiento y juegos

72. **Torneo de esports**: brackets, partidas y marcadores en vivo.
73. **Quiniela del Mundial**: predicciones, puntos y ranking en vivo.
74. **Radio o streaming**: lista de reproduccion colaborativa con votos.
75. **Carreras simuladas**: pilotos como procesos con eventos y apuestas ficticias.
76. **Mesa de domino o loteria en linea**: salas multijugador.

## Agro y alimentos

77. **Valle de Guadalupe, bodega**: fermentacion por tanque, temperatura y fases.
78. **Cultivo de fresa o tomate (San Quintin)**: cosecha, cuadrillas y trazabilidad.
79. **Acuacultura (atun, ostion)**: oxigeno, temperatura y alimentacion de jaulas.
80. **Cerveceria artesanal**: lotes, fermentadores y etapas de produccion.
81. **Gestion de ganado**: salud, pesaje y rutas de pastoreo.

---

## Asignacion de equipos

| Equipo | Integrantes | Proyecto (#) |
|---|---|---|
| 1 | | |
| 2 | | |
| 3 | | |
| 4 | | |
| 5 | | |
| 6 | | |
| 7 | | |
| 8 | | |
| 9 | | |
| 10 | | |
| 11 | | |
| 12 | | |
| 13 (bina) | | |
| 14 (bina) | | |
