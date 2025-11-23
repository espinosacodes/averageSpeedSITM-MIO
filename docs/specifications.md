# Especificaciones Bicolumnares - Sistema SITM-MIO

## B1: Historical Data Processing Service

| Precondiciones | Postcondiciones |
|----------------|-----------------|
| Archivo de datagramas existe y es accesible | Resultados de velocidad calculados y almacenados |
| Grafo de rutas está cargado | Metadatos de procesamiento registrados |
| Workers disponibles y registrados | Estadísticas de procesamiento disponibles |

**Entradas:**
- Ruta del archivo de datagramas CSV
- Número de particiones deseadas
- Configuración de workers

**Salidas:**
- Mapa de velocidades promedio por arco (arcId -> SpeedResult)
- Estadísticas de procesamiento (tiempo, muestras procesadas)
- Metadatos de tareas (taskId, workerId, estado)

**Excepciones:**
- `ProcessingException`: Error al leer archivo o procesar datos
- `CoordinationException`: Error en coordinación de workers
- `GraphException`: Error al acceder al grafo

**Requisitos de Performance:**
- Procesar 1M datagramas en < 5 minutos con 4 workers
- Procesar 10M datagramas en < 30 minutos con 16 workers
- Procesar 100M datagramas en < 4 horas con 31 workers
- Throughput mínimo: 10,000 datagramas/segundo/worker

---

## B2: Real-time Streaming Service

| Precondiciones | Postcondiciones |
|----------------|-----------------|
| Stream de datagramas disponible | Velocidades actualizadas en tiempo real |
| Grafo de rutas está cargado | Cache actualizado con nuevas velocidades |
| Conexión a base de datos activa | Eventos de actualización publicados |

**Entradas:**
- Stream de datagramas (Ice streaming o mensajería)
- Estado actual de velocidades por arco

**Salidas:**
- SpeedUpdate[] con velocidades actualizadas
- Confirmación de procesamiento

**Excepciones:**
- `StreamingException`: Error al recibir o procesar datagrama
- `CalculationException`: Error al calcular velocidad

**Requisitos de Performance:**
- Latencia de procesamiento < 100ms por datagrama
- Throughput: 1,000 datagramas/segundo
- Actualización de cache < 50ms

---

## B3: Arc Speed Calculation Service

| Precondiciones | Postcondiciones |
|----------------|-----------------|
| Datagramas válidos con coordenadas GPS | Velocidad calculada para arco |
| Arco identificado en el grafo | Muestra agregada a estadísticas del arco |
| Tiempo entre datagramas > 0 | Resultado actualizado en SpeedResult |

**Entradas:**
- Lista de datagramas ordenados por tiempo
- Arco objetivo (opcional, si se busca específico)

**Salidas:**
- SpeedResult con velocidad promedio, min, max, muestras
- Mapa de resultados por arco (si no se especifica arco)

**Excepciones:**
- `CalculationException`: Error en cálculo (datos inválidos, arco no encontrado)

**Requisitos de Performance:**
- Cálculo de velocidad < 10ms por par de datagramas
- Matching GPS a arco < 50ms por datagrama
- Agregación de resultados < 5ms por arco

---

## B4: Data Partitioning Service

| Precondiciones | Postcondiciones |
|----------------|-----------------|
| Archivo de datagramas existe | Particiones creadas con metadatos |
| Número de particiones > 0 | Workers pueden acceder a sus particiones |

**Entradas:**
- Ruta del archivo de datagramas
- Número de particiones deseadas
- Estrategia de particionamiento (por tamaño, por ruta, por tiempo)

**Salidas:**
- Lista de PartitionInfo (partitionId, filePath, startOffset, endOffset)
- Metadatos de particiones

**Excepciones:**
- `CoordinationException`: Error al acceder al archivo o crear particiones

**Requisitos de Performance:**
- Creación de particiones < 1 segundo para archivos < 10GB
- Particiones balanceadas (diferencia < 5% en tamaño)

---

## B5: Result Aggregation Service

| Precondiciones | Postcondiciones |
|----------------|-----------------|
| Resultados parciales de múltiples workers disponibles | Resultados agregados por arco |
| Tareas completadas identificadas | Estadísticas consolidadas generadas |

**Entradas:**
- Lista de taskIds de tareas completadas
- Resultados parciales por worker

**Salidas:**
- AggregationResult[] con velocidades promedio ponderadas por arco
- Estadísticas de agregación (tiempo, número de workers)

**Excepciones:**
- `CoordinationException`: Error al acceder a resultados o agregar datos

**Requisitos de Performance:**
- Agregación de resultados < 1 segundo para 7,187 arcos
- Escalabilidad lineal con número de workers

---

## B6: Graph Management Service

| Precondiciones | Postcondiciones |
|----------------|-----------------|
| Archivos CSV de rutas, paradas y linestops disponibles | Grafo construido y disponible |
| Formato de archivos CSV válido | Índices creados para búsqueda eficiente |

**Entradas:**
- Ruta de archivo lines-241.csv
- Ruta de archivo stops-241.csv
- Ruta de archivo linestops-241.csv

**Salidas:**
- Grafo estructurado (Map<routeId, List<Arc>>)
- Métodos de consulta (getAllArcs, getArcsByRoute, findArcByStops)

**Excepciones:**
- `GraphException`: Error al leer archivos o construir grafo

**Requisitos de Performance:**
- Carga de grafo < 5 segundos
- Consulta de arcos por ruta < 10ms
- Búsqueda de arco por paradas < 50ms

