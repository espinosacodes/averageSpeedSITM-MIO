# SITM-MIO Distributed Speed Calculation System

Sistema distribuido para calcular velocidades promedio por arcos en las rutas del SITM-MIO usando ZeroC-ICE.

## Arquitectura

El sistema utiliza una arquitectura Master-Worker con ZeroC-ICE para:
- Procesar datagramas históricos de forma distribuida
- Calcular velocidades promedio por arco
- Soportar procesamiento en tiempo real (streaming)

## Componentes

### Nodos
- **Coordinator** (swarch@x104m01): Coordina workers y gestiona el grafo
- **Workers** (swarch@x104m02 a swarch@x104m31): Procesan particiones de datos

### Servicios Ice
- `Coordinator`: Coordinación y distribución de tareas
- `GraphService`: Gestión del grafo de rutas y arcos
- `DataProcessor`: Procesamiento de datagramas
- `StreamProcessor`: Procesamiento en tiempo real

## Requisitos

- Java 11+
- ZeroC Ice 3.7+
- PostgreSQL 14+ (opcional)
- Redis 7+ (opcional)
- ZeroTier VPN configurada

## Instalación

1. Instalar ZeroC Ice: https://zeroc.com/downloads/ice
2. Generar código Ice desde slice files:
   ```bash
   ./src/main/scripts/generate_ice_code.sh
   ```
3. Compilar proyecto:
   ```bash
   ./gradlew build
   ```

## Uso

### Desarrollo Local

#### Visualizar grafo (sin Ice)
```bash
./gradlew run --args="Main"
# O directamente:
java -cp build/libs/averageSpeedSITM-MIO.jar Main
```

#### Iniciar Coordinator (local)
```bash
# Opción 1: Usando Gradle
./gradlew run

# Opción 2: Usando JAR
java -cp build/libs/averageSpeedSITM-MIO.jar coordinator.CoordinatorNode

# Opción 3: Con puerto personalizado
java -Dcoordinator.port=10002 -cp build/libs/averageSpeedSITM-MIO.jar coordinator.CoordinatorNode
```

#### Iniciar Worker (local)
```bash
java -cp build/libs/averageSpeedSITM-MIO.jar worker.WorkerNode worker1 "tcp -h localhost -p 10000"
```

#### Validar instalación local
```bash
./src/main/scripts/test_local.sh
```

### Despliegue Distribuido

#### Desplegar Coordinator
```bash
./src/main/scripts/deploy_coordinator.sh
```

#### Desplegar Workers
```bash
# Todos los workers
./src/main/scripts/deploy_all_workers.sh

# Worker individual
./src/main/scripts/deploy_worker.sh worker1 swarch@x104m02 "tcp -h x104m01 -p 10000"
```

#### Validar despliegue
```bash
./src/main/scripts/validate_deployment.sh
```

#### Ejecutar prueba de performance
```bash
./src/main/scripts/performance_test.sh proyecto-mio/MIO/datagrams4history.csv 4
```

## Documentación

- [Árbol de Particionamiento](docs/partitioning_tree.md)
- [Especificaciones](docs/specifications.md)
- [Diagrama de Deployment](docs/deployment_diagram.md)
- [Informe de Experimentos](docs/experiment_report.md)

## Estructura del Proyecto

```
src/main/
  ├── slice/              # Definiciones de interfaces Ice (.ice)
  ├── java/               # Código Java
  │   ├── coordinator/    # Nodo coordinador
  │   ├── worker/         # Nodos workers
  │   ├── services/       # Implementaciones de servicios Ice
  │   ├── model/          # Modelos de datos
  │   ├── parser/         # Parsers de CSV
  │   ├── calculator/     # Cálculo de velocidades
  │   └── persistence/    # Acceso a base de datos
  ├── resources/
  │   ├── icegrid/        # Configuración IceGrid
  │   └── sql/            # Esquemas de base de datos
  └── scripts/            # Scripts de deployment y testing
```

## Patrones de Diseño

- **Master-Worker**: Distribución de trabajo
- **Data Partitioning**: División de datos
- **Map-Reduce**: Procesamiento y agregación
- **Caching**: Cache de resultados
- **Load Balancing**: Balanceo de carga

## Licencia

Proyecto académico - Universidad Icesi
