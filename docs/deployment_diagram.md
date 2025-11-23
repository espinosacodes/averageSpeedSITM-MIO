# Diagrama de Deployment - Sistema SITM-MIO

## Arquitectura de Deployment

### Nodos de Procesamiento

#### Nodo Coordinador (swarch@x104m01)
- **Servicios Ice:**
  - `Coordinator` (puerto 10000): Coordinación de workers y distribución de tareas
  - `GraphService` (puerto 10001): Gestión del grafo de rutas y arcos
- **Responsabilidades:**
  - Cargar y mantener el grafo de rutas
  - Particionar archivos de datagramas
  - Asignar tareas a workers
  - Agregar resultados de workers
- **Recursos:**
  - CPU: 4 cores
  - RAM: 8GB
  - Almacenamiento: 100GB

#### Nodos Workers (swarch@x104m02 a swarch@x104m31)
- **Servicios Ice:**
  - `DataProcessor` (puerto dinámico): Procesamiento de particiones de datagramas
- **Responsabilidades:**
  - Recibir particiones de datos
  - Procesar datagramas y calcular velocidades
  - Enviar resultados al coordinador
- **Recursos por nodo:**
  - CPU: 2-4 cores
  - RAM: 4GB
  - Almacenamiento: 50GB

#### Nodo de Base de Datos (swarch@x104m01 o dedicado)
- **Servicio:**
  - PostgreSQL 14+ (puerto 5432)
  - Redis 7+ (puerto 6379)
- **Responsabilidades:**
  - Almacenar resultados de velocidades
  - Cache de consultas frecuentes
  - Metadatos de procesamiento

### Patrones de Diseño para Performance

#### 1. Master-Worker Pattern
- **Implementación:** Coordinator distribuye tareas a Workers
- **Beneficio:** Escalabilidad horizontal, procesamiento paralelo
- **Uso:** Procesamiento de datagramas históricos

#### 2. Data Partitioning Pattern
- **Implementación:** División de archivos por tamaño o ruta
- **Beneficio:** Balanceo de carga, procesamiento independiente
- **Uso:** Particionamiento de archivos grandes (100M+ registros)

#### 3. Map-Reduce Pattern
- **Implementación:** Workers procesan (map), Coordinator agrega (reduce)
- **Beneficio:** Procesamiento distribuido eficiente
- **Uso:** Cálculo de velocidades promedio

#### 4. Caching Pattern
- **Implementación:** Redis para cache de velocidades frecuentes
- **Beneficio:** Reducción de latencia en consultas
- **Uso:** Consultas de velocidades en tiempo real

#### 5. Load Balancing Pattern
- **Implementación:** Distribución round-robin de tareas
- **Beneficio:** Utilización uniforme de recursos
- **Uso:** Asignación de particiones a workers

### Estructura de Comunicación

```
Coordinator (x104m01)
    ├── GraphService (puerto 10001)
    │   └── Mantiene grafo en memoria
    │
    └── Coordinator (puerto 10000)
        ├── Worker 1 (x104m02) ──┐
        ├── Worker 2 (x104m03) ──┤
        ├── Worker 3 (x104m04) ──┤──> Procesan particiones
        ├── ...                   │
        └── Worker 30 (x104m31) ──┘
                │
                └──> Resultados agregados
                     │
                     └──> PostgreSQL + Redis
```

### Escalabilidad

**Escalabilidad Horizontal:**
- Agregar más workers incrementa throughput linealmente
- Límite práctico: 31 workers (nodos disponibles)

**Escalabilidad Vertical:**
- Aumentar RAM en coordinator para grafo más grande
- Aumentar CPU en workers para procesamiento más rápido

**Punto de Corte para Distribución:**
- Archivos < 1M datagramas: Procesamiento local más eficiente
- Archivos > 1M datagramas: Distribución recomendada
- Archivos > 10M datagramas: Distribución necesaria

### Latencia y Throughput

**Latencia Objetivo:**
- Procesamiento de partición: < 5 minutos para 1M datagramas
- Agregación de resultados: < 1 segundo
- Consulta de velocidades: < 100ms (con cache)

**Throughput Objetivo:**
- 10,000 datagramas/segundo/worker
- 300,000 datagramas/segundo total (30 workers)
- 10.8M datagramas/hora total

### Red ZeroTier

- **Configuración:** VPN privada con nodos x104m01 a x104m31
- **Latencia de red:** < 10ms entre nodos
- **Ancho de banda:** 1Gbps por nodo
- **Seguridad:** Autenticación y encriptación ZeroTier

