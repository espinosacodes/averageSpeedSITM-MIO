#!/bin/bash

COORDINATOR_ENDPOINT="tcp -h x104m01 -p 10000"
START_NODE=2
END_NODE=31

echo "Deploying workers to nodes x104m02 through x104m31"
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0

for i in $(seq $START_NODE $END_NODE); do
    NODE_NUM=$(printf "%02d" $i)
    WORKER_ID="worker${NODE_NUM}"
    NODE="swarch@x104m${NODE_NUM}"
    
    echo "[$((i-1))/30] Deploying $WORKER_ID to $NODE..."
    if timeout 120 ./src/main/scripts/deploy_worker.sh $WORKER_ID $NODE "$COORDINATOR_ENDPOINT" 2>&1; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        echo "  ✓ $WORKER_ID desplegado"
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo "  ✗ $WORKER_ID falló (timeout o error)"
    fi
    
    sleep 1
done

echo ""
echo "=========================================="
echo "Resumen: $SUCCESS_COUNT exitosos, $FAIL_COUNT fallidos"
echo "=========================================="

