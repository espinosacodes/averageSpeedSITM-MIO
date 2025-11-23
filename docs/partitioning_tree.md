# Árbol de Particionamiento - Sistema de Cálculo de Velocidad Promedio SITM-MIO

## Nivel 1: Sistema de Cálculo de Velocidad Promedio

### 1.1 Procesamiento de Datagramas Históricos
Sistema que procesa archivos históricos de datagramas para calcular velocidades promedio por arco.

### 1.2 Procesamiento de Datagramas en Tiempo Real (Streaming)
Sistema que procesa datagramas en tiempo real conforme son recibidos del sistema de buses.

### 1.3 Gestión de Grafos y Arcos
Sistema que mantiene y gestiona la estructura del grafo de rutas, paradas y arcos.

### 1.4 Almacenamiento y Persistencia
Sistema que almacena resultados, metadatos y permite consultas sobre velocidades calculadas.

## Nivel 2: Descomposición Detallada

### 1.1.1 Carga y Partición de Datos
- **Responsabilidad**: Cargar archivos de datagramas y dividirlos en particiones para procesamiento distribuido
- **Entradas**: Archivo CSV de datagramas históricos
- **Salidas**: Conjunto de particiones con metadatos (offset, tamaño, ruta)
- **Algoritmo**: División por tamaño de archivo o por número de registros

### 1.1.2 Procesamiento Distribuido
- **Responsabilidad**: Distribuir particiones a workers y coordinar el procesamiento
- **Entradas**: Particiones de datos, workers disponibles
- **Salidas**: Resultados parciales por worker
- **Algoritmo**: Master-Worker pattern con balanceo de carga

### 1.1.3 Agregación de Resultados
- **Responsabilidad**: Combinar resultados parciales de múltiples workers
- **Entradas**: Resultados parciales por worker
- **Salidas**: Resultados agregados por arco (velocidad promedio ponderada)
- **Algoritmo**: Promedio ponderado por número de muestras

### 1.2.1 Recepción de Stream
- **Responsabilidad**: Recibir datagramas en tiempo real desde el sistema de buses
- **Entradas**: Stream de datagramas (Ice streaming o mensajería)
- **Salidas**: Datagramas validados y listos para procesamiento
- **Algoritmo**: Buffer de recepción con validación

### 1.2.2 Procesamiento Incremental
- **Responsabilidad**: Procesar datagramas individuales y actualizar velocidades
- **Entradas**: Datagrama individual, estado actual de velocidades
- **Salidas**: Velocidad actualizada para el arco correspondiente
- **Algoritmo**: Actualización incremental de promedio (merge de SpeedResult)

### 1.2.3 Actualización en Tiempo Real
- **Responsabilidad**: Publicar actualizaciones de velocidad para consumo en tiempo real
- **Entradas**: Velocidades actualizadas
- **Salidas**: Eventos de actualización (SpeedUpdate)
- **Algoritmo**: Cola de actualizaciones recientes con límite de tamaño

### 1.3.1 Construcción de Grafo
- **Responsabilidad**: Construir el grafo a partir de archivos CSV (lines, stops, linestops)
- **Entradas**: Archivos CSV de rutas, paradas y paradas por ruta
- **Salidas**: Grafo estructurado con nodos (paradas) y aristas (arcos)
- **Algoritmo**: Agrupación por ruta y orientación, ordenamiento por secuencia

### 1.3.2 Identificación de Arcos
- **Responsabilidad**: Identificar arcos únicos en el grafo
- **Entradas**: Secuencia de paradas por ruta y orientación
- **Salidas**: Lista de arcos únicos con identificadores
- **Algoritmo**: Creación de arcos entre paradas consecutivas

### 1.3.3 Mapeo Datagrama-Arco
- **Responsabilidad**: Mapear coordenadas GPS de datagramas a arcos del grafo
- **Entradas**: Datagrama con coordenadas GPS, grafo de arcos
- **Salidas**: Arco identificado que corresponde al datagrama
- **Algoritmo**: Distancia mínima de Haversine entre coordenadas y paradas del arco

### 1.4.1 Base de Datos de Resultados
- **Responsabilidad**: Almacenar velocidades calculadas en base de datos PostgreSQL
- **Entradas**: Resultados agregados de velocidad por arco
- **Salidas**: Registros persistidos en base de datos
- **Algoritmo**: Inserción/actualización en tabla arc_speeds

### 1.4.2 Cache de Velocidades
- **Responsabilidad**: Mantener cache de velocidades frecuentemente consultadas
- **Entradas**: Velocidades calculadas
- **Salidas**: Cache Redis con TTL configurable
- **Algoritmo**: Cache LRU con invalidación por actualización

### 1.4.3 Persistencia de Metadatos
- **Responsabilidad**: Almacenar metadatos de procesamiento (tareas, workers, resultados)
- **Entradas**: Metadatos de procesamiento
- **Salidas**: Registros en tablas de metadatos
- **Algoritmo**: Inserción en tablas processing_tasks y processing_results

