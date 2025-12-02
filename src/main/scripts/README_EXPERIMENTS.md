# Scripts de Experimentos Automatizados

Este directorio contiene scripts para automatizar la ejecución de experimentos del sistema SITM-MIO con diferentes tamaños de archivos y configuraciones de nodos.

## Scripts Disponibles

### 1. `generate_test_files.sh`
Genera archivos de prueba de diferentes tamaños (1M, 10M, 100M datagramas) a partir del archivo fuente `datagrams4history.csv`.

**Uso:**
```bash
./src/main/scripts/generate_test_files.sh
```

**Qué hace:**
- Crea archivos de prueba en `proyecto-mio/MIO/test_files/`
- Genera: `datagrams_1M.csv`, `datagrams_10M.csv`, `datagrams_100M.csv`
- Copia los archivos al nodo coordinador (x104m01)

**Requisitos:**
- Archivo fuente `proyecto-mio/MIO/datagrams4history.csv` debe existir
- Acceso SSH a x104m01 con usuario `swarch` y contraseña `swarch`

### 2. `run_experiments.sh`
Ejecuta automáticamente todas las pruebas de rendimiento con diferentes configuraciones.

**Uso:**
```bash
./src/main/scripts/run_experiments.sh
```

**Qué hace:**
- Despliega coordinador y workers según la configuración
- Ejecuta pruebas para:
  - 3 tamaños de archivos: 1M, 10M, 100M datagramas
  - 6 configuraciones de nodos: 1, 2, 4, 8, 16, 31 nodos
- Mide tiempo de procesamiento y throughput
- Guarda resultados en `experiment_results/`

**Requisitos:**
- JAR compilado: `build/libs/averageSpeedSITM-MIO.jar`
- Archivos de prueba generados (ejecutar `generate_test_files.sh` primero)
- Acceso SSH a todos los nodos x104m01-x104m31

**Resultados:**
- CSV con métricas: `experiment_results/experiment_results_TIMESTAMP.csv`
- Resumen: `experiment_results/experiment_summary_TIMESTAMP.txt`
- Archivos de resultados individuales: `experiment_results/result_*_TIMESTAMP.txt`

### 3. `generate_experiment_report.sh`
Genera un reporte en Markdown con los resultados de los experimentos.

**Uso:**
```bash
./src/main/scripts/generate_experiment_report.sh
```

**Qué hace:**
- Lee el archivo de resultados más reciente
- Calcula speedup y eficiencia
- Genera reporte en `docs/experiment_report.md`

## Flujo de Trabajo Completo

1. **Compilar el proyecto:**
   ```bash
   ./gradlew build
   ```

2. **Generar archivos de prueba:**
   ```bash
   ./src/main/scripts/generate_test_files.sh
   ```

3. **Ejecutar experimentos:**
   ```bash
   ./src/main/scripts/run_experiments.sh
   ```
   
   **Nota:** Este proceso puede tomar varias horas dependiendo del tamaño de los archivos y número de nodos.

4. **Generar reporte:**
   ```bash
   ./src/main/scripts/generate_experiment_report.sh
   ```

## Configuración

Los scripts están configurados para:
- **Usuario SSH:** `swarch`
- **Contraseña:** `swarch`
- **Nodos:** `x104m01` (coordinador), `x104m02` a `x104m31` (workers)
- **Directorio remoto:** `/home/swarch/sitm-mio`
- **Endpoint coordinador:** `tcp -h x104m01 -p 10000`

Para cambiar la configuración, edita las variables al inicio de cada script.

## Métricas Medidas

- **Tiempo de procesamiento:** Tiempo total desde inicio hasta resultados agregados (segundos)
- **Throughput:** Datagramas procesados por segundo
- **Número de workers:** Workers disponibles y utilizados
- **Speedup:** Tiempo_1_nodo / Tiempo_N_nodos
- **Eficiencia:** Speedup / N_nodos * 100%

## Troubleshooting

### Error: "Test file not found"
- Ejecuta `generate_test_files.sh` primero
- Verifica que los archivos estén en el coordinador: `ssh swarch@x104m01 "ls -lh /home/swarch/sitm-mio/proyecto-mio/MIO/test_files/"`

### Error: "Coordinator not running"
- Verifica el estado: `./src/main/scripts/check_status.sh`
- Reinicia el coordinador: `./src/main/scripts/deploy_coordinator.sh`

### Error: "JAR file not found"
- Compila el proyecto: `./gradlew build`

### Workers no se conectan
- Verifica logs: `./src/main/scripts/view_logs.sh worker02`
- Verifica conectividad de red entre nodos
- Asegúrate de que el coordinador esté corriendo antes de desplegar workers


