# Árbol de Particionamiento Refinado - Sistema de Cálculo de Velocidad Promedio SITM-MIO

![Árbol de Particionamiento](partitioning_tree.png)

## Nivel 1: Sistema de Cálculo de Velocidad Promedio SITM-MIO

### 1.1 Procesamiento de Datagramas Históricos
Sistema distribuido que procesa archivos históricos de datagramas CSV para calcular velocidades promedio por arco mediante arquitectura Master-Worker.

### 1.2 Procesamiento de Datagramas en Tiempo Real (Streaming)
Sistema que procesa datagramas en tiempo real conforme son recibidos del sistema de buses, actualizando velocidades incrementalmente.

### 1.3 Gestión de Grafos y Arcos
Sistema que mantiene y gestiona la estructura del grafo de rutas, paradas y arcos del sistema de transporte MIO.

### 1.4 Almacenamiento y Persistencia
Sistema que almacena resultados, metadatos y permite consultas sobre velocidades calculadas.

### 1.5 Coordinación y Orquestación
Sistema que coordina workers, gestiona tareas y balancea la carga de procesamiento distribuido.

## Nivel 2: Descomposición Detallada

### 1.1.1 Carga y Validación de Archivo
- **Responsabilidad**: Cargar archivo CSV de datagramas históricos y validar formato y accesibilidad
- **Entradas**: Ruta del archivo CSV de datagramas históricos
- **Salidas**: Archivo validado y accesible, metadatos del archivo (tamaño, número de líneas estimado)
- **Algoritmo**: Lectura de metadatos del sistema de archivos, validación de extensión y formato CSV
- **Componente**: CoordinatorNode, CoordinatorI.partitionDataFile()

### 1.1.2 Particionamiento de Datos
- **Responsabilidad**: Dividir archivo de datagramas en particiones para procesamiento distribuido
- **Entradas**: Archivo CSV validado, número de particiones deseadas
- **Salidas**: Conjunto de PartitionInfo con metadatos (partitionId, filePath, startOffset, endOffset)
- **Algoritmo**: División equitativa por tamaño de archivo (fileSize / numPartitions)
- **Componente**: CoordinatorI.partitionDataFile()

### 1.1.3 Asignación de Particiones a Workers
- **Responsabilidad**: Asignar particiones a workers disponibles mediante balanceo de carga
- **Entradas**: Particiones creadas, lista de workers disponibles y registrados
- **Salidas**: ProcessingTask asignadas (taskId, partitionId, workerId, status)
- **Algoritmo**: Round-robin o asignación basada en disponibilidad de workers
- **Componente**: CoordinatorI.assignTask()

### 1.1.4 Procesamiento Distribuido de Particiones
- **Responsabilidad**: Procesar partición asignada en worker, parsear datagramas y calcular velocidades
- **Entradas**: Partición asignada (filePath, startOffset, endOffset), grafo de arcos cargado
- **Salidas**: ProcessingResult[] con velocidades calculadas por arco (arcId, averageSpeed, sampleCount)
- **Algoritmo**: Lectura de chunk de archivo, parsing de CSV, cálculo de velocidades por pares de datagramas
- **Componente**: WorkerNode, DataProcessorI.processDatagrams()

### 1.1.5 Agregación de Resultados Parciales
- **Responsabilidad**: Combinar resultados parciales de múltiples workers en resultados agregados por arco
- **Entradas**: ProcessingResult[] de múltiples tareas completadas (taskIds)
- **Salidas**: AggregationResult[] con velocidades promedio ponderadas por arco (weightedAverageSpeed, totalSamples)
- **Algoritmo**: Promedio ponderado por número de muestras: (Σ(speed_i × samples_i)) / Σ(samples_i)
- **Componente**: CoordinatorI.aggregateResults()

### 1.1.6 Persistencia de Resultados Históricos
- **Responsabilidad**: Almacenar resultados agregados en base de datos PostgreSQL
- **Entradas**: AggregationResult[] con velocidades agregadas por arco
- **Salidas**: Registros persistidos en tabla arc_speeds de PostgreSQL
- **Algoritmo**: Inserción/actualización (UPSERT) en tabla arc_speeds con arcId como clave
- **Componente**: Persistence layer (futuro)

### 1.2.1 Recepción de Stream de Datagramas
- **Responsabilidad**: Recibir datagramas en tiempo real desde el sistema de buses mediante Ice streaming
- **Entradas**: Stream de datagramas (Ice streaming o mensajería en tiempo real)
- **Salidas**: Datagramas validados y listos para procesamiento
- **Algoritmo**: Buffer de recepción con validación de formato y campos requeridos
- **Componente**: StreamProcessorI.processDatagram()

### 1.2.2 Procesamiento Incremental de Datagrama
- **Responsabilidad**: Procesar datagrama individual, identificar arco y calcular velocidad incremental
- **Entradas**: Datagrama individual con coordenadas GPS, estado actual de velocidades por arco
- **Salidas**: Velocidad actualizada para el arco correspondiente (SpeedResult actualizado)
- **Algoritmo**: Matching GPS a arco (Haversine), cálculo de velocidad con datagrama anterior del mismo bus, merge incremental de SpeedResult
- **Componente**: StreamProcessorI.processDatagram(), SpeedCalculator.calculateSpeeds()

### 1.2.3 Actualización de Estado en Memoria
- **Responsabilidad**: Actualizar estado en memoria de velocidades por arco con nuevo resultado
- **Entradas**: SpeedResult actualizado para un arco específico
- **Salidas**: Estado actualizado en Map<Integer, SpeedResult> currentSpeeds
- **Algoritmo**: Merge de SpeedResult existente con nuevo resultado (actualización de promedio, min, max, conteo de muestras)
- **Componente**: StreamProcessorI (currentSpeeds ConcurrentHashMap)

### 1.2.4 Publicación de Actualizaciones en Tiempo Real
- **Responsabilidad**: Publicar actualizaciones de velocidad para consumo en tiempo real
- **Entradas**: Velocidades actualizadas (SpeedResult actualizado)
- **Salidas**: SpeedUpdate[] con eventos de actualización (arcId, newAverageSpeed, sampleCount, timestamp)
- **Algoritmo**: Cola de actualizaciones recientes (Queue<SpeedUpdate>) con límite de tamaño MAX_RECENT_UPDATES=1000
- **Componente**: StreamProcessorI.getRecentUpdates()

### 1.2.5 Actualización de Cache en Tiempo Real
- **Responsabilidad**: Actualizar cache Redis con velocidades recién calculadas para consultas rápidas
- **Entradas**: SpeedUpdate con velocidad actualizada
- **Salidas**: Cache Redis actualizado con clave arcId y valor SpeedResult, TTL configurable
- **Algoritmo**: Inserción/actualización en Redis con invalidación automática por TTL
- **Componente**: Cache layer (futuro)

### 1.3.1 Carga de Archivos CSV de Grafo
- **Responsabilidad**: Cargar archivos CSV que definen el grafo (lines, stops, linestops)
- **Entradas**: Rutas de archivos CSV (lines-241.csv, stops-241.csv, linestops-241.csv)
- **Salidas**: Estructuras de datos parseadas (List<Route>, List<Stop>, List<LineStop>)
- **Algoritmo**: Parsing de CSV línea por línea, creación de objetos modelo
- **Componente**: CSVParser.parseRoutes(), CSVParser.parseStops(), CSVParser.parseLineStops()

### 1.3.2 Construcción de Grafo Estructurado
- **Responsabilidad**: Construir el grafo a partir de datos parseados, agrupando por ruta y orientación
- **Entradas**: List<Route>, List<Stop>, List<LineStop> parseados
- **Salidas**: Grafo estructurado con nodos (paradas) y aristas (arcos), Map<routeId, List<Arc>>
- **Algoritmo**: Agrupación por routeId y orientation, ordenamiento por sequence, creación de arcos entre paradas consecutivas
- **Componente**: GraphBuilder.buildGraph()

### 1.3.3 Identificación y Indexación de Arcos Únicos
- **Responsabilidad**: Identificar arcos únicos en el grafo y crear índices para búsqueda eficiente
- **Entradas**: Grafo estructurado con arcos por ruta
- **Salidas**: Lista de arcos únicos con identificadores (arcId), índices para búsqueda por paradas
- **Algoritmo**: Creación de arcos entre paradas consecutivas, deduplicación por (fromStopId, toStopId), asignación de arcId único
- **Componente**: GraphBuilder.getArcs(), GraphBuilder.getArcsByRoute()

### 1.3.4 Mapeo de Coordenadas GPS a Arcos
- **Responsabilidad**: Mapear coordenadas GPS de datagramas a arcos del grafo mediante cálculo de distancia
- **Entradas**: Datagrama con coordenadas GPS (latitude, longitude), grafo de arcos con coordenadas de paradas
- **Salidas**: Arco identificado que corresponde al datagrama (arcId)
- **Algoritmo**: Distancia mínima de Haversine entre coordenadas GPS y paradas de cada arco, selección del arco más cercano
- **Componente**: SpeedCalculator.findArcForDatagram()

### 1.3.5 Consulta y Acceso al Grafo
- **Responsabilidad**: Proporcionar métodos de consulta eficientes sobre el grafo (por ruta, por paradas, todos los arcos)
- **Entradas**: Consultas (routeId, fromStopId, toStopId)
- **Salidas**: Lista de arcos que cumplen criterios de búsqueda
- **Algoritmo**: Búsqueda en índices preconstruidos, filtrado por criterios
- **Componente**: GraphServiceI.getAllArcs(), GraphServiceI.getArcsByRoute(), GraphServiceI.findArcByStops()

### 1.4.1 Almacenamiento en Base de Datos PostgreSQL
- **Responsabilidad**: Almacenar velocidades calculadas en base de datos PostgreSQL para persistencia
- **Entradas**: Resultados agregados de velocidad por arco (AggregationResult[])
- **Salidas**: Registros persistidos en tabla arc_speeds de PostgreSQL
- **Algoritmo**: Inserción/actualización (UPSERT) en tabla arc_speeds con arcId como clave primaria
- **Componente**: Persistence layer (futuro)

### 1.4.2 Cache de Velocidades Frecuentes
- **Responsabilidad**: Mantener cache de velocidades frecuentemente consultadas en Redis
- **Entradas**: Velocidades calculadas (SpeedResult o AggregationResult)
- **Salidas**: Cache Redis con clave arcId y valor serializado, TTL configurable
- **Algoritmo**: Cache LRU con invalidación por actualización o TTL, actualización en tiempo real
- **Componente**: Cache layer (futuro)

### 1.4.3 Persistencia de Metadatos de Procesamiento
- **Responsabilidad**: Almacenar metadatos de procesamiento (tareas, workers, resultados, estadísticas)
- **Entradas**: Metadatos de procesamiento (ProcessingTask, WorkerInfo, ProcessingResult, estadísticas)
- **Salidas**: Registros en tablas de metadatos (processing_tasks, processing_results, worker_stats)
- **Algoritmo**: Inserción en tablas de metadatos con relaciones por taskId y workerId
- **Componente**: Persistence layer (futuro)

### 1.4.4 Consulta de Velocidades Almacenadas
- **Responsabilidad**: Proporcionar consultas sobre velocidades almacenadas (por arco, por ruta, por rango de tiempo)
- **Entradas**: Consultas (arcId, routeId, fecha inicio, fecha fin)
- **Salidas**: Resultados de consulta con velocidades y metadatos
- **Algoritmo**: Consulta SQL optimizada con índices, cache lookup primero, fallback a base de datos
- **Componente**: Query service (futuro)

### 1.5.1 Registro y Gestión de Workers
- **Responsabilidad**: Registrar workers disponibles y mantener estado de disponibilidad
- **Entradas**: WorkerId y endpoint de worker que se registra
- **Salidas**: Lista actualizada de WorkerInfo[] con todos los workers registrados
- **Algoritmo**: Almacenamiento en Map<String, WorkerInfo> con actualización de estado available
- **Componente**: CoordinatorI.registerWorker(), CoordinatorI.unregisterWorker()

### 1.5.2 Gestión de Tareas de Procesamiento
- **Responsabilidad**: Crear, asignar y rastrear estado de tareas de procesamiento
- **Entradas**: Partición asignada, workerId seleccionado
- **Salidas**: ProcessingTask creada con taskId único, estado inicializado
- **Algoritmo**: Creación de taskId UUID, almacenamiento en Map<String, ProcessingTask>, actualización de estado de worker
- **Componente**: CoordinatorI.assignTask(), CoordinatorI.updateTaskStatus(), CoordinatorI.getTaskStatus()

### 1.5.3 Balanceo de Carga
- **Responsabilidad**: Distribuir carga de procesamiento equitativamente entre workers disponibles
- **Entradas**: Particiones pendientes, workers disponibles con estado
- **Salidas**: Asignación balanceada de particiones a workers
- **Algoritmo**: Round-robin o selección basada en workers.available, evitando sobrecarga
- **Componente**: CoordinatorI.assignTask(), CoordinatorI.getAvailableWorkers()

### 1.5.4 Monitoreo y Estado del Sistema
- **Responsabilidad**: Monitorear estado de workers, tareas y sistema en general
- **Entradas**: Consultas de estado (workers disponibles, tareas en progreso, estadísticas)
- **Salidas**: Información de estado del sistema (WorkerInfo[], ProcessingTask[], estadísticas)
- **Algoritmo**: Agregación de estado desde estructuras de datos en memoria, logging periódico
- **Componente**: CoordinatorI.getAvailableWorkers(), CoordinatorNode (statusThread)

### 1.5.5 Manejo de Errores y Recuperación
- **Responsabilidad**: Manejar errores en workers, reasignar tareas fallidas y recuperar del sistema
- **Entradas**: Errores reportados, workers no disponibles, tareas fallidas
- **Salidas**: Tareas reasignadas, workers marcados como no disponibles, logs de errores
- **Algoritmo**: Detección de workers inactivos, reasignación de tareas pendientes, actualización de estado
- **Componente**: CoordinatorI.updateTaskStatus() (status=3 para error), lógica de recuperación (futuro)
