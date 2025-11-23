#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: deploy_worker.sh <worker_id> <node> [coordinator_endpoint]"
    echo "Example: deploy_worker.sh worker1 swarch@x104m02 tcp -h swarch@x104m01 -p 10000"
    exit 1
fi

WORKER_ID=$1
NODE=$2
COORDINATOR_ENDPOINT=${3:-"tcp -h swarch@x104m01 -p 10000"}
WORKER_DIR="/home/swarch/sitm-mio"
JAR_FILE="averageSpeedSITM-MIO.jar"

echo "Deploying worker $WORKER_ID to $NODE"

ssh $NODE "mkdir -p $WORKER_DIR"
scp build/libs/$JAR_FILE $NODE:$WORKER_DIR/
scp proyecto-mio/MIO/*.csv $NODE:$WORKER_DIR/proyecto-mio/MIO/

ssh $NODE << ENDSSH
cd $WORKER_DIR
java -Xmx2g -Djava.library.path=/usr/lib \
     -cp $JAR_FILE worker.WorkerNode $WORKER_ID "$COORDINATOR_ENDPOINT" &
echo \$! > worker_${WORKER_ID}.pid
echo "Worker $WORKER_ID started with PID: \$(cat worker_${WORKER_ID}.pid)"
ENDSSH

echo "Worker $WORKER_ID deployed successfully"

