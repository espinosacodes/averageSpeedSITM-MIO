# Informe de Experimentos - Sistema SITM-MIO

## Configuración de Experimentos

### Datos de Prueba
- **Archivo pequeño:** 1,000,000 datagramas (~100MB)
- **Archivo mediano:** 10,000,000 datagramas (~1GB)
- **Archivo grande:** 100,000,000 datagramas (~10GB)

### Configuraciones de Nodos
- 1 nodo (solo coordinador)
- 2 nodos (1 coordinador + 1 worker)
- 4 nodos (1 coordinador + 3 workers)
- 8 nodos (1 coordinador + 7 workers)
- 16 nodos (1 coordinador + 15 workers)
- 31 nodos (1 coordinador + 30 workers)

## Métricas a Medir

### Tiempo de Procesamiento
- Tiempo total de procesamiento (desde inicio hasta resultados agregados)
- Tiempo de particionamiento
- Tiempo de distribución de tareas
- Tiempo de procesamiento por worker
- Tiempo de agregación de resultados

### Throughput
- Datagramas procesados por segundo
- Throughput por worker
- Throughput total del sistema

### Utilización de Recursos
- Uso de CPU por nodo
- Uso de RAM por nodo
- Uso de red (ancho de banda)
- Uso de disco I/O

### Escalabilidad
- Speedup (tiempo_1_nodo / tiempo_N_nodos)
- Eficiencia (speedup / N_nodos)
- Overhead de comunicación

## Resultados Esperados

### Tabla de Resultados

| Tamaño Datos | Nodos | Tiempo (seg) | Throughput (dat/seg) | Speedup | Eficiencia |
|--------------|-------|--------------|---------------------|---------|------------|
| 1M           | 1     | TBD          | TBD                 | 1.0     | 100%       |
| 1M           | 2     | TBD          | TBD                 | TBD     | TBD         |
| 1M           | 4     | TBD          | TBD                 | TBD     | TBD         |
| 1M           | 8     | TBD          | TBD                 | TBD     | TBD         |
| 1M           | 16    | TBD          | TBD                 | TBD     | TBD         |
| 1M           | 31    | TBD          | TBD                 | TBD     | TBD         |
| 10M          | 1     | TBD          | TBD                 | 1.0     | 100%       |
| 10M          | 4     | TBD          | TBD                 | TBD     | TBD         |
| 10M          | 8     | TBD          | TBD                 | TBD     | TBD         |
| 10M          | 16    | TBD          | TBD                 | TBD     | TBD         |
| 10M          | 31    | TBD          | TBD                 | TBD     | TBD         |
| 100M         | 4     | TBD          | TBD                 | TBD     | TBD         |
| 100M         | 8     | TBD          | TBD                 | TBD     | TBD         |
| 100M         | 16    | TBD          | TBD                 | TBD     | TBD         |
| 100M         | 31    | TBD          | TBD                 | TBD     | TBD         |

### Gráficos

#### 1. Tiempo de Procesamiento vs Número de Nodos
- Eje X: Número de nodos
- Eje Y: Tiempo de procesamiento (segundos)
- Líneas: Una por cada tamaño de datos (1M, 10M, 100M)

#### 2. Speedup vs Número de Nodos
- Eje X: Número de nodos
- Eje Y: Speedup (tiempo_1_nodo / tiempo_N_nodos)
- Línea ideal: y = x (speedup lineal perfecto)

#### 3. Eficiencia vs Número de Nodos
- Eje X: Número de nodos
- Eje Y: Eficiencia (speedup / N_nodos * 100%)
- Línea ideal: y = 100% (eficiencia perfecta)

#### 4. Throughput vs Número de Nodos
- Eje X: Número de nodos
- Eje Y: Throughput (datagramas/segundo)
- Líneas: Una por cada tamaño de datos

## Análisis del Punto de Corte

### Punto de Corte para Distribución
El punto de corte es el número mínimo de nodos donde la distribución comienza a ser beneficiosa.

**Criterios:**
- Speedup > 1.2 (20% de mejora)
- Eficiencia > 60%
- Tiempo de overhead < 10% del tiempo total

**Resultado Esperado:**
- Para 1M datagramas: Punto de corte ~4 nodos
- Para 10M datagramas: Punto de corte ~2 nodos
- Para 100M datagramas: Punto de corte ~2 nodos

## Observaciones

### Overhead de Comunicación
- Tiempo de red para distribuir particiones
- Tiempo de red para recoger resultados
- Overhead de serialización Ice

### Balanceo de Carga
- Distribución uniforme de trabajo
- Tiempo de espera de workers
- Workers más lentos como cuello de botella

### Escalabilidad
- Límites de escalabilidad horizontal
- Degradación de eficiencia con más nodos
- Overhead de coordinación

## Conclusiones

### Efectividad de la Distribución
- Evaluar si la distribución mejora el rendimiento
- Identificar el número óptimo de nodos para cada tamaño de datos
- Determinar cuándo el overhead supera los beneficios

### Recomendaciones
- Configuración recomendada para diferentes tamaños de datos
- Optimizaciones identificadas
- Mejoras futuras sugeridas

