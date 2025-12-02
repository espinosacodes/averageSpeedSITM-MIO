#!/bin/bash

PASSWORD="swarch"
COORDINATOR_NODE="swarch@x104m01"
COORDINATOR_DIR="/home/swarch/sitm-mio"
COORDINATOR_ENDPOINT="tcp -h x104m01 -p 10000"
RESULTS_DIR="experiment_results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Configuraciones de prueba
FILE_SIZES=("100M")
FILE_PATHS=("proyecto-mio/MIO/test_files/datagrams_1M.csv" "proyecto-mio/MIO/test_files/datagrams_10M.csv" "proyecto-mio/MIO/test_files/datagrams_100M.csv")
NODE_CONFIGS=(1 2 4 8 16 31)

mkdir -p "$RESULTS_DIR"
RESULTS_FILE="$RESULTS_DIR/experiment_results_${TIMESTAMP}.csv"
SUMMARY_FILE="$RESULTS_DIR/experiment_summary_${TIMESTAMP}.txt"

echo "=== SITM-MIO Experiment Automation ===" > "$SUMMARY_FILE"
echo "Started: $(date)" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

echo "CSV Header" > "$RESULTS_FILE"
echo "Tamaño_Datos,Nodos,Tiempo_seg,Throughput_dat_seg,Num_Workers,Speedup,Eficiencia,Archivo_Resultado" >> "$RESULTS_FILE"

echo "=== SITM-MIO Experiment Automation ==="
echo "Results will be saved to: $RESULTS_DIR/"
echo ""

# Verificar que el JAR existe (buscar cualquier JAR en build/libs)
JAR_FILE=$(ls build/libs/*.jar 2>/dev/null | head -1)
if [ -z "$JAR_FILE" ]; then
    echo "Error: JAR file not found. Please build the project first: ./gradlew build"
    exit 1
fi
echo "Using JAR: $JAR_FILE"

# Función para desplegar workers
deploy_workers() {
    local num_workers=$1
    echo "  Deploying $num_workers workers..."
    
    local workers_deployed=0
    for i in $(seq 2 31); do
        if [ $workers_deployed -ge $num_workers ]; then
            break
        fi
        
        NODE_NUM=$(printf "%02d" $i)
        WORKER_ID="worker${NODE_NUM}"
        NODE="swarch@x104m${NODE_NUM}"
        
        echo "    Deploying $WORKER_ID to $NODE..."
        ./src/main/scripts/deploy_worker.sh $WORKER_ID $NODE "$COORDINATOR_ENDPOINT" > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            workers_deployed=$((workers_deployed + 1))
            sleep 2
        else
            echo "    Warning: Failed to deploy $WORKER_ID"
        fi
    done
    
    echo "  Deployed $workers_deployed workers"
    sleep 5
    return $workers_deployed
}

# Función para detener workers
stop_workers() {
    local num_workers=$1
    echo "  Stopping $num_workers workers..."
    
    local stopped=0
    for i in $(seq 2 31); do
        if [ $stopped -ge $num_workers ]; then
            break
        fi
        
        NODE_NUM=$(printf "%02d" $i)
        WORKER_ID="worker${NODE_NUM}"
        NODE="swarch@x104m${NODE_NUM}"
        
        sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 $NODE << ENDSSH 2>/dev/null
cd /home/swarch/sitm-mio
if [ -f worker_${WORKER_ID}.pid ]; then
    PID=\$(cat worker_${WORKER_ID}.pid)
    if ps -p \$PID > /dev/null 2>&1; then
        kill \$PID 2>/dev/null
        sleep 1
        if ps -p \$PID > /dev/null 2>&1; then
            kill -9 \$PID 2>/dev/null
        fi
    fi
    rm -f worker_${WORKER_ID}.pid
fi
ENDSSH
        
        if [ $? -eq 0 ]; then
            stopped=$((stopped + 1))
        fi
    done
}

# Función para ejecutar una prueba
run_test() {
    local file_size=$1
    local file_path=$2
    local num_nodes=$3
    local num_workers=$((num_nodes - 1))
    
    echo ""
    echo "=========================================="
    echo "Test: $file_size datagramas, $num_nodes nodos ($num_workers workers)"
    echo "=========================================="
    
    # Desplegar coordinador si es necesario
    if [ $num_nodes -eq 1 ]; then
        echo "  Deploying coordinator only..."
        ./src/main/scripts/deploy_coordinator.sh > /dev/null 2>&1
        sleep 5
    else
        echo "  Deploying coordinator and $num_workers workers..."
        ./src/main/scripts/deploy_coordinator.sh > /dev/null 2>&1
        sleep 3
        deploy_workers $num_workers
        local actual_workers=$?
        
        if [ $actual_workers -lt $num_workers ]; then
            echo "  Warning: Only $actual_workers workers available (requested $num_workers)"
            num_workers=$actual_workers
        fi
    fi
    
    # Esperar a que los workers se registren
    echo "  Waiting for workers to register..."
    sleep 10
    
    # Verificar que el coordinador está corriendo
    COORD_RUNNING=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $COORDINATOR_NODE \
        "cd $COORDINATOR_DIR && ps -p \$(cat coordinator.pid 2>/dev/null) > /dev/null 2>&1 && echo 'yes' || echo 'no'")
    
    if [ "$COORD_RUNNING" != "yes" ]; then
        echo "  Error: Coordinator not running. Skipping test."
        return 1
    fi
    
    # Ejecutar prueba
    echo "  Running performance test..."
    REMOTE_FILE_PATH="$COORDINATOR_DIR/$file_path"
    
    # Verificar que el archivo existe en el coordinador
    FILE_EXISTS=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $COORDINATOR_NODE \
        "test -f $REMOTE_FILE_PATH && echo 'yes' || echo 'no'")
    
    if [ "$FILE_EXISTS" != "yes" ]; then
        echo "  Error: Test file not found at $REMOTE_FILE_PATH"
        echo "  Please run ./src/main/scripts/generate_test_files.sh first"
        return 1
    fi
    
    # Ejecutar el test desde la máquina local (necesita acceso al JAR local)
    TEST_OUTPUT=$(java -Xmx4g -cp "$JAR_FILE" \
         coordinator.PerformanceTestClient \
         "$REMOTE_FILE_PATH" $num_workers "$COORDINATOR_ENDPOINT" 2>&1)
    
    echo "$TEST_OUTPUT"
    
    # Extraer métricas del output
    PROCESSING_TIME=$(echo "$TEST_OUTPUT" | grep "Total processing time:" | sed 's/.*Total processing time: \([0-9.]*\) ms.*/\1/' | head -1)
    THROUGHPUT=$(echo "$TEST_OUTPUT" | grep "Throughput:" | sed 's/.*Throughput: \([0-9.]*\) datagrams\/second.*/\1/' | head -1)
    AVAILABLE_WORKERS=$(echo "$TEST_OUTPUT" | grep "Available workers:" | sed 's/.*Available workers: \([0-9]*\).*/\1/' | head -1)
    
    # Convertir tiempo de ms a segundos
    if [ -n "$PROCESSING_TIME" ]; then
        TIME_SEC=$(echo "scale=2; $PROCESSING_TIME / 1000" | bc)
    else
        TIME_SEC="N/A"
    fi
    
    # Obtener resultado del archivo generado
    RESULT_FILE="performance_results_${num_workers}workers.txt"
    
    echo "  Results:"
    echo "    Processing time: ${TIME_SEC} seconds"
    echo "    Throughput: ${THROUGHPUT} datagrams/second"
    echo "    Workers used: ${AVAILABLE_WORKERS}"
    
    # Calcular speedup y eficiencia (necesitamos el tiempo de 1 nodo como referencia)
    SPEEDUP="N/A"
    EFFICIENCY="N/A"
    
    # Guardar en CSV
    echo "$file_size,$num_nodes,$TIME_SEC,$THROUGHPUT,$AVAILABLE_WORKERS,$SPEEDUP,$EFFICIENCY,$RESULT_FILE" >> "$RESULTS_FILE"
    
    # Guardar en resumen
    echo "Test: $file_size datagramas, $num_nodes nodos" >> "$SUMMARY_FILE"
    echo "  Processing time: ${TIME_SEC} seconds" >> "$SUMMARY_FILE"
    echo "  Throughput: ${THROUGHPUT} datagrams/second" >> "$SUMMARY_FILE"
    echo "  Workers used: ${AVAILABLE_WORKERS}" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"
    
    # Copiar archivo de resultados si existe (el archivo se genera localmente)
    if [ -f "$RESULT_FILE" ]; then
        cp "$RESULT_FILE" "$RESULTS_DIR/result_${file_size}_${num_nodes}nodos_${TIMESTAMP}.txt" 2>/dev/null
    fi
    
    # Detener workers para la siguiente prueba
    if [ $num_nodes -gt 1 ]; then
        stop_workers $num_workers
        sleep 2
    fi
    
    return 0
}

# Iniciar experimentos
echo "Starting experiments..."
echo "File sizes: ${FILE_SIZES[@]}"
echo "Node configurations: ${NODE_CONFIGS[@]}"
echo ""

# Desplegar coordinador inicial
echo "Deploying coordinator..."
./src/main/scripts/deploy_coordinator.sh > /dev/null 2>&1
sleep 5

# Ejecutar pruebas
for size_idx in "${!FILE_SIZES[@]}"; do
    FILE_SIZE="${FILE_SIZES[$size_idx]}"
    FILE_PATH="${FILE_PATHS[$size_idx]}"
    
    echo ""
    echo "=========================================="
    echo "Testing with $FILE_SIZE datagramas"
    echo "=========================================="
    
    for num_nodes in "${NODE_CONFIGS[@]}"; do
        # Para 100M, saltar configuraciones con muy pocos nodos
        if [ "$FILE_SIZE" = "100M" ] && [ $num_nodes -lt 4 ]; then
            echo "Skipping $FILE_SIZE with $num_nodes nodes (too few for large file)"
            continue
        fi
        
        run_test "$FILE_SIZE" "$FILE_PATH" "$num_nodes"
        
        # Pausa entre pruebas
        sleep 5
    done
done

# Detener todos los servicios
echo ""
echo "Stopping all services..."
./src/main/scripts/stop_all.sh > /dev/null 2>&1

# Calcular speedup y eficiencia para todos los resultados
echo ""
echo "=== Calculating Speedup and Efficiency ==="

# Crear archivo temporal con resultados actualizados
TEMP_CSV="${RESULTS_FILE}.tmp"
echo "Tamaño_Datos,Nodos,Tiempo_seg,Throughput_dat_seg,Num_Workers,Speedup,Eficiencia,Archivo_Resultado" > "$TEMP_CSV"

# Leer resultados y calcular métricas
declare -A time_1node

# Primera pasada: obtener tiempos de 1 nodo
while IFS=',' read -r size nodes time throughput workers speedup efficiency result_file; do
    if [ "$nodes" = "1" ] && [ "$time" != "N/A" ] && [ "$time" != "Tiempo_seg" ] && [ -n "$time" ]; then
        time_1node["$size"]="$time"
    fi
done < "$RESULTS_FILE"

# Segunda pasada: calcular speedup y eficiencia
while IFS=',' read -r size nodes time throughput workers speedup efficiency result_file; do
    if [ "$time" = "Tiempo_seg" ] || [ -z "$time" ]; then
        continue
    fi
    
    if [ "$time" = "N/A" ]; then
        echo "$size,$nodes,$time,$throughput,$workers,N/A,N/A,$result_file" >> "$TEMP_CSV"
    elif [ "$nodes" = "1" ]; then
        echo "$size,$nodes,$time,$throughput,$workers,1.0,100.0%,$result_file" >> "$TEMP_CSV"
    elif [ -n "${time_1node[$size]}" ] && [ "${time_1node[$size]}" != "N/A" ]; then
        base_time="${time_1node[$size]}"
        if [ "$base_time" != "0" ] && [ -n "$time" ]; then
            calc_speedup=$(echo "scale=2; $base_time / $time" | bc 2>/dev/null)
            if [ -n "$calc_speedup" ]; then
                calc_efficiency=$(echo "scale=2; $calc_speedup / $nodes * 100" | bc 2>/dev/null)
                echo "$size,$nodes,$time,$throughput,$workers,$calc_speedup,$calc_efficiency%,$result_file" >> "$TEMP_CSV"
            else
                echo "$size,$nodes,$time,$throughput,$workers,N/A,N/A,$result_file" >> "$TEMP_CSV"
            fi
        else
            echo "$size,$nodes,$time,$throughput,$workers,N/A,N/A,$result_file" >> "$TEMP_CSV"
        fi
    else
        echo "$size,$nodes,$time,$throughput,$workers,N/A,N/A,$result_file" >> "$TEMP_CSV"
    fi
done < "$RESULTS_FILE"

mv "$TEMP_CSV" "$RESULTS_FILE"

# Generar reporte final
echo ""
echo "=== Generating Final Report ==="
echo "Completed: $(date)" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "Results saved to:" >> "$SUMMARY_FILE"
echo "  CSV: $RESULTS_FILE" >> "$SUMMARY_FILE"
echo "  Summary: $SUMMARY_FILE" >> "$SUMMARY_FILE"

cat "$SUMMARY_FILE"
echo ""
echo "=== Experiments Completed ==="
echo "Results saved to: $RESULTS_DIR/"
echo ""
echo "To generate the experiment report, run:"
echo "  ./src/main/scripts/generate_experiment_report.sh"

