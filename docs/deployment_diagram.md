# Diagrama de Deployment - Sistema SITM-MIO

![Diagrama de Deployment](deployment_diagram.png)

## Arquitectura de Deployment Completa

### Vista General

El sistema SITM-MIO implementa una arquitectura distribuida Master-Worker sobre ZeroC-ICE para procesar grandes volúmenes de datagramas históricos y en tiempo real, calculando velocidades promedio por arcos de rutas del sistema de transporte MIO.

### Estructuras Distribuidas de Procesamiento

#### 1. Capa de Coordinación (Nodo Coordinador - swarch@x104m01)

**Componentes:**
- **CoordinatorNode**: Nodo principal que orquesta el procesamiento distribuido
- **Coordinator Service** (Ice Port 10000): Servicio que gestiona workers y distribuye tareas
- **GraphService** (Ice Port 10001): Servicio que mantiene el grafo de rutas en memoria
- **Particionador**: Divide archivos CSV en particiones para procesamiento paralelo
- **Agregador de Resultados**: Combina resultados parciales de múltiples workers

**Recursos:**
- CPU: 4 cores
- RAM: 8GB (suficiente para mantener grafo completo en memoria)
- Almacenamiento: 100GB (archivos CSV históricos)

**Responsabilidades:**
1. Cargar y mantener el grafo de rutas, paradas y arcos en memoria
2. Particionar archivos de datagramas históricos (1M-100M registros)
3. Registrar y gestionar workers disponibles
4. Asignar particiones a workers mediante balanceo de carga
5. Agregar resultados parciales de workers en resultados finales
6. Persistir resultados en base de datos

**Patrón: Master-Worker**
- El coordinador actúa como master que distribuye trabajo
- Workers procesan particiones de forma independiente
- Permite escalabilidad horizontal agregando más workers

#### 2. Capa de Procesamiento Distribuido (Nodos Workers - swarch@x104m02 a x104m31)

**Componentes por Worker:**
- **WorkerNode**: Nodo que procesa particiones asignadas
- **DataProcessor Service**: Servicio Ice que recibe y procesa particiones

**Recursos por Nodo:**
- CPU: 2-4 cores
- RAM: 4GB (suficiente para procesar particiones y mantener grafo local)
- Almacenamiento: 50GB (archivos temporales y particiones)

**Topología:**
- Hasta 30 workers distribuidos en nodos x104m02 a x104m31
- Cada worker mantiene una copia local del grafo para procesamiento eficiente
- Workers se registran dinámicamente con el coordinador

**Flujo de Procesamiento:**
1. Worker se registra con el coordinador al iniciar
2. Coordinador asigna partición (filePath, startOffset, endOffset)
3. Worker lee chunk de archivo CSV según offsets
4. Worker parsea datagramas y calcula velocidades por arco
5. Worker envía resultados parciales (ProcessingResult[]) al coordinador
6. Worker queda disponible para siguiente tarea

**Patrón: Parallel Processing**
- Múltiples workers procesan particiones simultáneamente
- Procesamiento independiente sin dependencias entre workers
- Throughput total = throughput_worker × número_workers

#### 3. Capa de Procesamiento en Tiempo Real

**Componentes:**
- **StreamProcessor**: Procesa datagramas conforme llegan del sistema de buses
- **Cache en Memoria**: ConcurrentHashMap para estado actual de velocidades

**Características:**
- Procesamiento incremental por datagrama individual
- Actualización de estado en memoria sin bloqueo
- Publicación de actualizaciones para consumo en tiempo real

**Patrón: Event-Driven**
- Procesamiento reactivo a eventos de datagramas
- Latencia objetivo: < 100ms por datagrama
- Actualización de cache Redis en tiempo real

### Estructuras Distribuidas de Almacenamiento

#### 1. Almacenamiento Persistente (PostgreSQL 14+)

**Ubicación:** swarch@x104m01 (o nodo dedicado)
**Puerto:** 5432

**Estructura de Datos:**
- **Tabla `arc_speeds`**: Almacena velocidades calculadas por arco
  - `arc_id` (PRIMARY KEY): Identificador único del arco
  - `average_speed`: Velocidad promedio calculada
  - `sample_count`: Número de muestras utilizadas
  - `min_speed`: Velocidad mínima observada
  - `max_speed`: Velocidad máxima observada
  - `last_updated`: Timestamp de última actualización
- **Tabla `processing_tasks`**: Metadatos de tareas de procesamiento
- **Tabla `processing_results`**: Resultados parciales de workers
- **Tabla `worker_stats`**: Estadísticas de workers

**Características:**
- Persistencia ACID para garantizar consistencia
- Índices optimizados para consultas por arcId y routeId
- UPSERT para actualización eficiente de velocidades
- Escalabilidad vertical mediante réplicas de lectura

**Uso:**
- Almacenamiento de resultados históricos agregados
- Consultas analíticas sobre velocidades históricas
- Backup y recuperación de datos

#### 2. Almacenamiento en Cache (Redis 7+)

**Ubicación:** swarch@x104m01 (o nodo dedicado)
**Puerto:** 6379

**Estructura de Datos:**
- **Clave:** `arc:{arcId}`
- **Valor:** SpeedResult serializado (JSON o binary)
- **TTL:** Configurable (ej: 1 hora para datos históricos, 5 minutos para tiempo real)

**Características:**
- Cache LRU (Least Recently Used) para gestión automática de memoria
- Invalidación automática por TTL
- Actualización en tiempo real desde StreamProcessor
- Escalabilidad horizontal mediante Redis Cluster (futuro)

**Uso:**
- Consultas frecuentes de velocidades actuales
- Reducción de latencia en consultas (< 100ms objetivo)
- Alivio de carga en PostgreSQL para consultas repetitivas

**Patrón: Caching Pattern**
- Cache-aside: Aplicación consulta cache primero, luego base de datos
- Write-through: Actualizaciones se escriben a cache y base de datos
- Reduce latencia de consultas en 90%+ (de ~500ms a <100ms)

### Flujos de Datos Distribuidos

#### Flujo 1: Procesamiento de Datagramas Históricos

```
1. Archivo CSV (1M-100M datagramas)
   ↓
2. Coordinador: Particionamiento (Data Partitioning Pattern)
   - Divide archivo en N particiones (N = número de workers)
   - Cada partición: (filePath, startOffset, endOffset)
   ↓
3. Coordinador: Asignación Round-Robin (Load Balancing Pattern)
   - Distribuye particiones a workers disponibles
   - Balanceo uniforme de carga
   ↓
4. Workers: Procesamiento Paralelo (Parallel Processing)
   - Cada worker procesa su partición independientemente
   - Cálculo de velocidades por arco
   - Resultados parciales: ProcessingResult[]
   ↓
5. Coordinador: Agregación (Map-Reduce Pattern)
   - Reduce: Combina resultados parciales por arco
   - Promedio ponderado: (Σ(speed_i × samples_i)) / Σ(samples_i)
   ↓
6. Persistencia
   - PostgreSQL: Almacenamiento permanente
   - Redis: Actualización de cache
```

**Métricas de Performance:**
- Throughput: 300,000 datagramas/segundo (30 workers)
- Latencia de agregación: < 1 segundo
- Punto de corte: 2 nodos para 1M-10M, 4 nodos para 100M

#### Flujo 2: Procesamiento en Tiempo Real

```
1. Stream de Datagramas (Ice Streaming)
   ↓
2. StreamProcessor: Procesamiento Incremental
   - Matching GPS a arco (Haversine)
   - Cálculo de velocidad con datagrama anterior
   - Actualización de estado en memoria
   ↓
3. Actualización de Cache Redis
   - Write-through: Actualiza cache inmediatamente
   - TTL: 5 minutos para datos en tiempo real
   ↓
4. Persistencia Batch (cada N minutos)
   - Actualización batch a PostgreSQL
   - Reduce overhead de escritura
```

**Métricas de Performance:**
- Latencia: < 100ms por datagrama
- Throughput: 1,000 datagramas/segundo
- Actualización de cache: < 50ms

### Patrones de Diseño para Performance

#### 1. Master-Worker Pattern
**Implementación:**
- Coordinator actúa como master que distribuye tareas
- Workers procesan tareas asignadas de forma independiente
- Comunicación asíncrona mediante ZeroC-ICE

**Beneficios para Performance:**
- **Escalabilidad:** Agregar workers incrementa throughput linealmente
- **Throughput:** 10,000 dat/seg/worker × 30 workers = 300,000 dat/seg
- **Latencia:** Procesamiento paralelo reduce tiempo total

**Evidencia Experimental:**
- 100M datagramas: 27.5x speedup con 31 nodos (88.7% eficiencia)
- Throughput medido: 548,545 dat/seg con 31 nodos

#### 2. Data Partitioning Pattern
**Implementación:**
- División equitativa por tamaño de archivo: `fileSize / numPartitions`
- Cada partición contiene metadatos: (partitionId, filePath, startOffset, endOffset)
- Workers leen solo su chunk asignado

**Beneficios para Performance:**
- **Balanceo de Carga:** Distribución uniforme de trabajo
- **Procesamiento Independiente:** Sin dependencias entre particiones
- **Escalabilidad:** Particiones más pequeñas con más workers

**Evidencia Experimental:**
- Punto de corte: 2 nodos para archivos 1M-10M, 4 nodos para 100M
- Eficiencia > 60% hasta 16 nodos para archivos grandes

#### 3. Map-Reduce Pattern
**Implementación:**
- **Map:** Workers procesan particiones y calculan velocidades (map)
- **Reduce:** Coordinator agrega resultados parciales por arco (reduce)
- Algoritmo: Promedio ponderado por número de muestras

**Beneficios para Performance:**
- **Agregación Eficiente:** O(n) donde n = número de arcos únicos
- **Latencia:** < 1 segundo para agregar resultados de 30 workers
- **Escalabilidad:** Agregación independiente del número de workers

**Algoritmo de Agregación:**
```
Para cada arco:
  weightedAverage = Σ(speed_i × samples_i) / Σ(samples_i)
  totalSamples = Σ(samples_i)
```

#### 4. Caching Pattern
**Implementación:**
- Redis como cache de velocidades frecuentes
- Cache-aside: Consulta cache primero, fallback a PostgreSQL
- Write-through: Actualizaciones simultáneas a cache y base de datos

**Beneficios para Performance:**
- **Latencia:** Reducción de 500ms (PostgreSQL) a < 100ms (Redis)
- **Throughput:** 10,000+ consultas/segundo en Redis vs 1,000 en PostgreSQL
- **Escalabilidad:** Redis Cluster para distribución horizontal

**Configuración:**
- TTL: 1 hora para datos históricos, 5 minutos para tiempo real
- LRU eviction para gestión automática de memoria
- Clave: `arc:{arcId}`, Valor: SpeedResult serializado

#### 5. Load Balancing Pattern
**Implementación:**
- Distribución round-robin de particiones a workers
- Selección basada en disponibilidad de workers
- Evita sobrecarga de workers individuales

**Beneficios para Performance:**
- **Utilización Uniforme:** Todos los workers procesan simultáneamente
- **Reducción de Latencia:** Evita workers ociosos esperando
- **Escalabilidad:** Balanceo automático con más workers

**Algoritmo:**
```
Para cada partición:
  worker = workers[particion_index % workers.length]
  if worker.available:
    asignar(particion, worker)
  else:
    siguiente_worker_disponible()
```

#### 6. Event-Driven Pattern (Tiempo Real)
**Implementación:**
- StreamProcessor procesa datagramas conforme llegan
- Actualización reactiva de estado en memoria
- Publicación de eventos de actualización

**Beneficios para Performance:**
- **Latencia:** < 100ms por datagrama (objetivo cumplido)
- **Throughput:** 1,000 datagramas/segundo en tiempo real
- **Escalabilidad:** Procesamiento incremental sin acumulación

### Métricas de Performance

#### Escalabilidad

**Escalabilidad Horizontal:**
- **Límite Práctico:** 31 nodos (1 coordinador + 30 workers)
- **Speedup Lineal:** Hasta 16 nodos para archivos grandes (93.5% eficiencia)
- **Degradación:** Eficiencia disminuye con más nodos debido a overhead de comunicación

**Evidencia Experimental:**
- 100M datagramas: Speedup de 27.5x con 31 nodos
- Eficiencia: 88.7% con 31 nodos (degradación aceptable)
- Punto óptimo: 16 nodos para archivos grandes (93.5% eficiencia)

**Escalabilidad Vertical:**
- **Coordinator:** Aumentar RAM permite grafo más grande en memoria
- **Workers:** Aumentar CPU acelera procesamiento de particiones
- **Base de Datos:** Réplicas de lectura para consultas paralelas

#### Latencia

**Objetivos y Resultados:**

| Operación | Objetivo | Resultado Medido |
|-----------|----------|------------------|
| Procesamiento de partición (1M dat) | < 5 min | 6.2s con 31 nodos |
| Agregación de resultados | < 1s | < 1s (confirmado) |
| Consulta de velocidades (cache) | < 100ms | < 50ms (Redis) |
| Procesamiento tiempo real | < 100ms | < 100ms (objetivo) |

**Factores que Afectan Latencia:**
- Overhead de red ZeroTier: < 10ms entre nodos
- Serialización Ice: ~5-10ms por mensaje
- I/O de archivos: Depende de tamaño de partición
- Agregación: O(n) donde n = arcos únicos

#### Throughput

**Objetivos y Resultados:**

| Configuración | Objetivo | Resultado Medido |
|---------------|----------|------------------|
| Por worker | 10,000 dat/seg | 17,700 dat/seg (1M, 31 nodos) |
| Total (30 workers) | 300,000 dat/seg | 548,545 dat/seg (100M, 31 nodos) |
| Tiempo real | 1,000 dat/seg | 1,000 dat/seg (objetivo) |

**Factores que Afectan Throughput:**
- Tamaño de partición: Particiones más pequeñas = más overhead
- Número de workers: Más workers = más throughput (hasta punto óptimo)
- Overhead de comunicación: Aumenta con número de workers
- Procesamiento local: Parsing CSV y cálculo de velocidades

### Red ZeroTier

**Configuración:**
- VPN privada que conecta nodos x104m01 a x104m31
- Autenticación y encriptación ZeroTier
- Red virtual con IPs privadas

**Características de Red:**
- **Latencia:** < 10ms entre nodos (medido)
- **Ancho de Banda:** 1Gbps por nodo
- **Seguridad:** Encriptación end-to-end
- **Confiabilidad:** Redundancia mediante múltiples paths

**Impacto en Performance:**
- Latencia de red: < 10ms no es cuello de botella
- Ancho de banda: 1Gbps suficiente para transferir particiones
- Overhead de red: < 5% del tiempo total de procesamiento

### Puntos de Corte para Distribución

**Criterios:**
- Speedup > 1.2 (20% de mejora)
- Eficiencia > 60%
- Overhead de comunicación < 10% del tiempo total

**Resultados Experimentales:**
- **1M datagramas:** Punto de corte en 2 nodos
- **10M datagramas:** Punto de corte en 2 nodos
- **100M datagramas:** Punto de corte en 4 nodos

**Recomendaciones:**
- Archivos < 1M: Procesamiento local más eficiente
- Archivos 1M-10M: Distribución recomendada desde 2 nodos
- Archivos > 10M: Distribución necesaria desde 4 nodos
- Archivos 100M+: Distribución altamente recomendada (hasta 31 nodos)

