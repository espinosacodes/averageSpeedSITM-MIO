#!/bin/bash

NODE="swarch@x104m01"
COORDINATOR_DIR="/home/swarch/sitm-mio"
JAR_FILE="averageSpeedSITM-MIO.jar"
PASSWORD="swarch"

echo "Deploying coordinator to $NODE"

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $NODE "mkdir -p $COORDINATOR_DIR"
sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no build/libs/$JAR_FILE $NODE:$COORDINATOR_DIR/
sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no -r proyecto-mio/MIO $NODE:$COORDINATOR_DIR/

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $NODE << 'ENDSSH'
cd /home/swarch/sitm-mio
pkill -f CoordinatorNode || true
sleep 1
nohup java -Xmx4g -Djava.library.path=/usr/lib \
     -jar averageSpeedSITM-MIO.jar coordinator.CoordinatorNode > coordinator.log 2>&1 &
echo $! > coordinator.pid
sleep 2
if ps -p $(cat coordinator.pid) > /dev/null 2>&1; then
    echo "Coordinator started with PID: $(cat coordinator.pid)"
else
    echo "ERROR: Coordinator failed to start. Check coordinator.log"
    exit 1
fi
ENDSSH

echo "Coordinator deployed successfully"

