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

SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=3"
SCP_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10"

timeout 30 sshpass -p "$PASSWORD" ssh $SSH_OPTS $NODE "mkdir -p $WORKER_DIR/proyecto-mio/MIO" || { echo "ERROR: No se pudo conectar a $NODE"; exit 1; }
timeout 60 sshpass -p "$PASSWORD" scp $SCP_OPTS build/libs/$JAR_FILE $NODE:$WORKER_DIR/ || { echo "ERROR: No se pudo copiar JAR"; exit 1; }

# Copy CSV files from coordinator node if available, otherwise from local
echo "  Copying CSV files..."
# Primero intentar desde coordinador (ruta sitm-mio)
if timeout 10 sshpass -p "$PASSWORD" ssh $SSH_OPTS swarch@x104m01 "test -f /home/swarch/sitm-mio/proyecto-mio/MIO/lines-241.csv" 2>/dev/null; then
    echo "  Copying from coordinator node (sitm-mio)..."
    timeout 120 sshpass -p "$PASSWORD" scp $SCP_OPTS swarch@x104m01:/home/swarch/sitm-mio/proyecto-mio/MIO/lines-241.csv $NODE:$WORKER_DIR/proyecto-mio/MIO/ 2>&1 | tail -1
    timeout 120 sshpass -p "$PASSWORD" scp $SCP_OPTS swarch@x104m01:/home/swarch/sitm-mio/proyecto-mio/MIO/stops-241.csv $NODE:$WORKER_DIR/proyecto-mio/MIO/ 2>&1 | tail -1
    timeout 120 sshpass -p "$PASSWORD" scp $SCP_OPTS swarch@x104m01:/home/swarch/sitm-mio/proyecto-mio/MIO/linestops-241.csv $NODE:$WORKER_DIR/proyecto-mio/MIO/ 2>&1 | tail -1
    echo "  ✓ Archivos CSV copiados"
# Si no, intentar ruta alternativa
elif timeout 10 sshpass -p "$PASSWORD" ssh $SSH_OPTS swarch@x104m01 "test -f /home/swarch/proyecto-mio/MIO/lines-241.csv" 2>/dev/null; then
    echo "  Copying from coordinator node (proyecto-mio)..."
    timeout 120 sshpass -p "$PASSWORD" scp $SCP_OPTS swarch@x104m01:/home/swarch/proyecto-mio/MIO/lines-241.csv $NODE:$WORKER_DIR/proyecto-mio/MIO/ 2>&1 | tail -1
    timeout 120 sshpass -p "$PASSWORD" scp $SCP_OPTS swarch@x104m01:/home/swarch/proyecto-mio/MIO/stops-241.csv $NODE:$WORKER_DIR/proyecto-mio/MIO/ 2>&1 | tail -1
    timeout 120 sshpass -p "$PASSWORD" scp $SCP_OPTS swarch@x104m01:/home/swarch/proyecto-mio/MIO/linestops-241.csv $NODE:$WORKER_DIR/proyecto-mio/MIO/ 2>&1 | tail -1
    echo "  ✓ Archivos CSV copiados"
else
    echo "  Copying from local machine..."
    timeout 120 sshpass -p "$PASSWORD" scp $SCP_OPTS proyecto-mio/MIO/lines-241.csv $NODE:$WORKER_DIR/proyecto-mio/MIO/ 2>&1 | tail -1
    timeout 120 sshpass -p "$PASSWORD" scp $SCP_OPTS proyecto-mio/MIO/stops-241.csv $NODE:$WORKER_DIR/proyecto-mio/MIO/ 2>&1 | tail -1
    timeout 120 sshpass -p "$PASSWORD" scp $SCP_OPTS proyecto-mio/MIO/linestops-241.csv $NODE:$WORKER_DIR/proyecto-mio/MIO/ 2>&1 | tail -1
    echo "  ✓ Archivos CSV copiados"
fi

timeout 60 sshpass -p "$PASSWORD" ssh $SSH_OPTS $NODE << ENDSSH
cd $WORKER_DIR
pkill -f "WorkerNode.*${WORKER_ID}" || true
sleep 1

# Ensure CSV files are available (create symlink if needed)
cd $WORKER_DIR
if [ ! -d proyecto-mio/MIO ]; then
    mkdir -p proyecto-mio/MIO
fi

# Verificar que los archivos críticos existan
if [ ! -f proyecto-mio/MIO/lines-241.csv ]; then
    # Intentar symlink desde sitm-mio primero
    if [ -f /home/swarch/sitm-mio/proyecto-mio/MIO/lines-241.csv ]; then
        echo "  Creando symlinks desde /home/swarch/sitm-mio/proyecto-mio/MIO/"
        ln -sf /home/swarch/sitm-mio/proyecto-mio/MIO/lines-241.csv proyecto-mio/MIO/ 2>/dev/null || true
        ln -sf /home/swarch/sitm-mio/proyecto-mio/MIO/stops-241.csv proyecto-mio/MIO/ 2>/dev/null || true
        ln -sf /home/swarch/sitm-mio/proyecto-mio/MIO/linestops-241.csv proyecto-mio/MIO/ 2>/dev/null || true
    elif [ -f /home/swarch/proyecto-mio/MIO/lines-241.csv ]; then
        echo "  Creando symlinks desde /home/swarch/proyecto-mio/MIO/"
        ln -sf /home/swarch/proyecto-mio/MIO proyecto-mio/MIO
    fi
    
    # Verificar nuevamente
    if [ ! -f proyecto-mio/MIO/lines-241.csv ]; then
        echo "ERROR: Archivos CSV del grafo no encontrados en $WORKER_DIR/proyecto-mio/MIO/"
        echo "  Archivos en directorio:"
        ls -la proyecto-mio/MIO/ 2>/dev/null || echo "  (directorio no existe)"
        exit 1
    fi
fi
echo "  ✓ Archivos CSV verificados"

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

