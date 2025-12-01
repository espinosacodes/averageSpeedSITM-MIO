#!/bin/bash

NODE="swarch@x104m01"
COORDINATOR_DIR="/home/swarch/sitm-mio"
JAR_FILE="averageSpeedSITM-MIO.jar"
PASSWORD="swarch"

echo "Deploying coordinator to $NODE"

SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=3"
SCP_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10"

timeout 30 sshpass -p "$PASSWORD" ssh $SSH_OPTS $NODE "mkdir -p $COORDINATOR_DIR" || { echo "ERROR: No se pudo conectar a $NODE"; exit 1; }
timeout 60 sshpass -p "$PASSWORD" scp $SCP_OPTS build/libs/$JAR_FILE $NODE:$COORDINATOR_DIR/ || { echo "ERROR: No se pudo copiar JAR"; exit 1; }

# Copiar archivos MIO si existen localmente, si no, solo crear el directorio
if [ -d "proyecto-mio/MIO" ] && [ "$(ls -A proyecto-mio/MIO 2>/dev/null)" ]; then
    echo "Copiando archivos MIO..."
    timeout 120 sshpass -p "$PASSWORD" scp $SCP_OPTS -r proyecto-mio/MIO $NODE:$COORDINATOR_DIR/ || { 
        echo "WARNING: No se pudo copiar archivos MIO, continuando..."
        timeout 30 sshpass -p "$PASSWORD" ssh $SSH_OPTS $NODE "mkdir -p $COORDINATOR_DIR/proyecto-mio/MIO" || true
    }
else
    echo "WARNING: Directorio proyecto-mio/MIO no existe localmente, creando directorio remoto..."
    timeout 30 sshpass -p "$PASSWORD" ssh $SSH_OPTS $NODE "mkdir -p $COORDINATOR_DIR/proyecto-mio/MIO" || true
fi

timeout 60 sshpass -p "$PASSWORD" ssh $SSH_OPTS $NODE << 'ENDSSH'
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

