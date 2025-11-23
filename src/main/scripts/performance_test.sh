#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: performance_test.sh <data_file> <num_workers>"
    echo "Example: performance_test.sh datagrams4history.csv 4"
    exit 1
fi

DATA_FILE=$1
NUM_WORKERS=$2
COORDINATOR_ENDPOINT="tcp -h x104m01 -p 10000"

echo "Performance Test Configuration:"
echo "  Data file: $DATA_FILE"
echo "  Number of workers: $NUM_WORKERS"
echo "  Coordinator: $COORDINATOR_ENDPOINT"

START_TIME=$(date +%s)

java -Xmx4g -cp build/libs/averageSpeedSITM-MIO.jar \
     coordinator.PerformanceTestClient \
     "$DATA_FILE" $NUM_WORKERS "$COORDINATOR_ENDPOINT"

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo "Total processing time: ${ELAPSED} seconds"
echo "Results saved to performance_results_${NUM_WORKERS}workers.txt"

