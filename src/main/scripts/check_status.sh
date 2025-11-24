#!/bin/bash

COORDINATOR_NODE="swarch@x104m01"
PASSWORD="swarch"

echo "=== SITM-MIO Deployment Status ==="
echo ""

# Check Coordinator
echo "1. Coordinator Status (x104m01):"
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $COORDINATOR_NODE << 'ENDSSH'
cd /home/swarch/sitm-mio
if [ -f coordinator.pid ]; then
    PID=$(cat coordinator.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "  ✓ Coordinator running (PID: $PID)"
        echo "  Port 10000:"
        netstat -tlnp 2>/dev/null | grep 10000 || ss -tlnp 2>/dev/null | grep 10000 | head -1
        echo ""
        echo "  Last 5 lines of log:"
        tail -5 coordinator.log 2>/dev/null || echo "  (no log file)"
    else
        echo "  ✗ Coordinator not running (PID file exists but process not found)"
    fi
else
    echo "  ✗ Coordinator not deployed (no PID file)"
fi
ENDSSH

echo ""
echo "2. Worker Status:"
WORKER_COUNT=0
RUNNING_COUNT=0

for i in 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31; do
    NODE_NUM=$i
    NODE="swarch@x104m${NODE_NUM}"
    WORKER_ID="worker${NODE_NUM}"
    
    STATUS=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 $NODE \
        "cd /home/swarch/sitm-mio 2>/dev/null && \
         if [ -f worker_${WORKER_ID}.pid ]; then \
             PID=\$(cat worker_${WORKER_ID}.pid); \
             if ps -p \$PID > /dev/null 2>&1; then \
                 echo 'RUNNING'; \
             else \
                 echo 'STOPPED'; \
             fi; \
         else \
             echo 'NOT_DEPLOYED'; \
         fi" 2>/dev/null)
    
    if [ "$STATUS" = "RUNNING" ]; then
        echo "  ✓ x104m${NODE_NUM}: $WORKER_ID - RUNNING"
        RUNNING_COUNT=$((RUNNING_COUNT + 1))
    elif [ "$STATUS" = "STOPPED" ]; then
        echo "  ✗ x104m${NODE_NUM}: $WORKER_ID - STOPPED"
    elif [ "$STATUS" = "NOT_DEPLOYED" ]; then
        echo "  - x104m${NODE_NUM}: $WORKER_ID - NOT DEPLOYED"
    else
        echo "  ? x104m${NODE_NUM}: $WORKER_ID - UNREACHABLE"
    fi
    
    if [ "$STATUS" != "" ]; then
        WORKER_COUNT=$((WORKER_COUNT + 1))
    fi
done

echo ""
echo "=== Summary ==="
echo "  Coordinator: $(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $COORDINATOR_NODE \
    "cd /home/swarch/sitm-mio && ps -p \$(cat coordinator.pid 2>/dev/null) > /dev/null 2>&1 && echo 'RUNNING' || echo 'STOPPED'")"
echo "  Workers checked: $WORKER_COUNT"
echo "  Workers running: $RUNNING_COUNT"
echo ""

