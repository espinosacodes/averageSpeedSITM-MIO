# 🎴 FLASHCARDS - Arquitectura SITM-MIO

## Instrucciones
Lee la pregunta, intenta responder mentalmente, luego revela la respuesta.

---

## CATEGORÍA: CONCEPTOS GENERALES

### Tarjeta 1
**P**: ¿Qué es el SITM-MIO?
**R**: Sistema Integrado de Transporte Masivo de Occidente, operado por el CCO de Metrocali en Cali, Colombia. Transporta ~450,000 pasajeros/día con ~1000 buses.

---

### Tarjeta 2
**P**: ¿Cuántos eventos por día genera el sistema?
**R**: Entre 2.5 millones y 3 millones de eventos por día.

---

### Tarjeta 3
**P**: ¿Con qué frecuencia los buses envían datagramas?
**R**: Cada 30 segundos vía GPRS.

---

### Tarjeta 4
**P**: ¿Cuántos sensores tiene cada bus?
**R**: Aproximadamente 40 sensores conectados a un computador embebido.

---

### Tarjeta 5
**P**: ¿Cuál es el objetivo principal del sistema?
**R**: Estimar el tiempo promedio de viaje entre dos puntos de la ciudad usando datos históricos y en tiempo real de las posiciones GPS de los buses.

---

## CATEGORÍA: ARQUITECTURA

### Tarjeta 6
**P**: ¿Cuántos nodos tiene la arquitectura distribuida?
**R**: 5 nodos: Bus, Central, Monitoreo, Consultas y Base de Datos.

---

### Tarjeta 7
**P**: ¿Cuál es el nodo más importante y por qué?
**R**: El Nodo Central, porque contiene el ProcesadorCentral que coordina todos los flujos del sistema y actúa como mediador entre componentes.

---

### Tarjeta 8
**P**: ¿Por qué se eligió una arquitectura distribuida?
**R**: Por escalabilidad (1000→2500 buses), separación de preocupaciones, tolerancia a fallos, y mejor rendimiento para procesar millones de eventos.

---

### Tarjeta 9
**P**: ¿Qué tipo de comunicación usa el bus para enviar datos?
**R**: Comunicación GPRS (inalámbrica celular).

---

### Tarjeta 10
**P**: ¿La base de datos es distribuida o centralizada?
**R**: Centralizada, en un nodo dedicado, para mantener consistencia y facilitar análisis históricos completos.

---

## CATEGORÍA: COMPONENTES DEL NODO CENTRAL

### Tarjeta 11
**P**: ¿Cuáles son los 6 gestores principales del nodo central?
**R**: 
1. GestorRecepcionDatos
2. GestorAnalisisEstimaciones
3. GestorSincronizacionActualizacion
4. GestorUsuariosSeguridad
5. GestorZonasRutas
6. ComunicacionExterna

---

### Tarjeta 12
**P**: ¿Qué hace el ProcesadorCentral?
**R**: Coordina todos los flujos del nodo central, delega tareas a gestores especializados, y actúa como mediador (Patrón Mediator).

---

### Tarjeta 13
**P**: ¿Qué hace el GestorRecepcionDatos?
**R**: Recibe los datagramas de los buses (punto de entrada), implementa buffer/cola para manejar alto volumen, y envía datos al ProcesadorCentral.

---

### Tarjeta 14
**P**: ¿Qué hace el GestorAnalisisEstimaciones?
**R**: Calcula velocidades promedio por arco, estima tiempos de viaje, combina datos históricos con tiempo real.

---

### Tarjeta 15
**P**: ¿Qué hace el GestorSincronizacionActualizacion?
**R**: Actualiza datos en tiempo real en la BD y notifica al nodo de monitoreo con los datos actualizados.

---

### Tarjeta 16
**P**: ¿Qué hace el GestorUsuariosSeguridad?
**R**: Administra usuarios, roles y permisos. Verifica autenticación y autorización antes de delegar operaciones.

---

### Tarjeta 17
**P**: ¿Qué hace el GestorZonasRutas?
**R**: Gestiona la asignación de rutas y zonas a los controladores de operación.

---

## CATEGORÍA: OTROS NODOS

### Tarjeta 18
**P**: ¿Qué componentes tiene el Nodo Bus?
**R**: GestorEventos (captura y envía eventos), UIBus (interfaz con perilla para conductor), ServicioGestorEventos (comunicación GPRS).

---

### Tarjeta 19
**P**: ¿Por qué el bus tiene una perilla en lugar de touchscreen?
**R**: Por seguridad vial (Req. 2): evita que el conductor desvíe la vista de la carretera para registrar eventos.

---

### Tarjeta 20
**P**: ¿Qué hace el Nodo de Monitoreo?
**R**: Permite a los 40 controladores visualizar en tiempo real sus zonas asignadas con velocidades promedio por arco y posiciones de buses.

---

### Tarjeta 21
**P**: ¿Qué hace el Nodo de Consultas?
**R**: Provee API pública para que ciudadanos, empresas y entidades públicas consulten información del sistema de transporte y estimaciones de tiempo.

---

### Tarjeta 22
**P**: ¿Qué almacena el Nodo de Base de Datos?
**R**: Usuarios, roles, permisos, eventos históricos, datos GPS, zonas, rutas, arcos, métricas calculadas y asignaciones de controladores.

---

## CATEGORÍA: PATRONES DE DISEÑO

### Tarjeta 23
**P**: ¿Qué patrón de diseño implementa el ProcesadorCentral?
**R**: Patrón Mediator - coordina las interacciones entre gestores sin que se conozcan directamente.

---

### Tarjeta 24
**P**: ¿Qué patrón implementa el GestorSincronizacionActualizacion?
**R**: Patrón Observer/Pub-Sub - notifica cambios al nodo de monitoreo cuando hay actualizaciones.

---

### Tarjeta 25
**P**: ¿Qué patrón implementa el GestorBD?
**R**: Patrón Repository - abstrae el acceso a datos y centraliza operaciones de persistencia.

---

### Tarjeta 26
**P**: ¿Qué arquitectura en capas se usa en cada nodo?
**R**: 
- Capa de Presentación (UIs)
- Capa de Lógica de Negocio (Gestores)
- Capa de Servicios (Comunicación)
- Capa de Datos (GestorBD)

---

## CATEGORÍA: FLUJOS DE DATOS

### Tarjeta 27
**P**: Describe el flujo de un datagrama desde el bus hasta el monitoreo.
**R**: 
Bus → GestorEventos → GPRS → GestorRecepcionDatos → ProcesadorCentral → GestorBD (persistir) → GestorSincronizacionActualizacion → GestorMonitoreo → UIMonitoreo

---

### Tarjeta 28
**P**: ¿Cómo fluye una consulta de velocidad de zona?
**R**: 
Controlador → UIMonitoreo → GestorMonitoreo → ProcesadorCentral → GestorAnalisisEstimaciones → GestorBD (consultar históricos) → Calcular → Retornar → UIMonitoreo

---

### Tarjeta 29
**P**: ¿Cómo fluye una consulta pública?
**R**: 
Ciudadano → UIConsultas → GestorConsultas → ProcesadorCentral → GestorAnalisisEstimaciones → GestorBD → Retornar estimación → UIConsultas

---

## CATEGORÍA: CASOS DE USO

### Tarjeta 30
**P**: ¿Cuáles son los 2 casos de uso principales?
**R**: 
1. Visualizar el análisis de movilidad por zona (Req. 9)
2. Consultar información del análisis generado (Req. 13)

---

### Tarjeta 31
**P**: Actor principal del CU "Visualizar análisis de movilidad por zona"
**R**: Controlador de operación.

---

### Tarjeta 32
**P**: Pasos principales del CU "Visualizar análisis de movilidad por zona"
**R**: 
1. Seleccionar "visualizar zonas"
2. Sistema verifica permisos
3. Mostrar zonas asignadas
4. Seleccionar zona específica
5. Sistema calcula velocidad promedio
6. Mostrar mapa + velocidades + alertas

---

### Tarjeta 33
**P**: Actor del CU "Consultar estado del sistema"
**R**: Ciudadano, empresa o entidad pública.

---

### Tarjeta 34
**P**: ¿Qué muestra el sistema al ciudadano en el CU de consulta?
**R**: Estado general del sistema, rutas disponibles y estimaciones de tiempo de viaje.

---

### Tarjeta 35
**P**: ¿Cuáles son los sub-casos de uso del CU de visualización?
**R**: 
- Obtener velocidad promedio por arco
- Calcular estimación de ruta
- Registrar evento

---

## CATEGORÍA: TARJETAS CRC

### Tarjeta 36
**P**: CRC - Responsabilidades del ProcesadorCentral
**R**: 
- Coordinar todos los flujos del nodo
- Delegar análisis, verificaciones, sincronización
- Gestionar consultas externas

---

### Tarjeta 37
**P**: CRC - Colaboradores del ProcesadorCentral
**R**: TODOS los gestores del nodo central (Recepcion, Analisis, Sincronizacion, Usuarios, Zonas, ComunicacionExterna).

---

### Tarjeta 38
**P**: CRC - Responsabilidades del GestorEventos (Bus)
**R**: 
- Detectar eventos generados por el bus
- Asignar categoría y prioridad
- Enviar datos al nodo central

---

### Tarjeta 39
**P**: CRC - Colaboradores del GestorEventos (Bus)
**R**: UIBus (para recibir selección), GestorRecepcionDatos del nodo central (para enviar datagramas).

---

### Tarjeta 40
**P**: CRC - Responsabilidades del GestorBD
**R**: 
- Proveer servicios de almacenamiento y recuperación
- Gestionar consultas de usuarios, eventos, análisis y métricas

---

## CATEGORÍA: DECISIONES DE DISEÑO

### Tarjeta 41
**P**: Ventajas de usar ProcesadorCentral como mediador
**R**: 
- Evita acoplamiento NxN entre componentes
- Facilita agregar nuevos gestores
- Punto único para logging y debugging
- Implementa lógica de orquestación compleja

---

### Tarjeta 42
**P**: ¿Por qué base de datos centralizada en lugar de distribuida?
**R**: 
- Consistencia de datos
- Facilita análisis con datos históricos completos
- Simplifica transacciones
(Nota: futuro podría usar sharding por zona)

---

### Tarjeta 43
**P**: ¿Qué tipo de procesamiento usa el sistema?
**R**: HÍBRIDO:
- Tiempo real: eventos críticos, posiciones
- Análisis periódico: velocidades promedio con históricos
- Incremental: nuevos datos ajustan métricas

---

### Tarjeta 44
**P**: ¿Cómo escala el sistema de 1000 a 2500 buses?
**R**: 
- Múltiples instancias del nodo central con balanceador
- Sharding de BD por zona
- Clúster de mensajería (Kafka/RabbitMQ)
- Réplicas de lectura

---

## CATEGORÍA: REQUERIMIENTOS

### Tarjeta 45
**P**: Req. 1 - ¿Qué debe hacer el sistema con eventos?
**R**: Los buses generan eventos automáticos y manuales que deben tener categoría y prioridad. Conductor puede enviar eventos vía GUI.

---

### Tarjeta 46
**P**: Req. 2 - ¿Por qué usar perilla?
**R**: Para evitar accidentes: permite seleccionar eventos sin desviar la vista de la carretera.

---

### Tarjeta 47
**P**: Req. 3 - ¿Qué debe administrar el sistema?
**R**: Roles, usuarios y permisos.

---

### Tarjeta 48
**P**: Req. 4 - ¿Qué visualización debe tener?
**R**: Mapa en tiempo real con posiciones de todos los buses del SITM-MIO.

---

### Tarjeta 49
**P**: Req. 6 - ¿Qué debe procesar y persistir el sistema?
**R**: Grandes volúmenes de datos: posiciones GPS, eventos operativos, reportes de controladores. Todo persistido en BD.

---

### Tarjeta 50
**P**: Req. 7 - ¿Qué análisis debe realizar?
**R**: Estimar variables de movilidad como tiempos promedio de viaje por arco, actualizándose en tiempo real.

---

### Tarjeta 51
**P**: Req. 8 - ¿Qué asignaciones debe permitir?
**R**: Asignar rutas y zonas de la ciudad a controladores de operación.

---

### Tarjeta 52
**P**: Req. 9 - ¿Qué debe visualizar cada controlador?
**R**: Sus zonas asignadas en tiempo real con la velocidad promedio por arco de cada zona.

---

### Tarjeta 53
**P**: Req. 11 - ¿Cómo debe adaptarse el sistema?
**R**: Mantener análisis actualizado adaptándose al crecimiento en volumen de datos y número de fuentes sin afectar disponibilidad.

---

### Tarjeta 54
**P**: Req. 12 - ¿Qué tipo de escalabilidad necesita?
**R**: Escalabilidad en el procesamiento de eventos generados por buses que se ponen a funcionar diariamente.

---

### Tarjeta 55
**P**: Req. 13 - ¿Qué servicios debe ofrecer?
**R**: Servicios para que ciudadanos, empresas o entidades públicas consulten información útil sobre el sistema y estimaciones de tiempo.

---

## CATEGORÍA: DEPLOYMENT

### Tarjeta 56
**P**: ¿Qué dispositivos físicos incluye el deployment?
**R**: 
1. Computador embebido en bus
2. Servidor Central
3. Estaciones de trabajo de controladores
4. Servidor de BD
5. Servidor Web público

---

### Tarjeta 57
**P**: ¿Qué protocolo comunica buses con servidor central?
**R**: GPRS (comunicación inalámbrica celular).

---

### Tarjeta 58
**P**: ¿Cómo se comunican los demás nodos?
**R**: Internet/Intranet con protocolos HTTP, TCP/IP, servicios web.

---

## CATEGORÍA: PREGUNTAS DE ANÁLISIS

### Tarjeta 59
**P**: ¿Qué pasa si el nodo central falla?
**R**: 
- Buses siguen enviando datos (buffer en GPRS)
- Monitoreo muestra última info conocida
- Solución: HA con clúster activo-pasivo y failover automático

---

### Tarjeta 60
**P**: ¿Cómo agregarías predicción de mantenimiento?
**R**: 
1. Crear GestorMantenimientoPredictivo en nodo central
2. Registrarlo con ProcesadorCentral
3. Usar datos de GestorBD (averías, km)
4. Notificar vía GestorSincronizacion
5. Sin modificar otros componentes

---

### Tarjeta 61
**P**: ¿Por qué separar nodo de consultas del nodo central?
**R**: 
- Seguridad: público tiene menos privilegios
- Escalabilidad: puede escalar independientemente
- Tolerancia a fallos: falla de consultas no afecta operación crítica

---

### Tarjeta 62
**P**: ¿Qué ventajas tiene el procesamiento híbrido?
**R**: 
- Balance entre velocidad (tiempo real) y precisión (históricos)
- Eventos críticos respondidos inmediatamente
- Estimaciones basadas en años de datos
- Actualización continua sin recalcular todo

---

## CATEGORÍA: TÉRMINOS TÉCNICOS

### Tarjeta 63
**P**: ¿Qué es un datagrama en este contexto?
**R**: Conjunto de datos que contiene los valores sensados de todos los sensores del bus, transmitido cada 30 segundos.

---

### Tarjeta 64
**P**: ¿Qué es un arco en el sistema?
**R**: Segmento de ruta entre dos puntos (generalmente entre paradas), usado para calcular velocidades promedio.

---

### Tarjeta 65
**P**: ¿Qué es el CCO?
**R**: Centro de Control de Operación de Metrocali, responsable de la operación diaria del SITM-MIO.

---

### Tarjeta 66
**P**: ¿Qué es el PSO?
**R**: Plan de Servicios de Operación que deben cumplir los concesionarios de la operación.

---

## CATEGORÍA: NÚMEROS Y ESTADÍSTICAS

### Tarjeta 67
**P**: ¿Cuántos controladores operan el sistema?
**R**: 40 controladores de operación.

---

### Tarjeta 68
**P**: ¿Cuántas rutas principales tiene el SITM-MIO?
**R**: 100 rutas principales.

---

### Tarjeta 69
**P**: Proyección de crecimiento de buses
**R**: De ~1000 buses actuales a 2500 buses proyectados.

---

### Tarjeta 70
**P**: ¿Cuántos pasajeros transporta diariamente?
**R**: Aproximadamente 450,000 pasajeros por día.

---

## CATEGORÍA: EXTRAS - PREGUNTAS COMPLEJAS

### Tarjeta 71
**P**: Explica el ciclo de vida completo de un dato GPS.
**R**: 
1. Sensor GPS captura posición
2. Computador embebido lee sensor
3. GestorEventos crea datagrama
4. Envío vía GPRS cada 30 seg
5. GestorRecepcionDatos recibe
6. ProcesadorCentral coordina
7. GestorBD persiste
8. GestorAnalisis calcula velocidad
9. GestorSincronizacion actualiza
10. GestorMonitoreo muestra en mapa

---

### Tarjeta 72
**P**: ¿Qué tecnologías recomendarías para implementar esto?
**R**: 
- Backend: Java/Spring Boot o Python
- Mensajería: Apache Kafka (alto volumen)
- BD: PostgreSQL + PostGIS (geoespacial)
- Time-series: TimescaleDB
- Frontend: React + WebSockets
- Mapas: Leaflet.js
- Contenedores: Docker + Kubernetes

---

### Tarjeta 73
**P**: ¿Cómo garantizar disponibilidad 24/7?
**R**: 
- Alta disponibilidad (HA) en nodo central
- Replicación de base de datos
- Balanceo de carga
- Monitoreo y alertas
- Failover automático
- Redundancia en comunicaciones

---

### Tarjeta 74
**P**: ¿Qué métricas monitorizarías en producción?
**R**: 
- Eventos recibidos/segundo
- Latencia de procesamiento
- Disponibilidad de nodos
- Carga de BD
- Uso de CPU/memoria
- Errores en comunicación GPRS
- Tiempo de respuesta de consultas

---

### Tarjeta 75
**P**: Resume la arquitectura en una frase.
**R**: "Arquitectura distribuida de 5 nodos especializados comunicándose vía servicios, coordinados por un ProcesadorCentral mediador, para procesar millones de eventos diarios de forma escalable y tolerante a fallos, proporcionando análisis de movilidad en tiempo real."

---

## 🎯 FIN DE FLASHCARDS

**Total de tarjetas**: 75
**Tiempo estimado de repaso**: 30-45 minutos

**Sugerencia de uso**:
1. Primera pasada: Lee todas
2. Segunda pasada: Intenta responder antes de ver la respuesta
3. Tercera pasada: Solo las que fallaste
4. Antes del examen: Repaso rápido de las primeras 30

¡Buena suerte! 🚀
