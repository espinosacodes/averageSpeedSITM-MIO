#!/bin/bash

COORDINATOR_ENDPOINT="tcp -h x104m01 -p 10000"

echo "Redesplegando workers que fallaron..."
echo ""

# Lista de workers que fallaron (basado en el check_status)
FAILED_WORKERS=(
    "worker04:swarch@x104m04"
    "worker05:swarch@x104m05"
    "worker06:swarch@x104m06"
    "worker07:swarch@x104m07"
    "worker09:swarch@x104m09"
    "worker10:swarch@x104m10"
    "worker11:swarch@x104m11"
    "worker12:swarch@x104m12"
    "worker13:swarch@x104m13"
    "worker19:swarch@x104m19"
    "worker20:swarch@x104m20"
    "worker22:swarch@x104m22"
    "worker23:swarch@x104m23"
    "worker24:swarch@x104m24"
    "worker27:swarch@x104m27"
    "worker29:swarch@x104m29"
    "worker31:swarch@x104m31"
)

SUCCESS_COUNT=0
FAIL_COUNT=0

for worker_info in "${FAILED_WORKERS[@]}"; do
    IFS=':' read -r WORKER_ID NODE <<< "$worker_info"
    
    echo "Redesplegando $WORKER_ID en $NODE..."
    if timeout 120 ./src/main/scripts/deploy_worker.sh $WORKER_ID $NODE "$COORDINATOR_ENDPOINT" 2>&1; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        echo "  ✓ $WORKER_ID redesplegado exitosamente"
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo "  ✗ $WORKER_ID falló nuevamente"
    fi
    
    sleep 2
done

echo ""
echo "=========================================="
echo "Resumen: $SUCCESS_COUNT exitosos, $FAIL_COUNT fallidos"
echo "=========================================="


