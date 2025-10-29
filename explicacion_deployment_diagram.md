# 📐 Explicación Detallada del Diagrama de Deployment - SITM-MIO

## 🎯 Visión General

El diagrama de deployment muestra la **arquitectura física** del sistema SITM-MIO, representando cómo los componentes de software se distribuyen en los nodos de hardware (dispositivos físicos) y cómo se comunican entre sí a través de diferentes protocolos de red.

---

## 🖥️ NODOS FÍSICOS (Devices)

### 1. **<<device>> Bus**
**Descripción**: Computador embebido instalado en cada uno de los ~1000 buses del sistema.

**Hardware típico**:
- Computador industrial embebido (ej: Raspberry Pi, Intel NUC industrial)
- Módulo GPRS/celular para comunicación
- Interfaz con ~40 sensores del bus
- Pantalla táctil o perilla física para el conductor

**Componentes de software desplegados**:
- `<<component>> GestorEventos`: Gestiona la captura y envío de eventos
- `<<component>> UIBus`: Interfaz de usuario (perilla) para el conductor

**Servicios expuestos**:
- `ServicioGestorEventos`: Endpoint para comunicación con el nodo central

**Conectividad**: GPRS (red celular) hacia el nodo central

---

### 2. **<<device>> Sistema de Procesamiento Central**
**Descripción**: Servidor principal del sistema, es el "cerebro" que coordina todas las operaciones.

**Hardware típico**:
- Servidor de alto rendimiento (multi-core, alta RAM)
- Puede ser un clúster de servidores para alta disponibilidad
- Ubicado en el data center del CCO de Metrocali

**Componentes de software desplegados**:

#### **Componente Maestro**:
- `<<component>> ProcesadorCentral`: Orquestador principal (patrón Mediator)

#### **Gestores Especializados**:
- `<<component>> GestorRecepcionDatos`: Recibe datagramas de los buses
- `<<component>> GestorAnalisisEstimaciones`: Calcula velocidades promedio y tiempos
- `<<component>> GestorSincronizacionActualizacion`: Actualiza y sincroniza datos
- `<<component>> GestorUsuariosSeguridad`: Administra usuarios, roles y permisos
- `<<component>> GestorZonasRutas`: Gestiona asignaciones de zonas a controladores
- `<<component>> ComunicacionExterna`: Maneja comunicación con nodos externos

#### **Interfaces de Usuario**:
- `<<component>> UIUsuarios`: Interfaz para administración de usuarios
- `<<component>> UIZonas`: Interfaz para gestión de zonas y rutas

**Servicios expuestos**:
- `ServicioRecepcionDatosPC`: Recibe datos de buses
- `ServicioConsultasPC`: Atiende consultas del nodo de consultas
- `ServicioAnalisisEst`: Provee análisis y estimaciones
- `ServicioZonasPC`: Gestiona zonas
- `ServicioUsuariosSeg`: Gestiona seguridad
- `ServicioSincActu`: Sincronización con monitoreo

**Conectividad**: 
- GPRS (recibe de buses)
- Ethernet/Internet (conecta con BD, monitoreo, consultas)

---

### 3. **<<device>> Nodo de Monitoreo**
**Descripción**: Estaciones de trabajo para los 40 controladores de operación que supervisan el sistema en tiempo real.

**Hardware típico**:
- Computadores de escritorio o laptops
- Pantallas grandes (posiblemente múltiples monitores)
- Ubicados en la sala de control del CCO

**Componentes de software desplegados**:
- `<<component>> UIMonitoreo`: Dashboard interactivo con mapas en tiempo real
- `<<component>> GestorMonitoreo`: Coordina la visualización y recepción de datos

**Servicios expuestos/consumidos**:
- `ServicioGestorMonitoreo`: Recibe actualizaciones del nodo central
- `MostrarResultados`: Renderiza información en la UI

**Funcionalidades visibles**:
- Mapa de Cali con posiciones de buses en tiempo real
- Zonas asignadas al controlador
- Velocidades promedio por arco
- Alertas y eventos importantes

**Conectividad**: Ethernet/Intranet hacia el nodo central

---

### 4. **<<device>> Nodo Sistema de Consultas**
**Descripción**: Servidor web público que expone información del sistema a ciudadanos y entidades externas.

**Hardware típico**:
- Servidor web en DMZ (zona desmilitarizada) para seguridad
- Balanceador de carga para alto tráfico
- Posiblemente CDN para distribución de contenido estático

**Componentes de software desplegados**:
- `<<component>> UIConsultas`: Interfaz web pública (sitio web/app móvil)
- `<<component>> GestorConsultas`: Lógica de negocio para consultas públicas

**Servicios expuestos**:
- `ServicioConsultas`: API REST/SOAP para consultas externas
- `ServicioZonasConsulta`: Consulta información de zonas

**Usuarios**:
- Ciudadanos que quieren saber tiempos de viaje
- Empresas que integran con la API
- Entidades públicas que monitorizan el sistema

**Conectividad**: Internet hacia el nodo central

---

### 5. **<<device>> Base de Datos**
**Descripción**: Servidor de base de datos centralizado que almacena toda la información del sistema.

**Hardware típico**:
- Servidor de base de datos de alto rendimiento
- Storage de alta capacidad (varios TB para datos históricos)
- Posible configuración maestro-esclavo para replicación

**Componentes de software desplegados**:
- `<<component>> GestorBD`: Servicio de acceso a datos (API de base de datos)
- Motor de BD (ej: PostgreSQL con PostGIS, TimescaleDB)

**Servicios expuestos**:
- `ServicioBD`: Único punto de acceso a la base de datos

**Datos almacenados**:
- Eventos históricos (años de datagramas)
- Usuarios, roles y permisos
- Zonas, rutas y arcos del sistema
- Métricas calculadas (velocidades, tiempos)
- Asignaciones de controladores
- Posiciones GPS históricas

**Conectividad**: Ethernet/Intranet con el nodo central y switch

---

### 6. **<<device>> Switch**
**Descripción**: Dispositivo de red que facilita las conexiones entre los nodos del sistema.

**Función**:
- Enrutamiento de paquetes de red
- Balanceo de carga (posiblemente)
- Seguridad de red (firewall, VLANs)

**Conectividad**: Ethernet con todos los nodos internos

---

## 🔗 PROTOCOLOS DE COMUNICACIÓN

### **<<GPRS>>** - General Packet Radio Service
**Entre**: Bus ↔ Sistema de Procesamiento Central

**Características**:
- Comunicación inalámbrica celular (2G/3G/4G)
- Transmisión cada 30 segundos
- Debe manejar conexiones intermitentes
- Posible buffer en el bus si pierde conexión

**Datos transmitidos**:
- Datagramas con ~40 valores de sensores
- Eventos manuales del conductor
- Posición GPS actualizada

**Consideraciones**:
- Latencia variable según cobertura
- Ancho de banda limitado
- Debe ser confiable (ACK/retransmisión)

---

### **<<Internet>>** 
**Entre**: Nodo de Consultas ↔ Sistema de Procesamiento Central

**Características**:
- Conexión pública a través de internet
- Requiere alta seguridad (HTTPS, autenticación)
- Posible uso de API Gateway

**Protocolos típicos**:
- HTTP/HTTPS para APIs REST
- WebSockets para actualizaciones en tiempo real (opcional)
- SOAP si se requiere (más pesado)

**Seguridad**:
- SSL/TLS para encriptación
- Autenticación por tokens (OAuth, JWT)
- Rate limiting para evitar abuso

---

### **<<eth>>** - Ethernet
**Entre**: Nodos internos (Central ↔ BD, Central ↔ Monitoreo)

**Características**:
- Red local de alta velocidad (Gigabit Ethernet)
- Baja latencia
- Alta confiabilidad
- Puede usar VLANs para segmentación

**Protocolos típicos**:
- TCP/IP para comunicación confiable
- Posible uso de RPC (Remote Procedure Call)
- Posible uso de mensajería (Kafka, RabbitMQ)

---

## 🔄 FLUJOS DE COMUNICACIÓN PRINCIPALES

### **Flujo 1: Envío de Datagrama del Bus**

```
┌─────┐  GPRS   ┌──────────┐  eth   ┌────┐
│ Bus │ ─────→ │ Central  │ ─────→ │ BD │
└─────┘         └────┬─────┘         └────┘
                     │ eth
                     ↓
              ┌───────────┐
              │ Monitoreo │
              └───────────┘
```

**Detalle del flujo**:
1. `UIBus` registra evento → `GestorEventos`
2. `ServicioGestorEventos` envía por GPRS
3. `ServicioRecepcionDatos` recibe en Central
4. `GestorRecepcionDatos` → `ProcesadorCentral`
5. `ProcesadorCentral` → `GestorBD` (persistir)
6. `ProcesadorCentral` → `GestorSincronizacionActualizacion`
7. `ServicioSincActu` notifica → `ServicioGestorMonitoreo`
8. `GestorMonitoreo` actualiza → `UIMonitoreo`

---

### **Flujo 2: Consulta de Velocidad por Zona**

```
┌───────────┐  eth   ┌──────────┐  eth   ┌────┐
│ Monitoreo │ ─────→ │ Central  │ ←────→ │ BD │
└───────────┘         └──────────┘         └────┘
```

**Detalle del flujo**:
1. Controlador selecciona zona en `UIMonitoreo`
2. `GestorMonitoreo` → `ServicioGestorMonitoreo`
3. Request a `ServicioAnalisisEst` en Central
4. `ProcesadorCentral` → `GestorAnalisisEstimaciones`
5. `GestorAnalisisEstimaciones` → `GestorBD` (consultar históricos)
6. `ServicioBD` retorna datos
7. Cálculo de velocidad promedio
8. Respuesta de vuelta a `UIMonitoreo`

---

### **Flujo 3: Consulta Pública de Ciudadano**

```
┌──────────┐  Internet  ┌──────────┐  eth   ┌────┐
│ Consultas│ ──────────→│ Central  │ ←────→ │ BD │
└──────────┘             └──────────┘         └────┘
```

**Detalle del flujo**:
1. Ciudadano ingresa consulta en `UIConsultas`
2. `GestorConsultas` → `ServicioConsultas`
3. Request a `ServicioConsultasPC` en Central
4. `ProcesadorCentral` → `GestorAnalisisEstimaciones`
5. Consulta a BD vía `GestorBD`
6. Cálculo de estimación de tiempo
7. Respuesta a través de `ServicioConsultas`
8. `UIConsultas` muestra resultado

---

## 🎨 SERVICIOS Y SUS FUNCIONES

### **Servicios del Nodo Central**

| Servicio | Función | Consumidores |
|----------|---------|--------------|
| `ServicioRecepcionDatos` | Recibir datagramas de buses | Buses vía GPRS |
| `ServicioRecepcionDatosPC` | Procesar datagramas recibidos | Interno (GestorRecepcionDatos) |
| `ServicioConsultasPC` | Atender consultas externas | Nodo de Consultas |
| `ServicioAnalisisEst` | Proveer análisis y estimaciones | Monitoreo, Consultas |
| `ServicioZonasPC` | Gestionar zonas y asignaciones | UIZonas, Monitoreo |
| `ServicioUsuariosSeg` | Autenticación y autorización | Todos los nodos |
| `ServicioSincActu` | Notificar actualizaciones | Nodo de Monitoreo |
| `ServicioZonasConsulta` | Consultar información de zonas | Interno/Externo |

### **Servicios del Nodo de Monitoreo**

| Servicio | Función | Consumidores |
|----------|---------|--------------|
| `ServicioGestorMonitoreo` | Recibir datos de visualización | Nodo Central |
| `MostrarResultados` | Renderizar información en UI | UIMonitoreo |
| `RecibirDatos` | Endpoint para recibir actualizaciones | Nodo Central |

### **Servicios del Nodo de Consultas**

| Servicio | Función | Consumidores |
|----------|---------|--------------|
| `ServicioConsultas` | API pública para consultas | Ciudadanos, apps externas |
| `ServicioZonasConsulta` | Consultar zonas específicas | UIConsultas |

### **Servicios del Nodo de BD**

| Servicio | Función | Consumidores |
|----------|---------|--------------|
| `ServicioBD` | Acceso unificado a base de datos | Todos los gestores del Central |

### **Servicios del Nodo Bus**

| Servicio | Función | Consumidores |
|----------|---------|--------------|
| `ServicioGestorEventos` | Enviar eventos al central | Nodo Central |

---

## 🏛️ ARQUITECTURA DE CAPAS EN CADA NODO

Cada nodo sigue una arquitectura en capas:

### **Bus**
```
┌─────────────────────┐
│ Capa Presentación   │ → UIBus
├─────────────────────┤
│ Capa Lógica         │ → GestorEventos
├─────────────────────┤
│ Capa Comunicación   │ → ServicioGestorEventos
└─────────────────────┘
```

### **Central** (más complejo)
```
┌─────────────────────┐
│ Capa Presentación   │ → UIUsuarios, UIZonas
├─────────────────────┤
│ Capa Lógica         │ → ProcesadorCentral + 6 Gestores
├─────────────────────┤
│ Capa Servicios      │ → 8 Servicios diferentes
├─────────────────────┤
│ Capa Integración    │ → Conectores GPRS/Ethernet
└─────────────────────┘
```

### **Monitoreo**
```
┌─────────────────────┐
│ Capa Presentación   │ → UIMonitoreo
├─────────────────────┤
│ Capa Lógica         │ → GestorMonitoreo
├─────────────────────┤
│ Capa Comunicación   │ → ServicioGestorMonitoreo
└─────────────────────┘
```

---

## 🔐 CONSIDERACIONES DE SEGURIDAD

### **Perímetro de Seguridad**

```
┌──────────────────────────────────────┐
│         ZONA PÚBLICA (DMZ)           │
│  ┌────────────────────┐              │
│  │ Nodo de Consultas  │              │
│  └────────────────────┘              │
└──────────────┬───────────────────────┘
               │ Firewall
┌──────────────┴───────────────────────┐
│      ZONA PRIVADA (INTRANET)         │
│  ┌──────────┐  ┌──────────┐          │
│  │ Central  │  │    BD    │          │
│  └──────────┘  └──────────┘          │
│  ┌──────────┐                        │
│  │Monitoreo │                        │
│  └──────────┘                        │
└──────────────────────────────────────┘
```

### **Medidas de Seguridad por Nodo**

**Nodo de Consultas**:
- En DMZ (zona desmilitarizada)
- Solo acceso de lectura
- Rate limiting para prevenir DDoS
- Autenticación de API (tokens, OAuth)
- No acceso directo a BD

**Nodo Central**:
- En red privada
- Firewall restrictivo
- Autenticación fuerte (2FA para admins)
- Logs de auditoría
- Cifrado de datos sensibles

**Nodo de Monitoreo**:
- Red interna solo
- Autenticación de usuarios
- Sesiones con timeout
- Control de acceso basado en roles (RBAC)

**Bus**:
- Certificados para autenticación
- Datos cifrados en tránsito (GPRS)
- Validación en el servidor central
- No almacena datos sensibles localmente

**Base de Datos**:
- Red privada aislada
- Solo accesible por Central
- Backups cifrados
- Replicación para recuperación

---

## 📊 ESCALABILIDAD DEL DEPLOYMENT

### **Escalamiento Horizontal**

Para crecer de 1000 a 2500 buses:

#### **Nodo Central**
```
┌─────────────────────────────────────┐
│     Balanceador de Carga            │
└──────┬─────────┬─────────┬──────────┘
       │         │         │
   ┌───▼───┐ ┌───▼───┐ ┌───▼───┐
   │Central│ │Central│ │Central│
   │   1   │ │   2   │ │   3   │
   └───────┘ └───────┘ └───────┘
```

**Estrategia**:
- Clúster de servidores Central
- Balanceador distribuye carga de buses
- Estado compartido en BD/Cache (Redis)
- Sessionless para facilitar escalado

#### **Base de Datos**
```
┌──────────┐
│ Maestro  │
└────┬─────┘
     │ Replicación
     ├────────────┬────────────┐
┌────▼────┐  ┌────▼────┐  ┌────▼────┐
│Esclavo 1│  │Esclavo 2│  │Esclavo 3│
└─────────┘  └─────────┘  └─────────┘
```

**Estrategia**:
- Maestro para escrituras
- Esclavos para lecturas (consultas, monitoreo)
- Posible sharding por zona geográfica
- Cache distribuido (Redis) para métricas

#### **Nodo de Monitoreo**
```
┌───────────┐ ┌───────────┐ ┌───────────┐
│ Monitor 1 │ │ Monitor 2 │ │ Monitor N │
│(Control 1)│ │(Control 2)│ │(Control N)│
└───────────┘ └───────────┘ └───────────┘
```

**Estrategia**:
- Cada controlador su propia instancia
- WebSockets para updates en tiempo real
- Filtrado en servidor (solo zonas asignadas)

---

## 🔄 ALTA DISPONIBILIDAD (HA)

### **Configuración de Failover**

```
┌──────────────┐          ┌──────────────┐
│ Central      │  Heartbeat│ Central      │
│ ACTIVO       │◄─────────►│ STANDBY      │
└──────┬───────┘           └──────┬───────┘
       │                          │
       │      Si falla Activo     │
       │      Standby toma control│
       │                          │
   ┌───▼──────────────────────────▼───┐
   │    Base de Datos Compartida      │
   └──────────────────────────────────┘
```

**Características**:
- Activo-Pasivo inicialmente
- Failover automático (< 1 minuto)
- Estado persistido en BD
- Buses reintentan automáticamente
- Monitoreo muestra "última info conocida" durante failover

---

## 💡 DECISIONES DE DISEÑO CRÍTICAS

### **1. ¿Por qué GPRS en lugar de WiFi para buses?**

**Respuesta**: 
- Los buses se mueven por toda la ciudad
- WiFi requeriría miles de puntos de acceso
- GPRS/4G tiene cobertura en toda Cali
- Costo-beneficio favorable
- Ya existe infraestructura celular

---

### **2. ¿Por qué separar Consultas en nodo independiente?**

**Respuesta**:
- **Seguridad**: Público no accede a infraestructura crítica
- **Escalabilidad**: Puede escalar independientemente según demanda ciudadana
- **Aislamiento**: Falla en consultas ≠ falla en operación
- **Rendimiento**: Evita que consultas públicas saturen el Central

---

### **3. ¿Por qué un solo nodo de BD centralizado?**

**Respuesta**:
- **Consistencia**: Análisis requiere vista unificada de datos
- **Simplicidad**: Evita problemas de sincronización distribuida
- **Transacciones**: Facilita operaciones ACID
- **Futura evolución**: Puede evolucionar a distribuida si es necesario

---

### **4. ¿Por qué Ethernet para comunicación interna?**

**Respuesta**:
- **Velocidad**: Gigabit Ethernet es muy rápido
- **Confiabilidad**: Conexión cableada más estable
- **Seguridad**: Red privada, no expuesta a internet
- **Costo**: Infraestructura ya existente en el data center

---

## 📈 MÉTRICAS DE PERFORMANCE ESPERADAS

### **Latencias Objetivo**

| Operación | Latencia Target | Protocolo |
|-----------|----------------|-----------|
| Bus → Central (envío datagrama) | < 2 segundos | GPRS |
| Central → BD (persistir) | < 100 ms | Ethernet |
| Central → Monitoreo (update) | < 500 ms | Ethernet |
| Consulta pública (API) | < 1 segundo | Internet |
| Cálculo velocidad promedio | < 3 segundos | N/A |

### **Throughput**

- **Datagramas/segundo**: ~1200 (1000 buses cada 30 seg con margen)
- **Consultas públicas/seg**: 100-1000 (variable)
- **Actualizaciones monitoreo/seg**: 10-50 por controlador
- **Escrituras BD/seg**: ~1500-2000 (datagramas + eventos)
- **Lecturas BD/seg**: 5000-10000 (consultas + análisis)

---

## 🛠️ TECNOLOGÍAS SUGERIDAS POR NODO

### **Nodo Bus**
- **OS**: Linux embebido (Ubuntu Core, Raspbian)
- **Lenguaje**: C++ o Python (eficiente, ligero)
- **Comunicación**: Biblioteca GPRS/4G
- **UI**: Qt o simple GPIO para perilla

### **Nodo Central**
- **OS**: Linux Server (Ubuntu Server, CentOS)
- **Framework**: Spring Boot (Java) o Django (Python)
- **Mensajería**: Apache Kafka o RabbitMQ
- **Cache**: Redis
- **Servicios**: REST + WebSockets

### **Nodo BD**
- **RDBMS**: PostgreSQL con PostGIS (geoespacial)
- **Time-Series**: TimescaleDB (extensión de PostgreSQL)
- **Tamaño**: 10-50 TB (datos históricos)
- **Backup**: Replicación asíncrona + snapshots diarios

### **Nodo Monitoreo**
- **Frontend**: React + Leaflet.js (mapas)
- **Comunicación**: WebSockets para real-time
- **OS**: Windows 10/11 o Linux Desktop

### **Nodo Consultas**
- **Frontend**: React/Vue PWA (Progressive Web App)
- **Backend**: Node.js + Express o Python + FastAPI
- **API**: REST con documentación OpenAPI/Swagger
- **CDN**: CloudFlare para static assets

---

## 📝 RESUMEN EJECUTIVO DEL DEPLOYMENT

### **Características Clave**

1. **Arquitectura de 5 nodos distribuidos**:
   - Bus (embebido, móvil)
   - Central (servidor potente, coordinador)
   - Monitoreo (estaciones de trabajo)
   - Consultas (servidor web público)
   - Base de Datos (servidor de almacenamiento)

2. **Comunicación multi-protocolo**:
   - GPRS para buses móviles
   - Ethernet para nodos internos
   - Internet para consultas públicas

3. **Separación clara de responsabilidades**:
   - Captura de datos (Bus)
   - Procesamiento (Central)
   - Visualización interna (Monitoreo)
   - Consultas externas (Consultas)
   - Persistencia (BD)

4. **Escalabilidad horizontal preparada**:
   - Central puede clusterizarse
   - BD puede replicarse
   - Consultas puede usar CDN

5. **Seguridad por capas**:
   - DMZ para nodo público
   - Red privada para operación crítica
   - Cifrado en todas las comunicaciones

---

## ✅ CHECKLIST DE COMPRENSIÓN

Verifica que entiendas:

- [ ] Los 5 nodos físicos y su hardware típico
- [ ] Qué componentes de software van en cada nodo
- [ ] Los 3 protocolos de comunicación (GPRS, Ethernet, Internet)
- [ ] Flujo completo de un datagrama: Bus → Central → BD → Monitoreo
- [ ] Por qué GPRS para buses y no WiFi
- [ ] Por qué el nodo de Consultas está separado del Central
- [ ] Cómo escala cada nodo independientemente
- [ ] Estrategia de alta disponibilidad del Central
- [ ] Perímetro de seguridad (DMZ vs red privada)
- [ ] Servicios expuestos por cada nodo

---

## 🎯 PREGUNTAS DE REPASO

**P1**: ¿Qué dispositivo físico tiene el componente ProcesadorCentral?
**R**: El Sistema de Procesamiento Central (servidor principal).

**P2**: ¿Por qué el bus usa GPRS en lugar de conexión directa?
**R**: Porque los buses son móviles y necesitan comunicación inalámbrica con cobertura en toda la ciudad.

**P3**: ¿Cuántos protocolos de comunicación aparecen en el diagrama?
**R**: 3 protocolos: GPRS (buses), Ethernet (nodos internos) e Internet (consultas públicas).

**P4**: ¿Qué nodo es accesible desde Internet?
**R**: Solo el Nodo de Consultas (para ciudadanos y entidades públicas).

**P5**: ¿Dónde se persisten los datagramas?
**R**: En el Nodo de Base de Datos a través del ServicioBD.

**P6**: ¿Qué componente notifica al monitoreo de cambios?
**R**: El GestorSincronizacionActualizacion del nodo Central.

**P7**: Si falla el nodo Central, ¿pueden los buses seguir enviando datos?
**R**: Sí, pero los datos se bufferean hasta que el Central se recupere (o failover a standby).

**P8**: ¿Cuál es el único punto de acceso a la base de datos?
**R**: El GestorBD a través del ServicioBD.

---

**Fecha**: Octubre 2025  
**Proyecto**: Arquitectura SITM-MIO  
**Estudiantes**: Santiago Espinosa, Juan Esteban Gómez  
**Herramienta**: Visual Paradigm Professional
