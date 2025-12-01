#!/bin/bash

RESULTS_DIR="experiment_results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_FILE="$RESULTS_DIR/experiment_results_sample_${TIMESTAMP}.csv"

mkdir -p "$RESULTS_DIR"

echo "Tamaño_Datos,Nodos,Tiempo_seg,Throughput_dat_seg,Num_Workers,Speedup,Eficiencia,Archivo_Resultado" > "$RESULTS_FILE"

# Generar datos de ejemplo realistas
# Para 1M datagramas
echo "1M,1,45.2,22123,0,1.0,100.0%,result_1M_1nodo.txt" >> "$RESULTS_FILE"
echo "1M,2,28.5,35087,1,1.59,79.5%,result_1M_2nodos.txt" >> "$RESULTS_FILE"
echo "1M,4,18.3,54644,3,2.47,61.8%,result_1M_4nodos.txt" >> "$RESULTS_FILE"
echo "1M,8,12.1,82644,7,3.74,46.7%,result_1M_8nodos.txt" >> "$RESULTS_FILE"
echo "1M,16,8.5,117647,15,5.32,33.2%,result_1M_16nodos.txt" >> "$RESULTS_FILE"
echo "1M,31,6.2,161290,30,7.29,23.5%,result_1M_31nodos.txt" >> "$RESULTS_FILE"

# Para 10M datagramas
echo "10M,1,452.3,22112,0,1.0,100.0%,result_10M_1nodo.txt" >> "$RESULTS_FILE"
echo "10M,2,235.8,42408,1,1.92,96.0%,result_10M_2nodos.txt" >> "$RESULTS_FILE"
echo "10M,4,125.4,79744,3,3.61,90.2%,result_10M_4nodos.txt" >> "$RESULTS_FILE"
echo "10M,8,68.2,146627,7,6.63,82.9%,result_10M_8nodos.txt" >> "$RESULTS_FILE"
echo "10M,16,38.5,259740,15,11.75,73.4%,result_10M_16nodos.txt" >> "$RESULTS_FILE"
echo "10M,31,22.1,452488,30,20.47,66.0%,result_10M_31nodos.txt" >> "$RESULTS_FILE"

# Para 100M datagramas (incluyendo 1 nodo como referencia)
echo "100M,1,5016.8,19933,0,1.0,100.0%,result_100M_1nodo.txt" >> "$RESULTS_FILE"
echo "100M,4,1254.2,79744,3,4.0,100.0%,result_100M_4nodos.txt" >> "$RESULTS_FILE"
echo "100M,8,642.8,155726,7,7.8,97.5%,result_100M_8nodos.txt" >> "$RESULTS_FILE"
echo "100M,16,335.6,298271,15,14.96,93.5%,result_100M_16nodos.txt" >> "$RESULTS_FILE"
echo "100M,31,182.3,548545,30,27.5,88.7%,result_100M_31nodos.txt" >> "$RESULTS_FILE"

echo "Datos de ejemplo generados: $RESULTS_FILE"
echo "Ahora puedes ejecutar: ./src/main/scripts/generate_experiment_report.sh"

