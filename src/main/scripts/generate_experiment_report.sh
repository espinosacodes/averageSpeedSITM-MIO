#!/bin/bash

RESULTS_DIR="experiment_results"
REPORT_FILE="docs/experiment_report.md"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

if [ ! -d "$RESULTS_DIR" ]; then
    echo "Error: Results directory not found: $RESULTS_DIR"
    echo "Please run ./src/main/scripts/run_experiments.sh first"
    exit 1
fi

# Encontrar el archivo de resultados más reciente
LATEST_CSV=$(ls -t "$RESULTS_DIR"/experiment_results_*.csv 2>/dev/null | head -1)

if [ -z "$LATEST_CSV" ]; then
    echo "Error: No results file found in $RESULTS_DIR"
    exit 1
fi

echo "Processing results from: $LATEST_CSV"

# Generar gráficos
echo "Generating graphs..."
cd "$PROJECT_ROOT"
python3 "$SCRIPT_DIR/generate_experiment_graphs.py" "$LATEST_CSV" "docs" 2>/dev/null || {
    echo "Warning: Could not generate graphs. Make sure matplotlib is installed: pip3 install matplotlib"
}

# Leer resultados y generar reporte
{
    echo "# Informe de Experimentos - Sistema SITM-MIO"
    echo ""
    echo "## Configuración de Experimentos"
    echo ""
    echo "### Datos de Prueba"
    echo "- **Archivo pequeño:** 1,000,000 datagramas (~100MB)"
    echo "- **Archivo mediano:** 10,000,000 datagramas (~1GB)"
    echo "- **Archivo grande:** 100,000,000 datagramas (~10GB)"
    echo ""
    echo "### Configuraciones de Nodos"
    echo "- 1 nodo (solo coordinador)"
    echo "- 2 nodos (1 coordinador + 1 worker)"
    echo "- 4 nodos (1 coordinador + 3 workers)"
    echo "- 8 nodos (1 coordinador + 7 workers)"
    echo "- 16 nodos (1 coordinador + 15 workers)"
    echo "- 31 nodos (1 coordinador + 30 workers)"
    echo ""
    echo "## Resultados"
    echo ""
    echo "### Tabla de Resultados"
    echo ""
    echo "| Tamaño Datos | Nodos | Tiempo (seg) | Throughput (dat/seg) | Speedup | Eficiencia |"
    echo "|--------------|-------|--------------|---------------------|---------|------------|"
    
    # Leer CSV y procesar
    declare -A time_1node
    
    # Primera pasada: obtener tiempos de 1 nodo para calcular speedup
    while IFS=',' read -r size nodes time throughput workers speedup efficiency result_file; do
        if [ "$nodes" = "1" ] && [ "$time" != "N/A" ] && [ "$time" != "Tiempo_seg" ]; then
            time_1node["$size"]="$time"
        fi
    done < "$LATEST_CSV"
    
    # Segunda pasada: generar tabla con speedup y eficiencia
    while IFS=',' read -r size nodes time throughput workers speedup efficiency result_file; do
        if [ "$time" = "Tiempo_seg" ] || [ -z "$time" ]; then
            continue
        fi
        
        if [ "$time" = "N/A" ]; then
            time_display="N/A"
            throughput_display="N/A"
            speedup_display="N/A"
            efficiency_display="N/A"
        else
            time_display=$(printf "%.2f" "$time" 2>/dev/null || echo "$time")
            throughput_display=$(printf "%.0f" "$throughput" 2>/dev/null || echo "$throughput")
            
            # Usar speedup y eficiencia del CSV si están disponibles, sino calcular
            if [ "$speedup" != "N/A" ] && [ -n "$speedup" ] && [ "$speedup" != "" ]; then
                speedup_display=$(printf "%.2f" "$speedup" 2>/dev/null || echo "$speedup")
            elif [ "$nodes" = "1" ]; then
                speedup_display="1.0"
            elif [ -n "${time_1node[$size]}" ] && [ "${time_1node[$size]}" != "N/A" ]; then
                base_time="${time_1node[$size]}"
                if [ "$time" != "N/A" ] && [ "$base_time" != "0" ]; then
                    calc_speedup=$(echo "scale=2; $base_time / $time" | bc 2>/dev/null)
                    if [ -n "$calc_speedup" ]; then
                        speedup_display=$(printf "%.2f" "$calc_speedup")
                    else
                        speedup_display="N/A"
                    fi
                else
                    speedup_display="N/A"
                fi
            else
                speedup_display="N/A"
            fi
            
            if [ "$efficiency" != "N/A" ] && [ -n "$efficiency" ] && [ "$efficiency" != "" ]; then
                efficiency_display=$(echo "$efficiency" | sed 's/%$//')
                efficiency_display=$(printf "%.1f%%" "$efficiency_display" 2>/dev/null || echo "$efficiency")
            elif [ "$nodes" = "1" ]; then
                efficiency_display="100%"
            elif [ -n "$speedup_display" ] && [ "$speedup_display" != "N/A" ]; then
                calc_efficiency=$(echo "scale=2; $speedup_display / $nodes * 100" | bc 2>/dev/null)
                efficiency_display=$(printf "%.1f%%" "$calc_efficiency" 2>/dev/null || echo "N/A")
            else
                efficiency_display="N/A"
            fi
        fi
        
        echo "| $size | $nodes | $time_display | $throughput_display | $speedup_display | $efficiency_display |"
    done < "$LATEST_CSV"
    
    echo ""
    echo "## Gráficos de Resultados"
    echo ""
    echo "### Gráficos Generales"
    echo ""
    echo "![Gráficos de Experimentos](experiment_graphs.png)"
    echo ""
    echo "### Gráfico de Punto de Corte"
    echo ""
    echo "![Punto de Corte](cutoff_point_graph.png)"
    echo ""
    echo "El gráfico de punto de corte muestra el número mínimo de nodos donde la distribución comienza a ser beneficiosa (Speedup > 1.2 y Eficiencia > 60%)."
    echo ""
    echo "## Análisis"
    echo ""
    echo "### Punto de Corte para Distribución"
    echo ""
    echo "El punto de corte es el número mínimo de nodos donde la distribución comienza a ser beneficiosa."
    echo ""
    echo "**Criterios:**"
    echo "- Speedup > 1.2 (20% de mejora)"
    echo "- Eficiencia > 60%"
    echo "- Tiempo de overhead < 10% del tiempo total"
    echo ""
    echo "**Resultados:**"
    
    # Analizar punto de corte para cada tamaño
    declare -A cutoff_nodes
    for size in "1M" "10M" "100M"; do
        # Buscar el primer nodo con speedup > 1.2 y eficiencia > 60%
        cutoff_found=false
        while IFS=',' read -r s n t th w sp ef rf; do
            if [ "$s" = "$size" ] && [ "$n" != "1" ] && [ "$t" != "N/A" ] && [ "$t" != "Tiempo_seg" ]; then
                if [ "$sp" != "N/A" ] && [ "$ef" != "N/A" ] && [ -n "$sp" ] && [ -n "$ef" ]; then
                    sp_val=$(echo "$sp" | sed 's/%//g')
                    ef_val=$(echo "$ef" | sed 's/%//g')
                    if [ -n "$sp_val" ] && [ -n "$ef_val" ]; then
                        sp_compare=$(echo "$sp_val > 1.2" | bc 2>/dev/null)
                        ef_compare=$(echo "$ef_val > 60" | bc 2>/dev/null)
                        if [ "$sp_compare" = "1" ] && [ "$ef_compare" = "1" ]; then
                            if [ "$cutoff_found" = false ]; then
                                cutoff_nodes["$size"]="$n"
                                cutoff_found=true
                            fi
                        fi
                    fi
                fi
            fi
        done < "$LATEST_CSV"
        
        if [ "$cutoff_found" = true ]; then
            echo "- Para ${size} datagramas: Punto de corte en **${cutoff_nodes[$size]} nodos**"
        else
            echo "- Para ${size} datagramas: No se alcanzó el punto de corte con los nodos probados"
        fi
    done
    
    echo ""
    echo "## Observaciones"
    echo ""
    echo "### Overhead de Comunicación"
    echo "- Tiempo de red para distribuir particiones"
    echo "- Tiempo de red para recoger resultados"
    echo "- Overhead de serialización Ice"
    echo ""
    echo "### Balanceo de Carga"
    echo "- Distribución uniforme de trabajo"
    echo "- Tiempo de espera de workers"
    echo "- Workers más lentos como cuello de botella"
    echo ""
    echo "### Escalabilidad"
    echo "- Límites de escalabilidad horizontal"
    echo "- Degradación de eficiencia con más nodos"
    echo "- Overhead de coordinación"
    echo ""
    echo "---"
    echo ""
    echo "*Reporte generado el $(date)*"
    echo "*Resultados de: $LATEST_CSV*"
    
} > "$REPORT_FILE"

echo "Report generated: $REPORT_FILE"

