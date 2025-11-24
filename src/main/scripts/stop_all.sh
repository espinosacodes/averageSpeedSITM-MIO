#!/bin/bash

PASSWORD="swarch"

echo "=== Stopping SITM-MIO Services ==="
echo ""

# Stop Coordinator
echo "Stopping Coordinator on x104m01..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no swarch@x104m01 << 'ENDSSH'
cd /home/swarch/sitm-mio
if [ -f coordinator.pid ]; then
    PID=$(cat coordinator.pid)
    if ps -p $PID > /dev/null 2>&1; then
        kill $PID
        sleep 2
        if ps -p $PID > /dev/null 2>&1; then
            kill -9 $PID
        fi
        echo "  Coordinator stopped"
    else
        echo "  Coordinator not running"
    fi
    rm -f coordinator.pid
else
    echo "  No coordinator PID file found"
fi
ENDSSH

echo ""

# Stop Workers
echo "Stopping Workers..."
for i in {02..31}; do
    NODE_NUM=$(printf "%02d" $i)
    NODE="swarch@x104m${NODE_NUM}"
    WORKER_ID="worker${NODE_NUM}"
    
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 $NODE << ENDSSH 2>/dev/null
cd /home/swarch/sitm-mio
if [ -f worker_${WORKER_ID}.pid ]; then
    PID=\$(cat worker_${WORKER_ID}.pid)
    if ps -p \$PID > /dev/null 2>&1; then
        kill \$PID
        sleep 1
        if ps -p \$PID > /dev/null 2>&1; then
            kill -9 \$PID
        fi
    fi
    rm -f worker_${WORKER_ID}.pid
fi
ENDSSH
    
    if [ $? -eq 0 ]; then
        echo "  Stopped worker on x104m${NODE_NUM}"
    fi
done

echo ""
echo "=== All Services Stopped ==="

