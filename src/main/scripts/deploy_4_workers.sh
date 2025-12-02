#!/bin/bash

COORDINATOR_ENDPOINT="tcp -h x104m01 -p 10000"
NUM_WORKERS=4
START_NODE=2
END_NODE=$((START_NODE + NUM_WORKERS - 1))

echo "=========================================="
echo "Desplegando para prueba de 100 millones"
echo "Coordinador + $NUM_WORKERS workers"
echo "=========================================="
echo ""

# Desplegar coordinador
echo "1. Desplegando coordinador..."
if ./src/main/scripts/deploy_coordinator.sh; then
    echo "  ✓ Coordinador desplegado"
else
    echo "  ✗ Error al desplegar coordinador"
    exit 1
fi

echo ""
echo "2. Esperando 3 segundos..."
sleep 3

# Desplegar 4 workers
echo ""
echo "3. Desplegando $NUM_WORKERS workers..."
SUCCESS_COUNT=0
FAIL_COUNT=0

for i in $(seq $START_NODE $END_NODE); do
    NODE_NUM=$(printf "%02d" $i)
    WORKER_ID="worker${NODE_NUM}"
    NODE="swarch@x104m${NODE_NUM}"
    
    echo "  [$((i-START_NODE+1))/$NUM_WORKERS] Desplegando $WORKER_ID a $NODE..."
    if timeout 120 ./src/main/scripts/deploy_worker.sh $WORKER_ID $NODE "$COORDINATOR_ENDPOINT" 2>&1; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        echo "    ✓ $WORKER_ID desplegado"
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo "    ✗ $WORKER_ID falló (timeout o error)"
    fi
    
    sleep 2
done

echo ""
echo "=========================================="
echo "Resumen del despliegue:"
echo "  Coordinador: ✓"
echo "  Workers exitosos: $SUCCESS_COUNT/$NUM_WORKERS"
echo "  Workers fallidos: $FAIL_COUNT/$NUM_WORKERS"
echo "=========================================="

if [ $SUCCESS_COUNT -eq $NUM_WORKERS ]; then
    echo ""
    echo "✓ Todos los workers desplegados correctamente"
    echo "Esperando 5 segundos para que se registren..."
    sleep 5
    exit 0
else
    echo ""
    echo "⚠ Algunos workers fallaron. Revisa los logs."
    exit 1
fi

