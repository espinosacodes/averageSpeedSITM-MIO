#!/bin/bash

COORDINATOR_ENDPOINT="tcp -h x104m01 -p 10000"
START_NODE=2
END_NODE=31

echo "Deploying workers to nodes x104m02 through x104m31"

for i in $(seq $START_NODE $END_NODE); do
    NODE_NUM=$(printf "%02d" $i)
    WORKER_ID="worker${NODE_NUM}"
    NODE="swarch@x104m${NODE_NUM}"
    
    echo "Deploying $WORKER_ID to $NODE..."
    ./src/main/scripts/deploy_worker.sh $WORKER_ID $NODE "$COORDINATOR_ENDPOINT"
    
    sleep 2
done

echo "All workers deployed"

