# Guía de Estudio: Arquitectura de Software SITM-MIO

## Estudiantes
- Santiago Espinosa - A00399531
- Juan Esteban Gómez - A00400293

---

## 1. CONTEXTO DEL PROBLEMA

### Sistema SITM-MIO (Sistema Integrado de Transporte Masivo de Occidente)
- **Operador**: Centro de Control de Operación (CCO) de Metrocali
- **Escala actual**: ~1000 buses, proyección a 2500 buses
- **Usuarios diarios**: ~450,000 pasajeros
- **Rutas**: 100 rutas principales
- **Volumen de datos**: 2.5M - 3M eventos por día
- **Sensores por bus**: ~40 sensores
- **Frecuencia de transmisión**: Cada 30 segundos vía GPRS

### Objetivo Principal
Diseñar una arquitectura para estimar el **tiempo promedio de viaje entre dos puntos** de la ciudad usando datos históricos y en tiempo real de las posiciones GPS de los buses.

---

## 2. CLASIFICACIÓN DE REQUERIMIENTOS

### A. Requerimientos Funcionales Principales

#### **RF1: Gestión de Eventos**
- Los buses generan eventos automáticos y manuales
- Eventos categorizados con prioridades
- Interfaz especial con perilla para seguridad del conductor
- Tipos: GPS, apertura/cierre puertas, averías, trancones, atracos, etc.

#### **RF2: Gestión de Usuarios y Seguridad**
- Administración de roles, usuarios y permisos
- Autenticación y autorización
- Control de acceso basado en roles

#### **RF3: Procesamiento de Datos**
- Recepción masiva de datagramas (2.5M-3M/día)
- Procesamiento en tiempo real
- Persistencia en base de datos
- Escalabilidad horizontal

#### **RF4: Análisis y Estimaciones**
- Cálculo de velocidades promedio por arco
- Estimación de tiempos de viaje
- Análisis basado en datos históricos + tiempo real
- Actualización continua de métricas

#### **RF5: Visualización y Monitoreo**
- 40 controladores visualizando zonas asignadas
- Mapa en tiempo real con posiciones de buses
- Velocidades promedio por arco en cada zona
- Panel de control para operadores

#### **RF6: Asignación de Zonas**
- Asignar rutas y zonas a controladores
- Gestión dinámica de asignaciones

#### **RF7: Consultas Públicas**
- API para ciudadanos, empresas y entidades públicas
- Información sobre tiempos de viaje estimados
- Estado del sistema de transporte

---

## 3. ARQUITECTURA DEL SISTEMA

### Arquitectura General: **Distribuida Multi-Nodo**

Tu solución utiliza una **arquitectura orientada a servicios distribuida** con los siguientes nodos:

### **A. Nodo de Consultas (Sistema de Consultas)**
**Propósito**: Permitir a usuarios externos consultar información del sistema

**Componentes principales**:
- `GestorConsultas`: Coordina las consultas externas
- `UIConsultas`: Interfaz de usuario para consultas
- `ServicioConsultas`: Provee API REST/SOAP
- `ServicioConsultasPC`: Comunicación con el procesador central

**Responsabilidades**:
- Recibir consultas de usuarios externos (ciudadanos, empresas)
- Consultar estado del sistema
- Obtener estimaciones de tiempo de viaje
- Mostrar rutas y tiempos estimados

---

### **B. Nodo Central (Sistema de Procesamiento Central)**

**Es el cerebro del sistema**. Coordina todos los flujos de datos y operaciones.

#### **Componentes Clave**:

1. **ProcesadorCentral** (Componente Maestro)
   - Coordina TODOS los flujos del sistema
   - Delega tareas a gestores especializados
   - Punto central de comunicación entre nodos

2. **GestorRecepcionDatos**
   - Recibe datagramas de los buses (vía GPRS)
   - Punto de entrada de datos al sistema
   - Buffer/Cola de mensajes para manejar alto volumen

3. **GestorAnalisisEstimaciones**
   - Calcula velocidades promedio por arco
   - Estima tiempos de viaje
   - Combina datos históricos + tiempo real
   - Algoritmos de análisis de movilidad

4. **GestorSincronizacionActualizacion**
   - Actualiza datos en tiempo real en la BD
   - Notifica al nodo de monitoreo con nuevos datos
   - Mantiene sincronización entre nodos

5. **GestorUsuariosSeguridad**
   - Administra usuarios, roles y permisos
   - Verificación de autenticación/autorización
   - Control de acceso

6. **GestorZonasRutas**
   - Gestiona asignación de zonas a controladores
   - Administra rutas del sistema
   - Mapeo de arcos y segmentos

7. **ComunicacionExterna** (ServicioConsultas, ServicioZonasConsulta)
   - API para consultas externas
   - Interoperabilidad con otros sistemas

8. **Interfaces de Usuario**:
   - `UIZonas`: Administración de zonas
   - `UIUsuarios`: Gestión de usuarios

---

### **C. Nodo de Monitoreo (Modo de Monitoreo)**

**Propósito**: Visualización en tiempo real para controladores de operación

**Componentes**:
- `UIMonitoreo`: Dashboard para controladores
- `GestorMonitoreo`: Coordina la visualización
- `ServicioGestorMonitoreo`: Recibe actualizaciones del nodo central

**Responsabilidades**:
- Mostrar zonas asignadas a cada controlador
- Visualizar velocidades promedio por arco
- Mostrar posición en tiempo real de buses
- Alertas de congestión o eventos importantes

---

### **D. Nodo Bus (Sistema de Eventos)**

**Propósito**: Captura y envío de eventos desde los buses

**Componentes**:
- `GestorEventos`: Gestiona eventos del bus
- `UIBus`: Interfaz con perilla para el conductor
- `ServicioGestorEventos`: Comunicación vía GPRS

**Responsabilidades**:
- Capturar datos de sensores (GPS, puertas, etc.)
- Permitir registro manual de eventos por el conductor
- Asignar categoría y prioridad a eventos
- Enviar datagramas al nodo central cada 30 segundos

---

### **E. Nodo Base de Datos**

**Propósito**: Persistencia centralizada de todos los datos

**Componentes**:
- `GestorBD`: Servicio de acceso a datos
- `ServicioBD`: API de base de datos
- Switch de conexiones

**Almacena**:
- Usuarios, roles y permisos
- Eventos históricos (años de datos)
- Datos de GPS y sensores
- Zonas, rutas y arcos
- Métricas calculadas (velocidades, tiempos)
- Asignaciones de controladores

---

## 4. PATRONES ARQUITECTÓNICOS UTILIZADOS

### 4.1 **Arquitectura en Capas**
Cada nodo tiene una estructura en capas:
- **Capa de Presentación**: UIs
- **Capa de Lógica de Negocio**: Gestores
- **Capa de Servicios**: Servicios de comunicación
- **Capa de Datos**: GestorBD

### 4.2 **Patrón Mediador (Mediator)**
- El `ProcesadorCentral` actúa como mediador
- Evita acoplamiento directo entre componentes
- Coordina interacciones complejas

### 4.3 **Patrón Repository**
- `GestorBD` abstrae el acceso a datos
- Centraliza operaciones de persistencia

### 4.4 **Patrón Observer/Pub-Sub**
- `GestorSincronizacionActualizacion` notifica cambios
- El nodo de monitoreo se suscribe a actualizaciones
- Comunicación asíncrona entre nodos

### 4.5 **Arquitectura Orientada a Servicios (SOA)**
- Comunicación entre nodos vía servicios
- Bajo acoplamiento, alta cohesión
- Escalabilidad independiente por nodo

---

## 5. CASOS DE USO PRINCIPALES

### **Caso de Uso 1: Visualizar Análisis de Movilidad por Zona**

**Actor**: Controlador de operación

**Precondición**: El controlador tiene zonas asignadas

**Flujo Principal**:
1. Controlador selecciona "visualizar zonas" en UIMonitoreo
2. Sistema verifica permisos del usuario
3. Sistema muestra mapa con zonas asignadas
4. Controlador selecciona una zona específica
5. Sistema recopila datos en tiempo real de esa zona
6. Sistema calcula velocidad promedio por arco
7. Sistema muestra:
   - Mapa de la zona
   - Arcos con velocidades
   - Alertas de congestión

**Flujo Alterno**:
- Si no tiene permisos → muestra error

**Extensiones**:
- Obtener velocidad promedio por arco
- Calcular estimación de ruta
- Registrar evento

---

### **Caso de Uso 2: Consultar Estado del Sistema**

**Actor**: Ciudadano, empresa o entidad pública

**Precondición**: Sistema operativo y con datos actualizados

**Flujo Principal**:
1. Usuario accede a interfaz de consultas públicas
2. Selecciona "consultar estado del sistema"
3. Sistema recopila datos de buses y estaciones en tiempo real
4. Sistema muestra:
   - Estado general del sistema
   - Rutas disponibles
   - Estimaciones de tiempo (si aplica)

**Sub-casos de uso**:
- Obtener estado del sistema
- Seleccionar ruta
- Mostrar estimación de tiempo

---

## 6. DIAGRAMAS CRC (Clase-Responsabilidad-Colaboración)

### Metodología CRC
Las tarjetas CRC te ayudan a:
1. Identificar las responsabilidades de cada clase/componente
2. Ver claramente las colaboraciones entre componentes
3. Evitar componentes con demasiadas responsabilidades
4. Diseñar con bajo acoplamiento

### Componentes Clave y Sus Responsabilidades

#### **GestorRecepcionDatos**
- **Responsabilidades**: Recibir datagramas, enviar al ProcesadorCentral
- **Colaboradores**: ProcesadorCentral, GestorEventos (del bus)

#### **ProcesadorCentral** (El más importante)
- **Responsabilidades**: 
  - Coordinar todos los flujos
  - Delegar análisis, verificaciones, sincronización
  - Gestionar consultas externas
- **Colaboradores**: TODOS los gestores del nodo central

#### **GestorAnalisisEstimaciones**
- **Responsabilidades**: 
  - Calcular métricas de movilidad
  - Consultar datos históricos
  - Estimar velocidades y tiempos
- **Colaboradores**: ProcesadorCentral, GestorBD

#### **GestorSincronizacionActualizacion**
- **Responsabilidades**: 
  - Actualizar datos en tiempo real
  - Notificar al nodo de monitoreo
- **Colaboradores**: ProcesadorCentral, GestorMonitoreo, GestorBD

---

## 7. DECISIONES DE DISEÑO CRÍTICAS

### **7.1 ¿Por qué arquitectura distribuida?**

**Razones**:
1. **Escalabilidad**: Cada nodo puede escalar independientemente
   - El nodo central puede tener múltiples instancias
   - El nodo de monitoreo puede replicarse para 40 controladores

2. **Separación de preocupaciones**:
   - Nodo de consultas: público, bajo privilegio
   - Nodo central: lógica crítica de negocio
   - Nodo de monitoreo: visualización en tiempo real
   - Nodo de bus: operación en campo

3. **Tolerancia a fallos**:
   - Si falla un nodo de monitoreo, no afecta la recepción de datos
   - Si falla consultas públicas, no afecta operación interna

4. **Rendimiento**:
   - Procesamiento distribuido de 2.5M eventos/día
   - Cálculos pesados no bloquean otras operaciones

### **7.2 ¿Por qué un ProcesadorCentral mediador?**

**Ventajas**:
- Evita que cada componente conozca a todos los demás
- Facilita agregar nuevos gestores sin modificar existentes
- Punto único para logging, monitoreo y debugging
- Implementa lógica de orquestación compleja

### **7.3 ¿Base de datos centralizada o distribuida?**

Tu diseño usa **base de datos centralizada** con un nodo dedicado.

**Ventajas**:
- Consistencia de datos
- Facilita análisis que requieren datos históricos completos
- Simplifica transacciones

**Consideración para escalabilidad futura**:
- Podrías implementar sharding por zona geográfica
- Réplicas de lectura para consultas públicas

### **7.4 ¿Procesamiento en tiempo real vs batch?**

Tu solución usa **procesamiento híbrido**:
- **Tiempo real**: Para actualizar posiciones y eventos inmediatos
- **Análisis periódico**: Para cálculo de velocidades promedio con datos históricos
- **Actualización incremental**: Nuevos datos ajustan métricas existentes

---

## 8. FLUJOS DE DATOS IMPORTANTES

### **Flujo 1: Recepción de Datagrama**
```
Bus → GestorEventos → GPRS → 
GestorRecepcionDatos → ProcesadorCentral → 
GestorBD (persistir) → 
GestorSincronizacionActualizacion → 
GestorMonitoreo (actualizar visualización)
```

### **Flujo 2: Cálculo de Velocidad Promedio**
```
Controlador → UIMonitoreo → GestorMonitoreo → 
ProcesadorCentral → GestorAnalisisEstimaciones → 
GestorBD (consultar históricos) → 
Calcular velocidad → 
GestorSincronizacionActualizacion → 
GestorMonitoreo → UIMonitoreo (mostrar)
```

### **Flujo 3: Consulta Pública**
```
Ciudadano → UIConsultas → GestorConsultas → 
ServicioConsultas → ProcesadorCentral → 
GestorAnalisisEstimaciones → GestorBD → 
Retornar estimación → UIConsultas
```

### **Flujo 4: Asignación de Zona**
```
Administrador → UIZonas → GestorZonasRutas → 
ProcesadorCentral → GestorUsuariosSeguridad (verificar) → 
GestorBD (persistir asignación) → 
Confirmar → UIZonas
```

---

## 9. DIAGRAMAS UML - PUNTOS CLAVE

### **Diagrama de Deployment**
Tu diagrama muestra:

**Dispositivos/Nodos físicos**:
1. **Computador embebido en bus** (Nodo Bus)
2. **Servidor Central** (Nodo Central de Procesamiento)
3. **Estaciones de trabajo de controladores** (Nodo Monitoreo)
4. **Servidor de BD** (Nodo Base de Datos)
5. **Servidor Web público** (Nodo Consultas)

**Comunicación**:
- GPRS entre buses y servidor central
- Internet/Intranet entre nodos
- Switch para conexiones a BD

**Elementos clave**:
- `<<device>>` para hardware físico
- `<<component>>` para software deployable
- Conectores con protocolos (GPRS, HTTP, TCP/IP)

### **Diagrama de Casos de Uso**
- Actor principal: Controlador
- Actores secundarios: Ciudadano, Conductor, Administrador
- Relaciones `<<include>>` y `<<extend>>`
- Agrupación por sistemas (visualización, consultas, eventos, central)

---

## 10. TECNOLOGÍAS SUGERIDAS (Para Implementación)

### Backend
- **Lenguaje**: Java/Spring Boot o Python/Django
- **Servicios**: RESTful APIs
- **Mensajería**: Apache Kafka o RabbitMQ (para manejar 2.5M eventos/día)
- **Cache**: Redis (para velocidades calculadas)

### Base de Datos
- **Transaccional**: PostgreSQL con extensión PostGIS (datos geoespaciales)
- **Time-series**: InfluxDB o TimescaleDB (para eventos con timestamp)
- **Consultas analíticas**: Apache Spark o Presto

### Frontend
- **Monitoreo**: React con WebSockets (actualización en tiempo real)
- **Mapas**: Leaflet.js o Google Maps API
- **Consultas públicas**: Progressive Web App (PWA)

### Infraestructura
- **Contenedores**: Docker
- **Orquestación**: Kubernetes (para escalabilidad)
- **Balanceador**: Nginx o HAProxy

---

## 11. PREGUNTAS DE ESTUDIO

### Preguntas Conceptuales

**P1**: ¿Por qué se eligió una arquitectura distribuida multi-nodo en lugar de una arquitectura monolítica?

**Respuesta**: La arquitectura distribuida permite:
- Escalabilidad independiente de cada componente (crítico para manejar 2.5M eventos/día)
- Separación de concerns (buses, procesamiento, visualización, consultas)
- Tolerancia a fallos (un nodo caído no tumba todo el sistema)
- Mejor rendimiento (procesamiento paralelo)

---

**P2**: ¿Cuál es el rol del ProcesadorCentral y por qué es importante?

**Respuesta**: Es el componente mediador que:
- Coordina todos los flujos del sistema
- Evita acoplamiento directo entre componentes
- Facilita mantenimiento y extensibilidad
- Implementa patrón Mediator para orquestación compleja

---

**P3**: ¿Cómo maneja el sistema el volumen masivo de datos (2.5M-3M eventos/día)?

**Respuesta**:
- Cola de mensajes en GestorRecepcionDatos (buffer)
- Procesamiento asíncrono
- Base de datos optimizada para time-series
- Arquitectura escalable horizontalmente
- Cache de métricas calculadas

---

**P4**: Explica la diferencia entre análisis en tiempo real y análisis histórico en este sistema.

**Respuesta**:
- **Tiempo real**: Actualización inmediata de posiciones, eventos críticos, alertas
- **Histórico**: Cálculo de velocidades promedio basado en meses/años de datos
- **Híbrido**: Velocidades se recalculan incrementalmente con nuevos datos

---

**P5**: ¿Por qué los buses tienen una interfaz especial con perilla?

**Respuesta**: Por seguridad vial (Req. 2):
- Evita que el conductor desvíe la vista de la vía
- Interfaz táctil sin necesidad de mirar pantalla
- Reduce riesgo de accidentes

---

### Preguntas de Diseño

**P6**: Si tuvieras que agregar un nuevo tipo de análisis (ej: predicción de mantenimiento), ¿cómo lo integrarías?

**Respuesta**:
1. Crear `GestorMantenimientoPredictivo` en nodo central
2. Registrarlo con ProcesadorCentral
3. Usar datos de GestorBD (eventos de averías, km recorridos)
4. Notificar vía GestorSincronizacionActualizacion
5. Sin modificar otros componentes (bajo acoplamiento)

---

**P7**: ¿Cómo escalarías el sistema si crece a 2500 buses?

**Respuesta**:
- Múltiples instancias del nodo central con balanceador
- Sharding de base de datos por zona geográfica
- Clúster de Kafka/RabbitMQ para mensajería
- Réplicas de lectura para consultas
- CDN para consultas públicas

---

**P8**: ¿Qué pasa si se cae el nodo central?

**Respuesta**:
- Los buses siguen enviando datos (GPRS con buffer)
- Nodo de monitoreo muestra última información conocida
- Implementar HA (High Availability): 
  - Clúster activo-pasivo
  - Failover automático
  - Estado persistido en BD o cache distribuido

---

## 12. CHECKLIST DE CONCEPTOS CLAVE

Asegúrate de entender:

- [ ] Diferencia entre nodo lógico y dispositivo físico
- [ ] Patrón Mediator y su implementación en ProcesadorCentral
- [ ] Flujo completo de un datagrama desde el bus hasta la visualización
- [ ] Rol de cada gestor en el nodo central
- [ ] Relaciones `<<include>>` y `<<extend>>` en casos de uso
- [ ] Tarjetas CRC: Responsabilidades vs Colaboradores
- [ ] Comunicación síncrona vs asíncrona entre nodos
- [ ] Escalabilidad horizontal vs vertical
- [ ] Procesamiento en tiempo real vs batch
- [ ] Arquitectura en capas dentro de cada nodo

---

## 13. RESUMEN EJECUTIVO

### Tu Solución en 3 Puntos

1. **Arquitectura Distribuida de 5 Nodos**:
   - Bus (captura eventos)
   - Central (procesamiento y coordinación)
   - Monitoreo (visualización para controladores)
   - Consultas (API pública)
   - Base de Datos (persistencia)

2. **Patrón Mediador con ProcesadorCentral**:
   - Coordina gestores especializados
   - Bajo acoplamiento entre componentes
   - Facilita mantenimiento y extensión

3. **Procesamiento Híbrido**:
   - Tiempo real para eventos críticos
   - Análisis histórico para estimaciones
   - Actualización incremental de métricas

### Fortalezas de tu Diseño
✓ Escalable para crecer de 1000 a 2500 buses
✓ Separa preocupaciones claramente
✓ Maneja volúmenes masivos de datos
✓ Provee APIs para consultas públicas
✓ Actualización en tiempo real para controladores
✓ Tolerante a fallos por distribución
✓ Bajo acoplamiento, alta cohesión

---

## 14. TIPS PARA EL EXAMEN

1. **Dibuja los diagramas de memoria**:
   - Practica dibujar el deployment diagram sin ver el original
   - Dibuja el flujo de datos principal

2. **Explica el "por qué" de cada decisión**:
   - No solo digas "usamos arquitectura distribuida"
   - Explica "usamos arquitectura distribuida porque necesitamos escalar de 1000 a 2500 buses..."

3. **Conoce los números**:
   - 2.5M-3M eventos/día
   - 1000 buses → 2500 buses
   - 40 controladores
   - 450,000 pasajeros/día
   - 30 segundos de frecuencia de envío

4. **Relaciona patrones con componentes**:
   - Mediator → ProcesadorCentral
   - Observer → GestorSincronizacionActualizacion
   - Repository → GestorBD

5. **Prepara respuestas a "¿Qué pasaría si...?"**:
   - ¿Qué pasa si duplicamos el número de buses?
   - ¿Qué pasa si un nodo falla?
   - ¿Cómo agregarías una nueva funcionalidad?

---

## DIAGRAMA DE FLUJO MENTAL

```
[BUS] --GPRS--> [CENTRAL] --Ethernet--> [BD]
                    |
                    +---> [MONITOREO] (40 controladores)
                    |
                    +---> [CONSULTAS] (público)
```

**Recuerda**: El nodo central es el corazón, la BD es la memoria, los demás son interfaces especializadas.

---

¡Éxito en tu estudio! 🚀
