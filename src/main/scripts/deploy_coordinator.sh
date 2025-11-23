#!/bin/bash

NODE="swarch@x104m01"
COORDINATOR_DIR="/home/swarch/sitm-mio"
JAR_FILE="averageSpeedSITM-MIO.jar"

echo "Deploying coordinator to $NODE"

ssh $NODE "mkdir -p $COORDINATOR_DIR"
scp build/libs/$JAR_FILE $NODE:$COORDINATOR_DIR/
scp proyecto-mio/MIO/*.csv $NODE:$COORDINATOR_DIR/proyecto-mio/MIO/

ssh $NODE << 'ENDSSH'
cd /home/swarch/sitm-mio
java -Xmx4g -Djava.library.path=/usr/lib \
     -cp averageSpeedSITM-MIO.jar coordinator.CoordinatorNode &
echo $! > coordinator.pid
echo "Coordinator started with PID: $(cat coordinator.pid)"
ENDSSH

echo "Coordinator deployed successfully"

