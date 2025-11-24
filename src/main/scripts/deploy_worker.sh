#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: deploy_worker.sh <worker_id> <node> [coordinator_endpoint]"
    echo "Example: deploy_worker.sh worker1 swarch@x104m02 tcp -h x104m01 -p 10000"
    exit 1
fi

WORKER_ID=$1
NODE=$2
COORDINATOR_ENDPOINT=${3:-"tcp -h x104m01 -p 10000"}
WORKER_DIR="/home/swarch/sitm-mio"
JAR_FILE="averageSpeedSITM-MIO.jar"
PASSWORD="swarch"

echo "Deploying worker $WORKER_ID to $NODE"

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $NODE "mkdir -p $WORKER_DIR/proyecto-mio/MIO"
sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no build/libs/$JAR_FILE $NODE:$WORKER_DIR/

# Copy CSV files from coordinator node if available, otherwise from local
echo "  Copying CSV files..."
if sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 swarch@x104m01 "test -f /home/swarch/proyecto-mio/MIO/lines-241.csv" 2>/dev/null; then
    echo "  Copying from coordinator node..."
    sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no swarch@x104m01:/home/swarch/proyecto-mio/MIO/*.csv $NODE:$WORKER_DIR/proyecto-mio/MIO/ 2>&1 | tail -1
else
    echo "  Copying from local machine..."
    sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no proyecto-mio/MIO/*.csv $NODE:$WORKER_DIR/proyecto-mio/MIO/ 2>&1 | tail -1
fi

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $NODE << ENDSSH
cd $WORKER_DIR
pkill -f "WorkerNode.*${WORKER_ID}" || true
sleep 1

# Ensure CSV files are available (create symlink if needed)
if [ ! -d proyecto-mio/MIO ] || [ ! -f proyecto-mio/MIO/lines-241.csv ]; then
    mkdir -p proyecto-mio
    if [ -d /home/swarch/proyecto-mio/MIO ]; then
        ln -sf /home/swarch/proyecto-mio/MIO proyecto-mio/MIO
    fi
fi

nohup java -Xmx2g -Djava.library.path=/usr/lib \
     -jar $JAR_FILE worker.WorkerNode $WORKER_ID "$COORDINATOR_ENDPOINT" > worker_${WORKER_ID}.log 2>&1 &
echo \$! > worker_${WORKER_ID}.pid
sleep 3
if ps -p \$(cat worker_${WORKER_ID}.pid) > /dev/null 2>&1; then
    echo "Worker $WORKER_ID started with PID: \$(cat worker_${WORKER_ID}.pid)"
    echo "Last 3 lines of log:"
    tail -3 worker_${WORKER_ID}.log
else
    echo "ERROR: Worker $WORKER_ID failed to start. Check worker_${WORKER_ID}.log"
    tail -10 worker_${WORKER_ID}.log
    exit 1
fi
ENDSSH

echo "Worker $WORKER_ID deployed successfully"

